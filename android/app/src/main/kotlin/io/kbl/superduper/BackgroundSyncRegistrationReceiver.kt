package io.kbl.superduper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundSyncRegistrationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> BackgroundCompanionManager.restoreStored(context)
        }
    }
}
