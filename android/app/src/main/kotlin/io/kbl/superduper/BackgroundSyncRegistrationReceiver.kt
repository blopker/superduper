package io.kbl.superduper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundSyncRegistrationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        BackgroundCompanionManager.restoreStored(context)
    }
}
