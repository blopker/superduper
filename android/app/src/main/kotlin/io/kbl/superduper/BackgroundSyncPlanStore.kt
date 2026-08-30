package io.kbl.superduper

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import io.flutter.util.PathUtils
import java.io.File

internal data class BackgroundSyncPlan(
    val deviceId: String,
    val commands: List<ByteArray>,
)

internal object BackgroundSyncPlanStore {
    private const val databaseFilename = "superduper.sqlite"
    private const val minimumSchemaVersion = 4
    private const val supportedPlanVersion = 1

    fun load(context: Context, expectedDeviceId: String): BackgroundSyncPlan? {
        val databaseFile = File(PathUtils.getDataDirectory(context), databaseFilename)
        if (!databaseFile.isFile) return null

        val flags = SQLiteDatabase.OPEN_READONLY or SQLiteDatabase.NO_LOCALIZED_COLLATORS
        return SQLiteDatabase.openDatabase(databaseFile.path, null, flags).use { database ->
            if (database.schemaVersion() < minimumSchemaVersion) return@use null
            database.rawQuery(
                """
                SELECT p.plan_version, p.device_id, c.sequence, c.payload
                FROM background_sync_plans AS p
                INNER JOIN background_sync_commands AS c
                  ON c.plan_singleton_id = p.singleton_id
                WHERE p.singleton_id = 1
                ORDER BY c.sequence
                """.trimIndent(),
                null,
            ).use { cursor ->
                var deviceId: String? = null
                val commands = mutableListOf<ByteArray>()
                while (cursor.moveToNext()) {
                    check(cursor.getInt(0) == supportedPlanVersion) {
                        "Unsupported background command plan version"
                    }
                    val rowDeviceId = cursor.getString(1)
                    check(rowDeviceId.equals(expectedDeviceId, ignoreCase = true)) {
                        "The background command plan belongs to a different bike"
                    }
                    check(deviceId == null || deviceId == rowDeviceId) {
                        "The background command plan contains multiple bikes"
                    }
                    check(cursor.getInt(2) == commands.size) {
                        "The background command plan sequence is invalid"
                    }
                    val command = cursor.getBlob(3)
                    validateCommand(command)
                    deviceId = rowDeviceId
                    commands.add(command)
                }
                deviceId?.let { BackgroundSyncPlan(expectedDeviceId, commands) }
            }
        }
    }

    private fun SQLiteDatabase.schemaVersion(): Int =
        rawQuery("PRAGMA user_version", null).use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }

    private fun validateCommand(command: ByteArray) {
        check(command.size == 10) { "A background command must contain 10 bytes" }
        check(command[0].unsigned == 0) { "A background command has an invalid prefix" }
        check(command[1].unsigned == 0xd1 || command[1].unsigned == 0xc1) {
            "A background command has an unsupported packet ID"
        }
        check((5 until command.size).all { command[it].unsigned == 0 }) {
            "A background command has an invalid reserved byte"
        }
    }

    private val Byte.unsigned: Int
        get() = toInt() and 0xff
}
