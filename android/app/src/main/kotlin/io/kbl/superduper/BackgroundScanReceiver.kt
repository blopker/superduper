package io.kbl.superduper

import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.BackoffPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

class BackgroundScanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != BackgroundScanManager.scanAction) return
        val preferences = context.getSharedPreferences(
            BackgroundScanManager.preferencesName,
            Context.MODE_PRIVATE,
        )
        val serial = preferences.getString(BackgroundScanManager.serialKey, null) ?: return
        val error = intent.getIntExtra(BluetoothLeScanner.EXTRA_ERROR_CODE, 0)
        if (error != 0) {
            BackgroundScanManager.scanFailed(context, error)
            val recovery = OneTimeWorkRequestBuilder<BackgroundScanRecoveryWorker>()
                .setInitialDelay(30, TimeUnit.SECONDS)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                "background-scan-recovery",
                ExistingWorkPolicy.REPLACE,
                recovery,
            )
            return
        }
        val callbackType = intent.getIntExtra(
            BluetoothLeScanner.EXTRA_CALLBACK_TYPE,
            ScanSettings.CALLBACK_TYPE_ALL_MATCHES,
        )
        if (callbackType and ScanSettings.CALLBACK_TYPE_MATCH_LOST != 0) {
            preferences.edit().putBoolean(BackgroundScanManager.presentKey, false).apply()
            return
        }
        if (preferences.getBoolean(BackgroundScanManager.presentKey, false)) return
        @Suppress("DEPRECATION")
        val results = intent.getParcelableArrayListExtra<ScanResult>(
            BluetoothLeScanner.EXTRA_LIST_SCAN_RESULT,
        ) ?: return
        val result = results.firstOrNull() ?: return
        preferences.edit().putBoolean(BackgroundScanManager.presentKey, true).apply()
        val request = OneTimeWorkRequestBuilder<BackgroundSyncWorker>()
            .setInputData(
                workDataOf(
                    BackgroundSyncWorker.deviceIdKey to result.device.address,
                    BackgroundSyncWorker.moduleSerialKey to serial,
                ),
            )
            .setBackoffCriteria(BackoffPolicy.LINEAR, 10, TimeUnit.SECONDS)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            "background-sync-$serial",
            ExistingWorkPolicy.KEEP,
            request,
        )
    }
}
