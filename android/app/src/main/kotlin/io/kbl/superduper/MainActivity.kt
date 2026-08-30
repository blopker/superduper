package io.kbl.superduper

import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanResult
import android.companion.AssociationInfo
import android.companion.CompanionDeviceManager
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private data class PendingAssociation(
        val deviceId: String,
        val result: MethodChannel.Result,
        var chooserLaunched: Boolean = false,
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingAssociation: PendingAssociation? = null
    private var cancelledAssociationDeviceId: String? = null
    private val associationDiscoveryTimeout = Runnable {
        val pending = pendingAssociation ?: return@Runnable
        if (!pending.chooserLaunched) {
            failAssociation(
                "Android could not find this bike. Keep it on and nearby, then try again.",
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BackgroundCompanionManager.setConnectionPaused(applicationContext, false)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backgroundSyncChannel,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "configure" -> {
                        val deviceId = call.argument<String>("deviceId")
                            ?: throw IllegalArgumentException("deviceId is required")
                        val requestAssociation =
                            call.argument<Boolean>("requestAssociation") ?: false
                        configureBackgroundSync(
                            deviceId,
                            requestAssociation,
                            result,
                        )
                    }
                    "cancel" -> {
                        cancelPendingAssociation("Bike association was cancelled")
                        BackgroundCompanionManager.cancel(applicationContext)
                        result.success(null)
                    }
                    "setConnectionPaused" -> {
                        val paused = call.argument<Boolean>("paused")
                            ?: throw IllegalArgumentException("paused is required")
                        BackgroundCompanionManager.setConnectionPaused(
                            applicationContext,
                            paused,
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("background_sync", error.message, null)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        cancelPendingAssociation("Bike association was interrupted")
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backgroundSyncChannel,
        ).setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        BackgroundSyncRuntime.isActivityForeground = true
        NativeBackgroundSync.cancel("The app entered the foreground")
        super.onStart()
    }

    override fun onStop() {
        super.onStop()
        BackgroundSyncRuntime.isActivityForeground = false
    }

    @Deprecated("Association uses the platform chooser result on Android 12")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != companionAssociationRequestCode) return
        cancelledAssociationDeviceId?.let { address ->
            cancelledAssociationDeviceId = null
            BackgroundCompanionManager.removeAssociation(applicationContext, address)
            return
        }
        if (resultCode == Activity.RESULT_OK) {
            val approvedAddress = associationResultAddress(data)
            val expectedAddress = pendingAssociation?.deviceId
            if (approvedAddress != null &&
                expectedAddress != null &&
                !approvedAddress.equals(expectedAddress, ignoreCase = true)
            ) {
                BackgroundCompanionManager.removeAssociation(
                    applicationContext,
                    approvedAddress,
                )
                failAssociation("Android associated a different Bluetooth device")
                return
            }
            completeAssociation()
        } else {
            failAssociation("Bike association was cancelled")
        }
    }

    private fun configureBackgroundSync(
        deviceId: String,
        requestAssociation: Boolean,
        result: MethodChannel.Result,
    ) {
        val address = BackgroundCompanionManager.normalizeDeviceId(deviceId)
        if (!BackgroundCompanionManager.hasCompanionSupport(applicationContext)) {
            if (requestAssociation) {
                throw IllegalStateException(
                    "This phone does not support Android companion-device association",
                )
            }
            result.success(false)
            return
        }
        if (BackgroundCompanionManager.configureIfAssociated(
                applicationContext,
                address,
            )
        ) {
            result.success(true)
            return
        }
        if (!requestAssociation) {
            result.success(false)
            return
        }
        if (pendingAssociation != null) {
            throw IllegalStateException("Another bike association is already in progress")
        }
        if (cancelledAssociationDeviceId != null) {
            throw IllegalStateException("The previous bike association is still closing")
        }

        BackgroundCompanionManager.stopAdvertisementScan(applicationContext)
        pendingAssociation = PendingAssociation(address, result)
        try {
            val manager = getSystemService(CompanionDeviceManager::class.java)
            val request = BackgroundCompanionManager.associationRequest(address)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                manager.associate(request, mainExecutor, modernAssociationCallback())
            } else {
                @Suppress("DEPRECATION")
                manager.associate(request, legacyAssociationCallback(), mainHandler)
            }
            if (pendingAssociation?.chooserLaunched == false) {
                mainHandler.postDelayed(
                    associationDiscoveryTimeout,
                    associationDiscoveryTimeoutMs,
                )
            }
        } catch (error: Exception) {
            failAssociation(error.message ?: error.javaClass.simpleName)
        }
    }

    private fun legacyAssociationCallback() = object : CompanionDeviceManager.Callback() {
        @Deprecated("Called by Android's association callback on all supported versions")
        override fun onDeviceFound(intentSender: IntentSender) {
            launchAssociationChooser(intentSender)
        }

        override fun onFailure(error: CharSequence?) {
            failAssociation(error?.toString() ?: "Android could not associate this bike")
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun modernAssociationCallback() = object : CompanionDeviceManager.Callback() {
        override fun onAssociationPending(intentSender: IntentSender) {
            launchAssociationChooser(intentSender)
        }

        override fun onAssociationCreated(associationInfo: AssociationInfo) {
            val pending = pendingAssociation ?: return
            val address = associationInfo.deviceMacAddress?.toString()
            if (address == null || !address.equals(pending.deviceId, ignoreCase = true)) {
                address?.let {
                    BackgroundCompanionManager.removeAssociation(applicationContext, it)
                }
                failAssociation("Android associated a different Bluetooth device")
                return
            }
            completeAssociation()
        }

        override fun onFailure(error: CharSequence?) {
            failAssociation(error?.toString() ?: "Android could not associate this bike")
        }
    }

    private fun launchAssociationChooser(intentSender: IntentSender) {
        val pending = pendingAssociation ?: return
        if (pending.chooserLaunched) return
        pending.chooserLaunched = true
        clearAssociationDiscoveryTimeout()
        try {
            startIntentSenderForResult(
                intentSender,
                companionAssociationRequestCode,
                null,
                0,
                0,
                0,
            )
        } catch (error: IntentSender.SendIntentException) {
            failAssociation(error.message ?: "Android could not open bike association")
        }
    }

    private fun cancelPendingAssociation(message: String) {
        val pending = pendingAssociation ?: return
        pendingAssociation = null
        clearAssociationDiscoveryTimeout()
        if (pending.chooserLaunched) {
            cancelledAssociationDeviceId = pending.deviceId
            try {
                finishActivity(companionAssociationRequestCode)
            } catch (_: RuntimeException) {
                // The chooser may already be closing.
            }
            mainHandler.postDelayed(
                {
                    if (cancelledAssociationDeviceId == pending.deviceId) {
                        BackgroundCompanionManager.removeAssociation(
                            applicationContext,
                            pending.deviceId,
                        )
                        cancelledAssociationDeviceId = null
                    }
                },
                cancelledAssociationCleanupMs,
            )
        } else {
            BackgroundCompanionManager.removeAssociation(
                applicationContext,
                pending.deviceId,
            )
        }
        replyError(pending, message)
    }

    private fun replyError(pending: PendingAssociation, message: String) {
        try {
            pending.result.error("background_sync", message, null)
        } catch (error: RuntimeException) {
            Log.w(logTag, "Could not reply to the association request", error)
        }
    }

    private fun replySuccess(pending: PendingAssociation) {
        try {
            pending.result.success(true)
        } catch (error: RuntimeException) {
            Log.w(logTag, "Could not reply to the association request", error)
        }
    }

    private fun completeAssociation(attempt: Int = 0) {
        val pending = pendingAssociation ?: return
        val configured = try {
            BackgroundCompanionManager.configureIfAssociated(
                applicationContext,
                pending.deviceId,
            )
        } catch (error: Exception) {
            failAssociation(error.message ?: error.javaClass.simpleName)
            return
        }
        if (!configured) {
            if (attempt < associationPersistenceAttempts) {
                mainHandler.postDelayed(
                    {
                        if (pendingAssociation === pending) {
                            completeAssociation(attempt + 1)
                        }
                    },
                    associationPersistenceRetryMs,
                )
                return
            }
            failAssociation(
                "Android is still saving the bike association. Try enabling Background Sync again.",
            )
            return
        }
        pendingAssociation = null
        clearAssociationDiscoveryTimeout()
        replySuccess(pending)
    }

    private fun failAssociation(message: String) {
        val pending = pendingAssociation ?: return
        pendingAssociation = null
        clearAssociationDiscoveryTimeout()
        replyError(pending, message)
    }

    private fun clearAssociationDiscoveryTimeout() {
        mainHandler.removeCallbacks(associationDiscoveryTimeout)
    }

    private fun associationResultAddress(data: Intent?): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return data
                ?.getParcelableExtra(
                    CompanionDeviceManager.EXTRA_ASSOCIATION,
                    AssociationInfo::class.java,
                )
                ?.deviceMacAddress
                ?.toString()
        }
        @Suppress("DEPRECATION")
        val device = data?.getParcelableExtra<Parcelable>(
            CompanionDeviceManager.EXTRA_DEVICE,
        )
        return when (device) {
            is BluetoothDevice -> device.address
            is ScanResult -> device.device.address
            else -> null
        }
    }

    companion object {
        private const val backgroundSyncChannel = "io.kbl.superduper/background_sync"
        private const val logTag = "BackgroundSync"
        private const val companionAssociationRequestCode = 8107
        private const val associationPersistenceAttempts = 100
        private const val associationPersistenceRetryMs = 50L
        private const val associationDiscoveryTimeoutMs = 45_000L
        private const val cancelledAssociationCleanupMs = 1_000L
    }
}
