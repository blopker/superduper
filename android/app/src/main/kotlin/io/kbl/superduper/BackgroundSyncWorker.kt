package io.kbl.superduper

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout

internal object BackgroundSyncChannels {
    const val control = "io.kbl.superduper/background_sync"
    const val worker = "io.kbl.superduper/background_sync_worker"
}

internal object BackgroundSyncEngineRegistry {
    private var engineReference = WeakReference<FlutterEngine>(null)

    @Volatile
    var isActivityForeground = false

    @Synchronized
    fun attach(engine: FlutterEngine) {
        engineReference = WeakReference(engine)
    }

    @Synchronized
    fun detach(engine: FlutterEngine) {
        if (engineReference.get() === engine) engineReference.clear()
    }

    @Synchronized
    fun current(): FlutterEngine? = engineReference.get()
}

private class FlutterHandlerUnavailable : IllegalStateException(
    "The running Flutter engine has no background handler",
)

class BackgroundSyncWorker(
    context: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val deviceId = inputData.getString(deviceIdKey) ?: return Result.failure()
        val moduleSerial = inputData.getString(moduleSerialKey) ?: return Result.failure()
        applicationContext.getSharedPreferences(
            BackgroundCompanionManager.preferencesName,
            Context.MODE_PRIVATE,
        ).edit().putLong("last_worker_started_at_ms", System.currentTimeMillis()).apply()
        if (BackgroundSyncEngineRegistry.isActivityForeground) {
            return finish(mapOf("outcome" to "skippedForeground", "detail" to null))
        }
        return try {
            val outcome = withTimeout(90_000) {
                withContext(Dispatchers.Main) {
                    val existing = BackgroundSyncEngineRegistry.current()
                    if (existing != null) {
                        if (!existing.dartExecutor.isExecutingDart) {
                            throw FlutterHandlerUnavailable()
                        }
                        runOnExistingEngine(existing, deviceId, moduleSerial)
                    } else {
                        runOnHeadlessEngine(deviceId, moduleSerial)
                    }
                }
            }
            finish(outcome)
        } catch (error: FlutterHandlerUnavailable) {
            if (runAttemptCount < 2) {
                Result.retry()
            } else {
                finish(
                    mapOf(
                        "outcome" to "failed",
                        "detail" to error.message,
                    ),
                )
            }
        } catch (error: Exception) {
            finish(
                mapOf(
                    "outcome" to "failed",
                    "detail" to (error.message ?: error.javaClass.simpleName),
                ),
            )
        }
    }

    private suspend fun runOnExistingEngine(
        engine: FlutterEngine,
        deviceId: String,
        moduleSerial: String,
    ): Map<String, Any?> {
        val completion = CompletableDeferred<Map<String, Any?>>()
        MethodChannel(engine.dartExecutor.binaryMessenger, BackgroundSyncChannels.control)
            .invokeMethod(
                "run",
                mapOf("deviceId" to deviceId, "moduleSerial" to moduleSerial),
                channelResult(completion),
            )
        return completion.await()
    }

    private suspend fun runOnHeadlessEngine(
        deviceId: String,
        moduleSerial: String,
    ): Map<String, Any?> {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val engine = FlutterEngine(applicationContext)
        val completion = CompletableDeferred<Map<String, Any?>>()
        val channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            BackgroundSyncChannels.worker,
        )
        channel.setMethodCallHandler { call, result ->
            if (call.method == "complete") {
                @Suppress("UNCHECKED_CAST")
                completion.complete(call.arguments as Map<String, Any?>)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        return try {
            val entrypoint = DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "backgroundSyncMain",
            )
            engine.dartExecutor.executeDartEntrypoint(
                entrypoint,
                listOf(deviceId, moduleSerial),
            )
            completion.await()
        } finally {
            channel.setMethodCallHandler(null)
            engine.destroy()
        }
    }

    private fun channelResult(
        completion: CompletableDeferred<Map<String, Any?>>,
    ) = object : MethodChannel.Result {
        override fun success(result: Any?) {
            @Suppress("UNCHECKED_CAST")
            completion.complete(result as Map<String, Any?>)
        }

        override fun error(code: String, message: String?, details: Any?) {
            completion.completeExceptionally(IllegalStateException("$code: $message"))
        }

        override fun notImplemented() {
            completion.completeExceptionally(FlutterHandlerUnavailable())
        }
    }

    private fun finish(outcome: Map<String, Any?>): Result {
        val name = outcome["outcome"]?.toString() ?: "failed"
        val detail = outcome["detail"]?.toString()
        applicationContext.getSharedPreferences(
            BackgroundCompanionManager.preferencesName,
            Context.MODE_PRIVATE,
        ).edit()
            .putString("last_outcome", name)
            .putString("last_detail", detail)
            .putLong("last_completed_at_ms", System.currentTimeMillis())
            .apply()
        val output = if (detail == null) {
            workDataOf("outcome" to name)
        } else {
            workDataOf("outcome" to name, "detail" to detail)
        }
        return Result.success(output)
    }

    companion object {
        const val deviceIdKey = "device_id"
        const val moduleSerialKey = "module_serial"
    }
}
