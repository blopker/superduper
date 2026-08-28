package io.kbl.superduper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundScanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        BackgroundCompanionManager.cancelLegacyScan(context)
    }
}
