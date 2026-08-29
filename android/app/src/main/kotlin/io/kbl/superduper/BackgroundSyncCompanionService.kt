package io.kbl.superduper

import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent
import android.os.Build
import androidx.annotation.RequiresApi

class BackgroundSyncCompanionService : CompanionDeviceService() {
    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        if (Build.VERSION.SDK_INT < 36 &&
            !BackgroundSyncEngineRegistry.isActivityForeground
        ) {
            BackgroundSyncScheduler.enqueue(this, address, "companion")
        }
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(address: String) {
        if (Build.VERSION.SDK_INT < 36) {
            BackgroundSyncScheduler.enqueue(
                this,
                address,
                "companionDisconnect",
                initialDelaySeconds = 10,
            )
        }
    }

    @RequiresApi(36)
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        val address = BackgroundCompanionManager.deviceIdForAssociation(
            this,
            event.associationId,
        ) ?: return
        when (event.event) {
            DevicePresenceEvent.EVENT_BLE_APPEARED ->
                BackgroundSyncScheduler.enqueue(this, address, "companion")

            DevicePresenceEvent.EVENT_BT_DISCONNECTED ->
                BackgroundSyncScheduler.enqueue(
                    this,
                    address,
                    "companionDisconnect",
                    initialDelaySeconds = 10,
                )
        }
    }
}
