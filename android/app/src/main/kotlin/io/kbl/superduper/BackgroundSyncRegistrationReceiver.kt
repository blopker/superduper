package io.kbl.superduper

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BackgroundSyncRegistrationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> BackgroundCompanionManager.restoreStored(context)

            BluetoothAdapter.ACTION_STATE_CHANGED -> {
                val state = intent.getIntExtra(
                    BluetoothAdapter.EXTRA_STATE,
                    BluetoothAdapter.ERROR,
                )
                if (state == BluetoothAdapter.STATE_ON) {
                    BackgroundCompanionManager.restoreStored(context)
                    NativeBackgroundSync.resumePending(context)
                }
            }
        }
    }
}
