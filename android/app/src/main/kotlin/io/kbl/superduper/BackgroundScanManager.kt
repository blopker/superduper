package io.kbl.superduper

import android.Manifest
import android.app.PendingIntent
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

internal object BackgroundScanManager {
    const val manufacturerId = 0x020f
    const val preferencesName = "background_sync"
    const val serialKey = "module_serial"
    const val presentKey = "bike_present"
    const val scanAction = "io.kbl.superduper.BACKGROUND_SCAN"

    private const val registrationErrorCodeKey = "registration_error_code"
    private const val registrationErrorDetailKey = "registration_error_detail"
    private const val registrationErrorAtKey = "registration_error_at_ms"

    private var registeredSerial: String? = null

    @Synchronized
    fun configure(context: Context, moduleSerial: String) {
        val normalized = normalizeSerial(moduleSerial)
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        preferences.edit().putString(serialKey, normalized).apply()
        try {
            register(context, normalized, reportFailure = true)
        } catch (error: RuntimeException) {
            preferences.edit().remove(serialKey).remove(presentKey).apply()
            throw error
        }
    }

    @Synchronized
    fun registerStored(context: Context): Boolean {
        val serial = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .getString(serialKey, null) ?: return true
        return try {
            register(context, normalizeSerial(serial), reportFailure = false)
        } catch (error: RuntimeException) {
            recordRegistrationFailure(context, null, error.message ?: error.javaClass.simpleName)
            false
        }
    }

    @Synchronized
    fun adapterUnavailable() {
        registeredSerial = null
    }

    @Synchronized
    fun scanFailed(context: Context, errorCode: Int) {
        registeredSerial = null
        recordRegistrationFailure(context, errorCode, "Bluetooth scan failed with code $errorCode")
    }

    @Synchronized
    fun cancel(context: Context) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .remove(serialKey)
            .remove(presentKey)
            .apply()
        registeredSerial = null
        if (!hasScanPermission(context)) {
            return
        }
        try {
            scanner(context)?.stopScan(pendingIntent(context))
        } catch (error: RuntimeException) {
            recordRegistrationFailure(
                context,
                null,
                "Bluetooth scan cancellation failed: ${error.message ?: error.javaClass.simpleName}",
            )
        }
    }

    private fun register(
        context: Context,
        normalizedSerial: String,
        reportFailure: Boolean,
    ): Boolean {
        if (registeredSerial == normalizedSerial) return true
        if (!hasScanPermission(context)) {
            return registrationUnavailable(
                context,
                reportFailure,
                "Bluetooth scan permission is required for Background Sync",
            )
        }
        val scanner = scanner(context)
            ?: return registrationUnavailable(
                context,
                reportFailure,
                "Bluetooth must be turned on to enable Background Sync",
            )
        val pendingIntent = pendingIntent(context)
        try {
            scanner.stopScan(pendingIntent)
        } catch (error: RuntimeException) {
            return registrationUnavailable(
                context,
                reportFailure,
                "Bluetooth scan reset failed: ${error.message ?: error.javaClass.simpleName}",
            )
        }
        val serial = decodeSerial(normalizedSerial)
        val filter = ScanFilter.Builder()
            .setManufacturerData(
                manufacturerId,
                serial,
                ByteArray(serial.size) { 0xff.toByte() },
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
        val result = scanner.startScan(listOf(filter), settings, pendingIntent)
        if (result != 0) {
            return registrationUnavailable(
                context,
                reportFailure,
                "Bluetooth scan registration failed with code $result",
                result,
            )
        }
        registeredSerial = normalizedSerial
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(presentKey, false)
            .remove(registrationErrorCodeKey)
            .remove(registrationErrorDetailKey)
            .remove(registrationErrorAtKey)
            .apply()
        return true
    }

    private fun registrationUnavailable(
        context: Context,
        reportFailure: Boolean,
        detail: String,
        errorCode: Int? = null,
    ): Boolean {
        registeredSerial = null
        recordRegistrationFailure(context, errorCode, detail)
        if (reportFailure) throw IllegalStateException(detail)
        return false
    }

    private fun recordRegistrationFailure(
        context: Context,
        errorCode: Int?,
        detail: String,
    ) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(registrationErrorDetailKey, detail)
            .putLong(registrationErrorAtKey, System.currentTimeMillis())
            .apply {
                if (errorCode == null) {
                    remove(registrationErrorCodeKey)
                } else {
                    putInt(registrationErrorCodeKey, errorCode)
                }
            }
            .apply()
    }

    private fun scanner(context: Context) =
        context.getSystemService(BluetoothManager::class.java)
            ?.adapter
            ?.bluetoothLeScanner

    private fun hasScanPermission(context: Context): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Manifest.permission.BLUETOOTH_SCAN
        } else {
            Manifest.permission.ACCESS_FINE_LOCATION
        }
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, BackgroundScanReceiver::class.java)
            .setAction(scanAction)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun normalizeSerial(value: String): String {
        val normalized = value.lowercase()
        require(normalized.matches(Regex("[0-9a-f]{16}"))) {
            "moduleSerial must contain exactly eight hexadecimal bytes"
        }
        return normalized
    }

    private fun decodeSerial(normalized: String) = ByteArray(8) { index ->
        normalized.substring(index * 2, index * 2 + 2).toInt(16).toByte()
    }
}
