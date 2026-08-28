package io.kbl.superduper

import android.Manifest
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanFilter
import android.companion.AssociationRequest
import android.companion.BluetoothLeDeviceFilter
import android.companion.CompanionDeviceManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import androidx.work.WorkManager

internal object BackgroundCompanionManager {
    const val preferencesName = "background_sync"
    const val deviceIdKey = "device_id"
    const val serialKey = "module_serial"
    const val lastPresenceAtKey = "last_presence_at_ms"
    const val lastPresenceSourceKey = "last_presence_source"
    const val lastWorkerStartedAtKey = "last_worker_started_at_ms"
    const val lastOutcomeKey = "last_outcome"
    const val lastDetailKey = "last_detail"
    const val lastCompletedAtKey = "last_completed_at_ms"
    const val companionPresentKey = "companion_present"

    private const val legacyPresentKey = "bike_present"
    private const val legacyScanAction = "io.kbl.superduper.BACKGROUND_SCAN"
    private const val registrationErrorDetailKey = "registration_error_detail"
    private const val registrationErrorAtKey = "registration_error_at_ms"

    fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    fun workName(serial: String): String = "background-sync-${normalizeSerial(serial)}"

    fun normalizeDeviceId(value: String): String {
        val normalized = value.uppercase()
        require(BluetoothAdapter.checkBluetoothAddress(normalized)) {
            "The saved bike does not have a valid Bluetooth address"
        }
        return normalized
    }

    fun normalizeSerial(value: String): String {
        val normalized = value.lowercase()
        require(normalized.matches(Regex("[0-9a-f]{16}"))) {
            "moduleSerial must contain exactly eight hexadecimal bytes"
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
        moduleSerial: String,
    ): Boolean {
        val address = normalizeDeviceId(deviceId)
        val serial = normalizeSerial(moduleSerial)
        if (!hasCompanionSupport(context)) {
            throw IllegalStateException(
                "This phone does not support Android companion-device association",
            )
        }
        if (!isAssociated(context, address)) return false

        val preferences = preferences(context)
        val previousAddress = preferences.getString(deviceIdKey, null)
        val previousSerial = preferences.getString(serialKey, null)
        if (previousAddress != null && !previousAddress.equals(address, ignoreCase = true)) {
            stopObserving(context, previousAddress)
            disassociate(context, previousAddress)
        }
        if (previousSerial != null && previousSerial != serial) {
            WorkManager.getInstance(context).cancelUniqueWork(
                workName(previousSerial),
            )
        }
        preferences
            .edit()
            .putString(deviceIdKey, address)
            .putString(serialKey, serial)
            .putBoolean(companionPresentKey, false)
            .remove(legacyPresentKey)
            .remove(registrationErrorDetailKey)
            .remove(registrationErrorAtKey)
            .commit()
        cancelLegacyScan(context)
        startObserving(context, address)
        return true
    }

    fun restoreStored(context: Context) {
        val preferences = preferences(context)
        val address = preferences.getString(deviceIdKey, null) ?: run {
            cancelLegacyScan(context)
            return
        }
        val serial = preferences.getString(serialKey, null) ?: return
        try {
            if (!configureIfAssociated(context, address, serial)) {
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
        val serial = preferences.getString(serialKey, null)
        if (address != null) {
            stopObserving(context, address)
            disassociate(context, address)
        }
        if (serial != null) {
            WorkManager.getInstance(context).cancelUniqueWork(
                workName(serial),
            )
        }
        preferences.edit()
            .remove(deviceIdKey)
            .remove(serialKey)
            .remove(legacyPresentKey)
            .remove(companionPresentKey)
            .apply()
        cancelLegacyScan(context)
    }

    fun removeAssociation(context: Context, deviceId: String) {
        val address = normalizeDeviceId(deviceId)
        stopObserving(context, address)
        disassociate(context, address)
    }

    fun markCompanionAbsent(context: Context, deviceId: String) {
        val preferences = preferences(context)
        val storedDeviceId = preferences.getString(deviceIdKey, null) ?: return
        if (!storedDeviceId.equals(deviceId, ignoreCase = true)) return
        preferences.edit().putBoolean(companionPresentKey, false).apply()
    }

    fun cancelLegacyScan(context: Context) {
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val scanner = context.getSystemService(BluetoothManager::class.java)
            ?.adapter
            ?.bluetoothLeScanner ?: return
        val pendingIntent = legacyPendingIntent(context) ?: return
        try {
            scanner.stopScan(pendingIntent)
            pendingIntent.cancel()
        } catch (_: RuntimeException) {
            // The legacy registration may not exist or Bluetooth may be changing state.
        }
    }

    private fun isAssociated(context: Context, address: String): Boolean {
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        @Suppress("DEPRECATION")
        return manager.associations.any { it.equals(address, ignoreCase = true) }
    }

    private fun startObserving(context: Context, address: String) {
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        @Suppress("DEPRECATION")
        manager.startObservingDevicePresence(address)
    }

    private fun stopObserving(context: Context, address: String) {
        if (!hasCompanionSupport(context)) return
        val manager = context.getSystemService(CompanionDeviceManager::class.java)
        try {
            @Suppress("DEPRECATION")
            manager.stopObservingDevicePresence(address)
        } catch (_: RuntimeException) {
            // Opt-out must still remove local consent if observation is already gone.
        }
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

    private fun legacyPendingIntent(context: Context): PendingIntent? {
        // These values must remain identical to the scan registration shipped
        // before CompanionDeviceManager so upgrades can cancel that PendingIntent.
        val intent = Intent(context, BackgroundScanReceiver::class.java)
            .setAction(legacyScanAction)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun recordFailure(context: Context, detail: String) {
        preferences(context)
            .edit()
            .putString(registrationErrorDetailKey, detail)
            .putLong(registrationErrorAtKey, System.currentTimeMillis())
            .apply()
    }
}
