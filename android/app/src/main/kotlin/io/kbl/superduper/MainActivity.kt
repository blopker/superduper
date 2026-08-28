package io.kbl.superduper

import android.app.Activity
import android.companion.CompanionDeviceManager
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private data class PendingAssociation(
        val deviceId: String,
        val moduleSerial: String,
        val result: MethodChannel.Result,
        var chooserLaunched: Boolean = false,
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingAssociation: PendingAssociation? = null
    private var cancelledAssociationDeviceId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BackgroundSyncEngineRegistry.attach(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BackgroundSyncChannels.control,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "configure" -> {
                        val deviceId = call.argument<String>("deviceId")
                            ?: throw IllegalArgumentException("deviceId is required")
                        val serial = call.argument<String>("moduleSerial")
                            ?: throw IllegalArgumentException("moduleSerial is required")
                        val requestAssociation =
                            call.argument<Boolean>("requestAssociation") ?: false
                        configureBackgroundSync(
                            deviceId,
                            serial,
                            requestAssociation,
                            result,
                        )
                    }
                    "cancel" -> {
                        cancelPendingAssociation("Bike association was cancelled")
                        BackgroundCompanionManager.cancel(applicationContext)
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
            BackgroundSyncChannels.control,
        ).setMethodCallHandler(null)
        BackgroundSyncEngineRegistry.detach(flutterEngine)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        BackgroundSyncEngineRegistry.isActivityForeground = true
    }

    override fun onResume() {
        super.onResume()
        BackgroundCompanionManager.restoreStored(applicationContext)
    }

    override fun onStop() {
        BackgroundSyncEngineRegistry.isActivityForeground = false
        super.onStop()
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
            completeAssociation()
        } else {
            failAssociation("Bike association was cancelled")
        }
    }

    private fun configureBackgroundSync(
        deviceId: String,
        moduleSerial: String,
        requestAssociation: Boolean,
        result: MethodChannel.Result,
    ) {
        val address = BackgroundCompanionManager.normalizeDeviceId(deviceId)
        val serial = BackgroundCompanionManager.normalizeSerial(moduleSerial)
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
                serial,
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

        BackgroundCompanionManager.cancelLegacyScan(applicationContext)
        pendingAssociation = PendingAssociation(address, serial, result)
        try {
            val manager = getSystemService(CompanionDeviceManager::class.java)
            val request = BackgroundCompanionManager.associationRequest(address)
            val callback = associationCallback()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                manager.associate(request, mainExecutor, callback)
            } else {
                @Suppress("DEPRECATION")
                manager.associate(request, callback, mainHandler)
            }
        } catch (error: Exception) {
            failAssociation(error.message ?: error.javaClass.simpleName)
        }
    }

    private fun associationCallback() = object : CompanionDeviceManager.Callback() {
        @Deprecated("Called by Android's association callback on all supported versions")
        override fun onDeviceFound(intentSender: IntentSender) {
            launchAssociationChooser(intentSender)
        }

        override fun onFailure(error: CharSequence?) {
            failAssociation(error?.toString() ?: "Android could not associate this bike")
        }
    }

    private fun launchAssociationChooser(intentSender: IntentSender) {
        val pending = pendingAssociation ?: return
        if (pending.chooserLaunched) return
        pending.chooserLaunched = true
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
        }
        BackgroundCompanionManager.removeAssociation(
            applicationContext,
            pending.deviceId,
        )
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
                pending.moduleSerial,
            )
        } catch (error: Exception) {
            BackgroundCompanionManager.removeAssociation(
                applicationContext,
                pending.deviceId,
            )
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
            BackgroundCompanionManager.removeAssociation(
                applicationContext,
                pending.deviceId,
            )
            failAssociation("Android did not save the bike association")
            return
        }
        pendingAssociation = null
        replySuccess(pending)
    }

    private fun failAssociation(message: String) {
        val pending = pendingAssociation ?: return
        pendingAssociation = null
        replyError(pending, message)
    }

    companion object {
        private const val logTag = "BackgroundSync"
        private const val companionAssociationRequestCode = 8107
        private const val associationPersistenceAttempts = 20
        private const val associationPersistenceRetryMs = 50L
        private const val cancelledAssociationCleanupMs = 1_000L
    }
}
