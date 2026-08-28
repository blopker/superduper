package io.kbl.superduper

import android.app.Activity
import android.companion.CompanionDeviceManager
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.Handler
import android.os.Looper
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

    private var pendingAssociation: PendingAssociation? = null

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
        pendingAssociation?.let {
            BackgroundCompanionManager.removeAssociation(
                applicationContext,
                it.deviceId,
            )
        }
        pendingAssociation?.result?.error(
            "background_sync",
            "Bike association was interrupted",
            null,
        )
        pendingAssociation = null
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
        if (BackgroundCompanionManager.configureIfAssociated(
                applicationContext,
                address,
                serial,
            )
        ) {
            result.success(null)
            return
        }
        if (!requestAssociation) {
            throw IllegalStateException(
                "Open Background Sync and associate this bike again",
            )
        }
        if (pendingAssociation != null) {
            throw IllegalStateException("Another bike association is already in progress")
        }

        BackgroundCompanionManager.cancelLegacyScan(applicationContext)
        pendingAssociation = PendingAssociation(address, serial, result)
        val manager = getSystemService(CompanionDeviceManager::class.java)
        val request = BackgroundCompanionManager.associationRequest(address)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            associateModern(manager, request)
        } else {
            val callback = object : CompanionDeviceManager.Callback() {
                @Deprecated("Called by Android 12")
                override fun onDeviceFound(intentSender: IntentSender) {
                    launchAssociationChooser(intentSender)
                }

                override fun onFailure(error: CharSequence?) {
                    failAssociation(
                        error?.toString() ?: "Android could not associate this bike",
                    )
                }
            }
            @Suppress("DEPRECATION")
            manager.associate(request, callback, Handler(Looper.getMainLooper()))
        }
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun associateModern(
        manager: CompanionDeviceManager,
        request: android.companion.AssociationRequest,
    ) {
        val callback = object : CompanionDeviceManager.Callback() {
            override fun onAssociationPending(intentSender: IntentSender) {
                launchAssociationChooser(intentSender)
            }

            override fun onFailure(error: CharSequence?) {
                failAssociation(error?.toString() ?: "Android could not associate this bike")
            }

            override fun onFailure(errorCode: Int, error: CharSequence?) {
                failAssociation(
                    error?.toString()
                        ?: "Android could not associate this bike (code $errorCode)",
                )
            }
        }
        manager.associate(request, mainExecutor, callback)
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

    private fun completeAssociation() {
        val pending = pendingAssociation ?: return
        try {
            if (!BackgroundCompanionManager.configureIfAssociated(
                    applicationContext,
                    pending.deviceId,
                    pending.moduleSerial,
                )
            ) {
                BackgroundCompanionManager.removeAssociation(
                    applicationContext,
                    pending.deviceId,
                )
                failAssociation("Android did not save the bike association")
                return
            }
            pendingAssociation = null
            pending.result.success(null)
        } catch (error: Exception) {
            BackgroundCompanionManager.removeAssociation(
                applicationContext,
                pending.deviceId,
            )
            failAssociation(error.message ?: error.javaClass.simpleName)
        }
    }

    private fun failAssociation(message: String) {
        val pending = pendingAssociation ?: return
        pendingAssociation = null
        pending.result.error("background_sync", message, null)
    }

    companion object {
        private const val companionAssociationRequestCode = 8107
    }
}
