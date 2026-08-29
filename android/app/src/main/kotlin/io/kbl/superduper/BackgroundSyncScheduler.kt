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
    fun enqueue(
        context: Context,
        deviceId: String,
        source: String,
        initialDelaySeconds: Long = 0,
    ) {
        val preferences = BackgroundCompanionManager.preferences(context)
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
            .putLong(
                BackgroundCompanionManager.lastPresenceAtKey,
                System.currentTimeMillis(),
            )
            .putString(BackgroundCompanionManager.lastPresenceSourceKey, source)
            .commit()
        val requestBuilder = OneTimeWorkRequestBuilder<BackgroundSyncWorker>()
            .setInputData(
                workDataOf(
                    BackgroundCompanionManager.deviceIdKey to storedDeviceId,
                    BackgroundCompanionManager.serialKey to serial,
                ),
            )
            .setBackoffCriteria(BackoffPolicy.LINEAR, 10, TimeUnit.SECONDS)
        if (initialDelaySeconds > 0) {
            requestBuilder.setInitialDelay(initialDelaySeconds, TimeUnit.SECONDS)
        } else {
            requestBuilder.setExpedited(
                OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST,
            )
        }
        val request = requestBuilder.build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            BackgroundCompanionManager.workName(serial),
            ExistingWorkPolicy.KEEP,
            request,
        )
    }
}
