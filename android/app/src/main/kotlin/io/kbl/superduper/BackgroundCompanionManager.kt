package io.kbl.superduper

import android.Manifest
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanSettings
import android.companion.AssociationRequest
import android.companion.BluetoothLeDeviceFilter
import android.companion.CompanionDeviceManager
import android.companion.ObservingDevicePresenceRequest
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

internal object BackgroundCompanionManager {
    const val preferencesName = "background_sync"
    const val deviceIdKey = "device_id"
    const val lastPresenceAtKey = "last_presence_at_ms"
    const val lastPresenceSourceKey = "last_presence_source"
    const val lastSyncStartedAtKey = "last_sync_started_at_ms"
    const val lastOutcomeKey = "last_outcome"
    const val lastDetailKey = "last_detail"
    const val lastCompletedAtKey = "last_completed_at_ms"
    const val pendingSyncKey = "pending_sync"
    const val presenceCooldownUntilKey = "presence_cooldown_until_ms"
    const val scanAction = "io.kbl.superduper.BACKGROUND_SCAN"

    private const val legacyPresentKey = "bike_present"
    private const val legacyCompanionPresentKey = "companion_present"
    private const val legacySerialKey = "module_serial"
    private const val registrationErrorDetailKey = "registration_error_detail"
    private const val registrationErrorAtKey = "registration_error_at_ms"
    private const val typedPresenceApi = 36
    private const val logTag = "BackgroundSync"

    fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    fun normalizeDeviceId(value: String): String {
        val normalized = value.uppercase()
        require(BluetoothAdapter.checkBluetoothAddress(normalized)) {
            "The saved bike does not have a valid Bluetooth address"
        }
        return normalized
    }

    fun associationRequest(deviceId: String): AssociationRequest {
        val filter = BluetoothLeDeviceFilter.Builder()
            .setScanFilter(
                ScanFilter.Builder()
                    .setDeviceAddress(normalizeDeviceId(deviceId))
                    .build(),
            )
            .build()
        return AssociationRequest.Builder()
            .addDeviceFilter(filter)
            .setSingleDevice(true)
            .build()
    }

    fun hasCompanionSupport(context: Context): Boolean =
        context.packageManager.hasSystemFeature(
            PackageManager.FEATURE_COMPANION_DEVICE_SETUP,
        )

    fun configureIfAssociated(
        context: Context,
        deviceId: String,
    ): Boolean {
        val address = normalizeDeviceId(deviceId)
        if (!hasCompanionSupport(context)) {
            throw IllegalStateException(
                "This phone does not support Android companion-device association",
            )
        }
        if (!isAssociated(context, address)) {
            Log.w(logTag, "Cannot observe bike presence: companion association is missing")
            return false
        }

        val preferences = preferences(context)
        val previousAddress = preferences.getString(deviceIdKey, null)
        if (previousAddress != null && !previousAddress.equals(address, ignoreCase = true)) {
            NativeBackgroundSync.cancel("Background Sync bike changed")
            stopObserving(context, previousAddress)
            disassociate(context, previousAddress)
        }
        preferences
            .edit()
            .putString(deviceIdKey, address)
            .remove(legacySerialKey)
            .remove(legacyPresentKey)
            .remove(legacyCompanionPresentKey)
            .remove(registrationErrorDetailKey)
            .remove(registrationErrorAtKey)
            .commit()
        startObserving(context, address)
        val plan = BackgroundSyncPlanStore.load(context, address)
        if (plan == null) {
            stopAdvertisementScan(context)
        } else {
            startAdvertisementScan(context, plan)
        }
        return true
    }

    fun restoreStored(context: Context) {
        val preferences = preferences(context)
        val address = preferences.getString(deviceIdKey, null) ?: run {
            stopAdvertisementScan(context)
            return
        }
        try {
            if (!configureIfAssociated(context, address)) {
                recordFailure(
                    context,
                    "Background Sync needs this bike to be associated again",
                )
            }
        } catch (error: RuntimeException) {
            recordFailure(context, error.message ?: error.javaClass.simpleName)
        }
    }

    fun cancel(context: Context) {
        val preferences = preferences(context)
        val address = preferences.getString(deviceIdKey, null)
        NativeBackgroundSync.cancel("Background Sync was disabled")
        if (address != null) {
            stopObserving(context, address)
            disassociate(context, address)
        }
        preferences.edit()
            .remove(deviceIdKey)
            .remove(legacySerialKey)
            .remove(pendingSyncKey)
            .remove(presenceCooldownUntilKey)
            .remove(legacyPresentKey)
            .remove(legacyCompanionPresentKey)
            .apply()
        stopAdvertisementScan(context)
    }

    fun removeAssociation(context: Context, deviceId: String) {
        val address = normalizeDeviceId(deviceId)
        stopObserving(context, address)
        disassociate(context, address)
    }

    @RequiresApi(typedPresenceApi)
    fun deviceIdForAssociation(context: Context, associationId: Int): String? {
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        return manager.myAssociations
            .firstOrNull { it.id == associationId }
            ?.deviceMacAddress
            ?.toString()
    }

    fun stopAdvertisementScan(context: Context) {
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val scanner = context.getSystemService(BluetoothManager::class.java)
            ?.adapter
            ?.bluetoothLeScanner ?: return
        val pendingIntent = advertisementPendingIntent(context, create = false) ?: return
        try {
            scanner.stopScan(pendingIntent)
            pendingIntent.cancel()
        } catch (_: RuntimeException) {
            // The scan may already be absent or Bluetooth may be changing state.
        }
    }

    fun recordScanFailure(context: Context, errorCode: Int) {
        recordFailure(context, "Bluetooth advertisement scan failed with code $errorCode")
    }

    private fun isAssociated(context: Context, address: String): Boolean {
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        @Suppress("DEPRECATION")
        return manager.associations.any { it.equals(address, ignoreCase = true) }
    }

    private fun startObserving(context: Context, address: String) {
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        Log.d(logTag, "Registering CDM BLE presence observation on API ${Build.VERSION.SDK_INT}")
        if (Build.VERSION.SDK_INT >= typedPresenceApi) {
            manager.startObservingDevicePresence(observingRequest(manager, address))
        } else {
            @Suppress("DEPRECATION")
            manager.startObservingDevicePresence(address)
        }
        Log.d(logTag, "CDM BLE presence observation registered")
    }

    private fun startAdvertisementScan(context: Context, plan: BackgroundSyncPlan) {
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw IllegalStateException("Bluetooth scan permission is unavailable")
        }
        val scanner = context.getSystemService(BluetoothManager::class.java)
            ?.adapter
            ?.bluetoothLeScanner
            ?: throw IllegalStateException("Bluetooth must be on for Background Sync")
        stopAdvertisementScan(context)
        val filter = ScanFilter.Builder()
            .setManufacturerData(
                plan.scanManufacturerId,
                plan.scanManufacturerData,
                plan.scanManufacturerMask,
            )
            .build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
            .setCallbackType(
                ScanSettings.CALLBACK_TYPE_FIRST_MATCH or
                    ScanSettings.CALLBACK_TYPE_MATCH_LOST,
            )
            .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
            .setNumOfMatches(ScanSettings.MATCH_NUM_ONE_ADVERTISEMENT)
            .build()
        val pendingIntent = checkNotNull(advertisementPendingIntent(context, create = true))
        val result = scanner.startScan(listOf(filter), settings, pendingIntent)
        if (result != 0) {
            pendingIntent.cancel()
            throw IllegalStateException(
                "Bluetooth advertisement scan registration failed with code $result",
            )
        }
        Log.d(logTag, "Background BLE advertisement scan registered")
    }

    private fun stopObserving(context: Context, address: String) {
        if (!hasCompanionSupport(context)) return
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        try {
            if (Build.VERSION.SDK_INT >= typedPresenceApi) {
                observingRequestOrNull(manager, address)?.let {
                    manager.stopObservingDevicePresence(it)
                }
            } else {
                @Suppress("DEPRECATION")
                manager.stopObservingDevicePresence(address)
            }
        } catch (_: RuntimeException) {
            // Opt-out must still remove local consent if observation is already gone.
        }
    }

    @RequiresApi(typedPresenceApi)
    private fun observingRequest(
        manager: CompanionDeviceManager,
        address: String,
    ): ObservingDevicePresenceRequest = observingRequestOrNull(manager, address)
        ?: throw IllegalStateException("The bike's companion association is missing")

    @RequiresApi(typedPresenceApi)
    private fun observingRequestOrNull(
        manager: CompanionDeviceManager,
        address: String,
    ): ObservingDevicePresenceRequest? {
        val associationId = manager.myAssociations
            .firstOrNull {
                it.deviceMacAddress?.toString()?.equals(address, ignoreCase = true) == true
            }
            ?.id ?: return null
        return ObservingDevicePresenceRequest.Builder()
            .setAssociationId(associationId)
            .build()
    }

    private fun disassociate(context: Context, address: String) {
        if (!hasCompanionSupport(context)) return
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        try {
            @Suppress("DEPRECATION")
            manager.disassociate(address)
        } catch (_: RuntimeException) {
            // The system association may already have been removed by the user.
        }
    }

    private fun advertisementPendingIntent(context: Context, create: Boolean): PendingIntent? {
        val intent = Intent(context, BackgroundScanReceiver::class.java)
            .setAction(scanAction)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            (if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE) or
                PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun recordFailure(context: Context, detail: String) {
        Log.w(logTag, "CDM presence registration failed: $detail")
        preferences(context)
            .edit()
            .putString(registrationErrorDetailKey, detail)
            .putLong(registrationErrorAtKey, System.currentTimeMillis())
            .apply()
    }
}
