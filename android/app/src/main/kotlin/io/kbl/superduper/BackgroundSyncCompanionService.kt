package io.kbl.superduper

import android.companion.CompanionDeviceService

class BackgroundSyncCompanionService : CompanionDeviceService() {
    @Suppress("DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        BackgroundSyncScheduler.enqueue(this, address, "companion")
    }
}
