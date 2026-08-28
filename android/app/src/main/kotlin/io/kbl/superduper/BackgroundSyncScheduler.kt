package io.kbl.superduper

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

internal object BackgroundSyncScheduler {
    fun enqueue(context: Context, deviceId: String, source: String) {
        val preferences = context.getSharedPreferences(
            BackgroundCompanionManager.preferencesName,
            Context.MODE_PRIVATE,
        )
        val storedDeviceId = preferences.getString(
            BackgroundCompanionManager.deviceIdKey,
            null,
        ) ?: return
        val serial = preferences.getString(
            BackgroundCompanionManager.serialKey,
            null,
        ) ?: return
        if (!storedDeviceId.equals(deviceId, ignoreCase = true)) return

        preferences.edit()
            .putLong("last_presence_at_ms", System.currentTimeMillis())
            .putString("last_presence_source", source)
            .apply()
        val request = OneTimeWorkRequestBuilder<BackgroundSyncWorker>()
            .setInputData(
                workDataOf(
                    BackgroundSyncWorker.deviceIdKey to storedDeviceId,
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
