package io.kbl.superduper

import android.companion.AssociationInfo
import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

class BackgroundSyncCompanionService : CompanionDeviceService() {
    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            synchronize(address, "address callback")
        }
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(address: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Log.d(logTag, "CDM BLE disappeared via address callback")
            NativeBackgroundSync.noteDisappearance(this, address, "cdmAddress")
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        if (Build.VERSION.SDK_INT < 36) {
            val address = associationInfo.deviceMacAddress?.toString()
            if (address == null) {
                Log.w(logTag, "CDM appearance has no Bluetooth address")
                return
            }
            synchronize(address, "association callback")
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(associationInfo: AssociationInfo) {
        if (Build.VERSION.SDK_INT < 36) {
            Log.d(logTag, "CDM BLE disappeared via association callback")
            val address = associationInfo.deviceMacAddress?.toString() ?: return
            NativeBackgroundSync.noteDisappearance(this, address, "cdmAssociation")
        }
    }

    @RequiresApi(36)
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        Log.d(
            logTag,
            "CDM presence event=${eventName(event.event)}(${event.event}) " +
                "association=${event.associationId}",
        )
        val address = BackgroundCompanionManager.deviceIdForAssociation(
            this,
            event.associationId,
        )
        if (address == null) {
            Log.w(logTag, "CDM presence event has no matching association")
            return
        }
        when (event.event) {
            DevicePresenceEvent.EVENT_BLE_APPEARED -> synchronize(address, "presence event")
            DevicePresenceEvent.EVENT_BLE_DISAPPEARED ->
                NativeBackgroundSync.noteDisappearance(this, address, "cdmPresence")
        }
    }

    private fun synchronize(address: String, callback: String) {
        Log.d(logTag, "CDM BLE appeared via $callback; requesting native sync")
        NativeBackgroundSync.synchronize(this, address, "bleAppeared")
    }

    private fun eventName(event: Int): String = when (event) {
        DevicePresenceEvent.EVENT_BLE_APPEARED -> "BLE_APPEARED"
        DevicePresenceEvent.EVENT_BLE_DISAPPEARED -> "BLE_DISAPPEARED"
        DevicePresenceEvent.EVENT_BT_CONNECTED -> "BT_CONNECTED"
        DevicePresenceEvent.EVENT_BT_DISCONNECTED -> "BT_DISCONNECTED"
        else -> "OTHER"
    }

    private companion object {
        const val logTag = "BackgroundSync"
    }
}
