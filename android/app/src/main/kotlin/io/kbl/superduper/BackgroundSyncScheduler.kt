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
        if (source == "companion" &&
            preferences.getBoolean(BackgroundCompanionManager.companionPresentKey, false)
        ) {
            return
        }

        val editor = preferences.edit()
            .putLong(
                BackgroundCompanionManager.lastPresenceAtKey,
                System.currentTimeMillis(),
            )
            .putString(BackgroundCompanionManager.lastPresenceSourceKey, source)
        if (source == "companion") {
            editor.putBoolean(BackgroundCompanionManager.companionPresentKey, true)
        }
        editor.commit()
        val request = OneTimeWorkRequestBuilder<BackgroundSyncWorker>()
            .setInputData(
                workDataOf(
                    BackgroundCompanionManager.deviceIdKey to storedDeviceId,
                    BackgroundCompanionManager.serialKey to serial,
                ),
            )
            .setBackoffCriteria(BackoffPolicy.LINEAR, 10, TimeUnit.SECONDS)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            BackgroundCompanionManager.workName(serial),
            ExistingWorkPolicy.KEEP,
            request,
        )
    }
}
