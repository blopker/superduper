package io.kbl.superduper

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

internal object NativeBackgroundSync {
    private const val logTag = "BackgroundSync"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val planExecutor = Executors.newSingleThreadExecutor()

    private var generation = 0L
    private var loading = false
    private var active: NativeBikeTransaction? = null

    fun synchronize(context: Context, deviceId: String, source: String) {
        val applicationContext = context.applicationContext
        Log.d(
            logTag,
            "Native sync requested: source=$source foreground=${BackgroundSyncRuntime.isActivityForeground}",
        )
        mainHandler.post {
            synchronizeOnMain(applicationContext, deviceId, source)
        }
    }

    fun cancel(reason: String) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            cancelOnMain(reason)
        } else {
            mainHandler.post { cancelOnMain(reason) }
        }
    }

    fun resumePending(context: Context) {
        val applicationContext = context.applicationContext
        mainHandler.postDelayed(
            {
                val preferences = BackgroundCompanionManager.preferences(applicationContext)
                if (!preferences.getBoolean(BackgroundCompanionManager.pendingSyncKey, false)) {
                    return@postDelayed
                }
                val deviceId = preferences.getString(
                    BackgroundCompanionManager.deviceIdKey,
                    null,
                ) ?: return@postDelayed
                Log.d(logTag, "Bluetooth is on; resuming pending native sync")
                synchronizeOnMain(applicationContext, deviceId, "bluetoothOn")
            },
            adapterResumeDelayMs,
        )
    }

    private fun synchronizeOnMain(context: Context, deviceId: String, source: String) {
        val preferences = BackgroundCompanionManager.preferences(context)
        preferences.edit()
            .putLong(BackgroundCompanionManager.lastPresenceAtKey, System.currentTimeMillis())
            .putString(BackgroundCompanionManager.lastPresenceSourceKey, source)
            .apply()

        val configuredDeviceId = preferences.getString(
            BackgroundCompanionManager.deviceIdKey,
            null,
        )
        if (configuredDeviceId?.equals(deviceId, ignoreCase = true) != true) {
            record(context, "skippedDeviceMismatch", null)
            return
        }
        val cooldownUntil = preferences.getLong(
            BackgroundCompanionManager.presenceCooldownUntilKey,
            0L,
        )
        if (System.currentTimeMillis() < cooldownUntil) {
            Log.d(logTag, "Native sync request ignored during post-transaction cooldown")
            return
        }
        if (BackgroundSyncRuntime.isActivityForeground) {
            preferences.edit().remove(BackgroundCompanionManager.pendingSyncKey).apply()
            record(context, "skippedForeground", null)
            return
        }
        if (loading || active != null) {
            record(context, "skippedBusy", null)
            return
        }
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            record(context, "failed", "Bluetooth connect permission is unavailable")
            return
        }
        if (!isBluetoothEnabled(context)) {
            deferUntilBluetoothOn(context)
            return
        }
        preferences.edit().remove(BackgroundCompanionManager.pendingSyncKey).apply()

        loading = true
        val loadGeneration = ++generation
        planExecutor.execute {
            val result = runCatching {
                BackgroundSyncPlanStore.load(context, configuredDeviceId)
            }
            mainHandler.post {
                finishLoading(context, loadGeneration, result)
            }
        }
    }

    private fun finishLoading(
        context: Context,
        loadGeneration: Long,
        result: Result<BackgroundSyncPlan?>,
    ) {
        if (loadGeneration != generation) return
        loading = false
        if (BackgroundSyncRuntime.isActivityForeground) {
            record(context, "skippedForeground", null)
            return
        }
        val plan = result.getOrElse { error ->
            record(context, "failed", error.message ?: error.javaClass.simpleName)
            return
        }
        if (plan == null || plan.commands.isEmpty()) {
            record(context, "skippedNoPlan", null)
            return
        }
        if (!isBluetoothEnabled(context)) {
            deferUntilBluetoothOn(context)
            return
        }

        BackgroundCompanionManager.preferences(context).edit()
            .putLong(
                BackgroundCompanionManager.lastSyncStartedAtKey,
                System.currentTimeMillis(),
            )
            .apply()
        val transaction = NativeBikeTransaction(
            context = context,
            plan = plan,
            onFinished = ::finishTransaction,
        )
        active = transaction
        Log.d(logTag, "Starting native background transaction")
        transaction.start()
    }

    private fun finishTransaction(
        transaction: NativeBikeTransaction,
        outcome: String,
        detail: String?,
    ) {
        if (active !== transaction) return
        active = null
        if (outcome == "failed" && !isBluetoothEnabled(transaction.context)) {
            deferUntilBluetoothOn(transaction.context)
            return
        }
        startPresenceCooldown(transaction.context)
        record(transaction.context, outcome, detail)
    }

    private fun cancelOnMain(reason: String) {
        generation++
        loading = false
        val transaction = active ?: return
        active = null
        startPresenceCooldown(transaction.context)
        transaction.cancel(reason)
        record(transaction.context, "cancelled", reason)
    }

    private fun record(context: Context, outcome: String, detail: String?) {
        BackgroundCompanionManager.preferences(context).edit()
            .putString(BackgroundCompanionManager.lastOutcomeKey, outcome)
            .putString(BackgroundCompanionManager.lastDetailKey, detail)
            .putLong(
                BackgroundCompanionManager.lastCompletedAtKey,
                System.currentTimeMillis(),
            )
            .apply()
        if (detail == null) {
            Log.d(logTag, "Native background transaction: $outcome")
        } else {
            Log.w(logTag, "Native background transaction: $outcome ($detail)")
        }
    }

    private fun deferUntilBluetoothOn(context: Context) {
        BackgroundCompanionManager.preferences(context)
            .edit()
            .putBoolean(BackgroundCompanionManager.pendingSyncKey, true)
            .apply()
        record(context, "deferredBluetoothUnavailable", "Waiting for Bluetooth to turn on")
    }

    private fun isBluetoothEnabled(context: Context): Boolean = try {
        context.getSystemService(BluetoothManager::class.java)?.adapter?.isEnabled == true
    } catch (_: SecurityException) {
        false
    }

    private fun startPresenceCooldown(context: Context) {
        BackgroundCompanionManager.preferences(context)
            .edit()
            .putLong(
                BackgroundCompanionManager.presenceCooldownUntilKey,
                System.currentTimeMillis() + presenceCooldownMs,
            )
            .apply()
    }

    private const val adapterResumeDelayMs = 1_000L
    private const val presenceCooldownMs = 10_000L
}

private class NativeBikeTransaction(
    val context: Context,
    private val plan: BackgroundSyncPlan,
    private val onFinished: (NativeBikeTransaction, String, String?) -> Unit,
) {
    private enum class State {
        CONNECTING,
        DISCOVERING,
        READING_CHALLENGE,
        WRITING_RESPONSE,
        READING_AUTHENTICATION,
        WRITING_COMMAND,
        FINISHED,
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { finish("failed", "The bike transaction timed out") }
    private var state = State.CONNECTING
    private var gatt: BluetoothGatt? = null
    private var responseCharacteristic: BluetoothGattCharacteristic? = null
    private var authenticationCharacteristic: BluetoothGattCharacteristic? = null
    private var commandCharacteristic: BluetoothGattCharacteristic? = null
    private var commandIndex = 0

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            handleConnectionStateChange(gatt, status, newState)
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            handleServicesDiscovered(gatt, status)
        }

        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                @Suppress("DEPRECATION")
                handleCharacteristicRead(gatt, characteristic, characteristic.value, status)
            }
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int,
        ) {
            handleCharacteristicRead(gatt, characteristic, value, status)
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            handleCharacteristicWrite(gatt, characteristic, status)
        }
    }

    @SuppressLint("MissingPermission")
    fun start() {
        mainHandler.postDelayed(timeout, transactionTimeoutMs)
        try {
            val manager = context.getSystemService(BluetoothManager::class.java)
                ?: error("Bluetooth is unavailable")
            val adapter = manager.adapter ?: error("Bluetooth is unavailable")
            check(adapter.isEnabled) { "Bluetooth is turned off" }
            val device = adapter.getRemoteDevice(plan.deviceId)
            val connection = device.connectGatt(
                context,
                false,
                callback,
                BluetoothDevice.TRANSPORT_LE,
            )
            if (state == State.FINISHED) {
                connection.close()
            } else {
                gatt = connection
            }
        } catch (error: Exception) {
            finish("failed", error.message ?: error.javaClass.simpleName)
        }
    }

    fun cancel(reason: String) {
        finish("cancelled", reason)
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    private fun handleConnectionStateChange(
        gatt: BluetoothGatt,
        status: Int,
        newState: Int,
    ) {
        if (state == State.FINISHED) return
        if (status != BluetoothGatt.GATT_SUCCESS) {
            finish("failed", "GATT connection failed with status $status")
            return
        }
        if (newState == BluetoothProfile.STATE_CONNECTED && state == State.CONNECTING) {
            state = State.DISCOVERING
            if (!gatt.discoverServices()) {
                finish("failed", "Could not start GATT service discovery")
            }
        } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            finish("failed", "The bike disconnected before synchronization completed")
        }
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    private fun handleServicesDiscovered(gatt: BluetoothGatt, status: Int) {
        if (state != State.DISCOVERING) return
        if (status != BluetoothGatt.GATT_SUCCESS) {
            finish("failed", "GATT service discovery failed with status $status")
            return
        }
        val authenticationService = gatt.getService(authenticationServiceUuid)
        val controlService = gatt.getService(controlServiceUuid)
        val challenge = authenticationService.characteristic(challengeUuid)
        val response = authenticationService.characteristic(responseUuid)
        val authentication = authenticationService.characteristic(authenticationUuid)
        val command = controlService.characteristic(commandUuid)
        if (challenge == null || response == null || authentication == null || command == null) {
            finish("failed", "The bike is missing a required GATT characteristic")
            return
        }
        responseCharacteristic = response
        authenticationCharacteristic = authentication
        commandCharacteristic = command
        state = State.READING_CHALLENGE
        if (!gatt.readCharacteristic(challenge)) {
            finish("failed", "Could not read the authentication challenge")
        }
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    private fun handleCharacteristicRead(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray,
        status: Int,
    ) {
        if (state == State.FINISHED) return
        if (status != BluetoothGatt.GATT_SUCCESS) {
            finish("failed", "GATT read failed with status $status")
            return
        }
        when (state) {
            State.READING_CHALLENGE -> {
                if (characteristic.uuid != challengeUuid) return
                if (value.size != authenticationValueLength) {
                    finish("failed", "The authentication challenge has an invalid length")
                    return
                }
                val key = ByteArray(authenticationValueLength) { 0xff.toByte() }
                val response = MessageDigest.getInstance("SHA-1").digest(value + key)
                state = State.WRITING_RESPONSE
                if (!write(gatt, responseCharacteristic, response)) {
                    finish("failed", "Could not write the authentication response")
                }
            }

            State.READING_AUTHENTICATION -> {
                if (characteristic.uuid != authenticationUuid) return
                if (value.size != 1 || value[0].toInt() != 1) {
                    finish("failed", "Bike authentication was rejected")
                    return
                }
                writeNextCommand(gatt)
            }

            else -> Unit
        }
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    private fun handleCharacteristicWrite(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
    ) {
        if (state == State.FINISHED) return
        if (status != BluetoothGatt.GATT_SUCCESS) {
            finish("failed", "GATT write failed with status $status")
            return
        }
        when (state) {
            State.WRITING_RESPONSE -> {
                if (characteristic.uuid != responseUuid) return
                state = State.READING_AUTHENTICATION
                val authentication = authenticationCharacteristic
                if (authentication == null || !gatt.readCharacteristic(authentication)) {
                    finish("failed", "Could not verify bike authentication")
                }
            }

            State.WRITING_COMMAND -> {
                if (characteristic.uuid != commandUuid) return
                commandIndex++
                if (commandIndex == plan.commands.size) {
                    finish("confirmed", null)
                } else {
                    writeNextCommand(gatt)
                }
            }

            else -> Unit
        }
    }

    @SuppressLint("MissingPermission")
    private fun writeNextCommand(gatt: BluetoothGatt) {
        state = State.WRITING_COMMAND
        if (!write(gatt, commandCharacteristic, plan.commands[commandIndex])) {
            finish("failed", "Could not write a background command")
        }
    }

    @SuppressLint("MissingPermission")
    private fun write(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic?,
        value: ByteArray,
    ): Boolean {
        characteristic ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeCharacteristic(
                characteristic,
                value,
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
            ) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            @Suppress("DEPRECATION")
            characteristic.value = value
            @Suppress("DEPRECATION")
            gatt.writeCharacteristic(characteristic)
        }
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    private fun finish(outcome: String, detail: String?) {
        if (state == State.FINISHED) return
        state = State.FINISHED
        mainHandler.removeCallbacks(timeout)
        val connection = gatt
        gatt = null
        if (connection != null) {
            try {
                connection.disconnect()
            } catch (_: RuntimeException) {
                // Closing below still releases the native GATT client.
            }
            try {
                connection.close()
            } catch (_: RuntimeException) {
                // Completion still needs to be recorded if Bluetooth permission changes.
            }
        }
        mainHandler.post { onFinished(this, outcome, detail) }
    }

    private fun BluetoothGattService?.characteristic(
        uuid: UUID,
    ): BluetoothGattCharacteristic? = this?.getCharacteristic(uuid)

    private companion object {
        const val authenticationValueLength = 20
        const val transactionTimeoutMs = 45_000L
        val authenticationServiceUuid: UUID =
            UUID.fromString("00002554-1212-efde-1523-785feabcd123")
        val challengeUuid: UUID =
            UUID.fromString("00002556-1212-efde-1523-785feabcd123")
        val responseUuid: UUID =
            UUID.fromString("00002557-1212-efde-1523-785feabcd123")
        val authenticationUuid: UUID =
            UUID.fromString("00002558-1212-efde-1523-785feabcd123")
        val controlServiceUuid: UUID =
            UUID.fromString("00001554-1212-efde-1523-785feabcd123")
        val commandUuid: UUID =
            UUID.fromString("0000155f-1212-efde-1523-785feabcd123")
    }
}
