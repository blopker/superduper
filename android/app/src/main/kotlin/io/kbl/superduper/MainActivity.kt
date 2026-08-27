package io.kbl.superduper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
                        val serial = call.argument<String>("moduleSerial")
                            ?: throw IllegalArgumentException("moduleSerial is required")
                        BackgroundScanManager.configure(applicationContext, serial)
                        result.success(null)
                    }
                    "cancel" -> {
                        BackgroundScanManager.cancel(applicationContext)
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
        BackgroundScanManager.registerStored(applicationContext)
    }

    override fun onStop() {
        BackgroundSyncEngineRegistry.isActivityForeground = false
        super.onStop()
    }
}
