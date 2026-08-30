package io.kbl.superduper

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import io.flutter.util.PathUtils
import java.io.File
import java.security.MessageDigest
import java.util.UUID

internal data class BackgroundSyncPlan(
    val deviceId: String,
    val scanManufacturerId: Int,
    val scanManufacturerData: ByteArray,
    val scanManufacturerMask: ByteArray,
    val authenticationServiceUuid: UUID,
    val authenticationChallengeUuid: UUID,
    val authenticationResponseUuid: UUID,
    val authenticationStateUuid: UUID,
    val authenticationChallengeLength: Int,
    val authenticationDigest: String,
    val authenticationKey: ByteArray,
    val authenticatedState: ByteArray,
    val commandServiceUuid: UUID,
    val commandCharacteristicUuid: UUID,
    val commands: List<ByteArray>,
)

internal object BackgroundSyncPlanStore {
    private const val databaseFilename = "superduper.sqlite"
    private const val minimumSchemaVersion = 5
    private const val supportedPlanVersion = 2

    fun load(context: Context, expectedDeviceId: String): BackgroundSyncPlan? {
        val databaseFile = File(PathUtils.getDataDirectory(context), databaseFilename)
        if (!databaseFile.isFile) return null

        val flags = SQLiteDatabase.OPEN_READONLY or SQLiteDatabase.NO_LOCALIZED_COLLATORS
        return SQLiteDatabase.openDatabase(databaseFile.path, null, flags).use { database ->
            if (database.schemaVersion() < minimumSchemaVersion) return@use null
            database.rawQuery(
                """
                SELECT
                  p.plan_version,
                  p.device_id,
                  p.scan_manufacturer_id,
                  p.scan_manufacturer_data,
                  p.scan_manufacturer_mask,
                  p.authentication_service_uuid,
                  p.authentication_challenge_uuid,
                  p.authentication_response_uuid,
                  p.authentication_state_uuid,
                  p.authentication_challenge_length,
                  p.authentication_digest,
                  p.authentication_key,
                  p.authenticated_state,
                  p.command_service_uuid,
                  p.command_characteristic_uuid,
                  c.sequence,
                  c.payload
                FROM background_sync_plans AS p
                INNER JOIN background_sync_commands AS c
                  ON c.plan_singleton_id = p.singleton_id
                WHERE p.singleton_id = 1
                ORDER BY c.sequence
                """.trimIndent(),
                null,
            ).use { cursor ->
                var plan: BackgroundSyncPlan? = null
                val commands = mutableListOf<ByteArray>()
                while (cursor.moveToNext()) {
                    check(cursor.getInt(0) == supportedPlanVersion) {
                        "Unsupported background command plan version"
                    }
                    val rowDeviceId = cursor.getString(1)
                    check(rowDeviceId.equals(expectedDeviceId, ignoreCase = true)) {
                        "The background command plan belongs to a different bike"
                    }
                    check(cursor.getInt(15) == commands.size) {
                        "The background command plan sequence is invalid"
                    }
                    val command = cursor.getBlob(16)
                    validateCommand(command)
                    if (plan == null) {
                        plan = BackgroundSyncPlan(
                            deviceId = expectedDeviceId,
                            scanManufacturerId = cursor.getInt(2),
                            scanManufacturerData = cursor.getBlob(3),
                            scanManufacturerMask = cursor.getBlob(4),
                            authenticationServiceUuid = cursor.uuid(5),
                            authenticationChallengeUuid = cursor.uuid(6),
                            authenticationResponseUuid = cursor.uuid(7),
                            authenticationStateUuid = cursor.uuid(8),
                            authenticationChallengeLength = cursor.getInt(9),
                            authenticationDigest = cursor.getString(10),
                            authenticationKey = cursor.getBlob(11),
                            authenticatedState = cursor.getBlob(12),
                            commandServiceUuid = cursor.uuid(13),
                            commandCharacteristicUuid = cursor.uuid(14),
                            commands = commands,
                        ).also(::validatePlan)
                    }
                    commands.add(command)
                }
                plan
            }
        }
    }

    private fun SQLiteDatabase.schemaVersion(): Int =
        rawQuery("PRAGMA user_version", null).use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }

    private fun validateCommand(command: ByteArray) {
        check(command.isNotEmpty()) { "A background command must not be empty" }
        check(command.size <= maximumAttributeValueLength) {
            "A background command is too large"
        }
    }

    private fun validatePlan(plan: BackgroundSyncPlan) {
        check(plan.scanManufacturerId in 0..0xffff) {
            "The background scan manufacturer ID is invalid"
        }
        check(plan.scanManufacturerData.isNotEmpty()) {
            "The background scan data must not be empty"
        }
        check(plan.scanManufacturerData.size == plan.scanManufacturerMask.size) {
            "The background scan mask has an invalid length"
        }
        check(plan.authenticationChallengeLength > 0) {
            "The authentication challenge length is invalid"
        }
        check(plan.authenticationKey.isNotEmpty()) {
            "The authentication key must not be empty"
        }
        check(plan.authenticatedState.isNotEmpty()) {
            "The authenticated state must not be empty"
        }
        MessageDigest.getInstance(plan.authenticationDigest)
    }

    private fun android.database.Cursor.uuid(index: Int): UUID =
        UUID.fromString(getString(index))

    private const val maximumAttributeValueLength = 512
}
