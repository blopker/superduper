package io.kbl.superduper

internal object BackgroundSyncRuntime {
    @Volatile
    var isActivityForeground = false
}
