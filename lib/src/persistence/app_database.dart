import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/domain/bike.dart';

part 'app_database.g.dart';

const appDatabaseFilename = 'superduper.sqlite';
const installedBikesFilename = 'bikes.json';
const installedSettingsFilename = 'settings.json';

final class BikeControlPatchConverter
    extends TypeConverter<BikeControlPatch, String> {
  const BikeControlPatchConverter();

  @override
  BikeControlPatch fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Set-on-connect settings must be an object.');
    }
    return BikeControlPatch(
      light: _optionalBool(decoded, 'light'),
      mode: _optionalInt(decoded, 'mode'),
      assist: _optionalInt(decoded, 'assist'),
    );
  }

  @override
  String toSql(BikeControlPatch value) {
    return jsonEncode({
      'light': ?value.light,
      'mode': ?value.mode,
      'assist': ?value.assist,
    });
  }

  static bool? _optionalBool(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value == null || value is bool) {
      return value as bool?;
    }
    throw FormatException('Set-on-connect $key must be a boolean.');
  }

  static int? _optionalInt(Map<String, dynamic> object, String key) {
    final value = object[key];
    if (value == null || value is int) {
      return value as int?;
    }
    throw FormatException('Set-on-connect $key must be an integer.');
  }
}

@DataClassName('BikeRow')
class Bikes extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get advertisedName => text()();
  TextColumn get protocol => textEnum<BikeProtocolVersion>()();
  TextColumn get region => text().nullable()();
  TextColumn get colorKey => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get lastConnectedAtMs => integer().nullable()();
  TextColumn get moduleSerial => text().nullable()();
  IntColumn get odometerMeters => integer().nullable()();
  IntColumn get odometerReadAtMs => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(device_id) > 0)',
    'CHECK (length(display_name) > 0)',
    'CHECK (length(advertised_name) > 0)',
    "CHECK (protocol IN ('v1', 'v2'))",
    "CHECK ((protocol = 'v1' AND region IS NOT NULL AND region IN ('us', 'eu')) OR (protocol = 'v2' AND region IS NULL))",
    'CHECK (length(color_key) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

@DataClassName('BikePreferenceRow')
class BikePreferences extends Table {
  TextColumn get deviceId =>
      text().references(Bikes, #deviceId, onDelete: KeyAction.cascade)();
  TextColumn get setOnConnect =>
      text().map(const BikeControlPatchConverter())();
  BoolColumn get backgroundRequested => boolean()();
  IntColumn get backgroundConsentVersion => integer()();

  @override
  List<String> get customConstraints => [
    'CHECK (background_consent_version >= 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

@DataClassName('BikeVersionRow')
class BikeVersions extends Table {
  TextColumn get deviceId =>
      text().references(Bikes, #deviceId, onDelete: KeyAction.cascade)();
  TextColumn get hardwareRevision => text()();
  TextColumn get firmwareRevision => text()();
  TextColumn get softwareRevision => text()();
  IntColumn get stmFirmwareVersion => integer()();
  IntColumn get controllerVariant => integer()();
  IntColumn get bootloaderHandoff => integer()();
  IntColumn get motorControllerVersion => integer()();
  IntColumn get bmsVersion => integer()();
  IntColumn get readAtMs => integer()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(hardware_revision) > 0)',
    'CHECK (length(firmware_revision) > 0)',
    'CHECK (length(software_revision) > 0)',
    'CHECK (stm_firmware_version BETWEEN 0 AND 16777215)',
    'CHECK (controller_variant BETWEEN 0 AND 65535)',
    'CHECK (bootloader_handoff BETWEEN 0 AND 255)',
    'CHECK (motor_controller_version BETWEEN 0 AND 4294967295)',
    'CHECK (bms_version BETWEEN 0 AND 4294967295)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  IntColumn get singletonId => integer()();

  @ReferenceName('activeBikeSettings')
  TextColumn get activeBikeId => text().nullable().references(
    Bikes,
    #deviceId,
    onDelete: KeyAction.setNull,
  )();

  @ReferenceName('lastViewedBikeSettings')
  TextColumn get lastViewedBikeId => text().nullable().references(
    Bikes,
    #deviceId,
    onDelete: KeyAction.setNull,
  )();
  BoolColumn get migrationNoticePending => boolean()();

  @override
  List<String> get customConstraints => ['CHECK (singleton_id = 1)'];

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

@DataClassName('DataImportRow')
class DataImports extends Table {
  TextColumn get importKey => text()();
  TextColumn get outcome => text()();
  IntColumn get completedAtMs => integer()();
  IntColumn get bikesImported => integer()();
  TextColumn get warningsJson => text()();

  @override
  List<String> get customConstraints => [
    "CHECK (outcome IN ('completed', 'no_source', 'skipped_by_user'))",
    'CHECK (bikes_imported >= 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {importKey};
}

@DataClassName('BackgroundSyncPlanRow')
class BackgroundSyncPlans extends Table {
  IntColumn get singletonId => integer()();
  IntColumn get planVersion => integer()();
  TextColumn get deviceId =>
      text().references(Bikes, #deviceId, onDelete: KeyAction.cascade)();
  IntColumn get scanManufacturerId => integer()();
  BlobColumn get scanManufacturerData => blob()();
  BlobColumn get scanManufacturerMask => blob()();
  TextColumn get authenticationServiceUuid => text()();
  TextColumn get authenticationChallengeUuid => text()();
  TextColumn get authenticationResponseUuid => text()();
  TextColumn get authenticationStateUuid => text()();
  IntColumn get authenticationChallengeLength => integer()();
  TextColumn get authenticationDigest => text()();
  BlobColumn get authenticationKey => blob()();
  BlobColumn get authenticatedState => blob()();
  TextColumn get commandServiceUuid => text()();
  TextColumn get commandCharacteristicUuid => text()();

  @override
  List<String> get customConstraints => [
    'CHECK (singleton_id = 1)',
    'CHECK (plan_version = 2)',
    'CHECK (scan_manufacturer_id BETWEEN 0 AND 65535)',
    'CHECK (length(scan_manufacturer_data) > 0)',
    'CHECK (length(scan_manufacturer_mask) = length(scan_manufacturer_data))',
    'CHECK (length(authentication_service_uuid) > 0)',
    'CHECK (length(authentication_challenge_uuid) > 0)',
    'CHECK (length(authentication_response_uuid) > 0)',
    'CHECK (length(authentication_state_uuid) > 0)',
    'CHECK (authentication_challenge_length > 0)',
    'CHECK (length(authentication_digest) > 0)',
    'CHECK (length(authentication_key) > 0)',
    'CHECK (length(authenticated_state) > 0)',
    'CHECK (length(command_service_uuid) > 0)',
    'CHECK (length(command_characteristic_uuid) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

@DataClassName('BackgroundSyncCommandRow')
class BackgroundSyncCommands extends Table {
  IntColumn get planSingletonId => integer().references(
    BackgroundSyncPlans,
    #singletonId,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get sequence => integer()();
  BlobColumn get payload => blob()();

  @override
  List<String> get customConstraints => [
    'CHECK (plan_singleton_id = 1)',
    'CHECK (sequence >= 0)',
    'CHECK (length(payload) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {planSingletonId, sequence};
}

@DriftDatabase(
  tables: [
    Bikes,
    BikePreferences,
    BikeVersions,
    AppSettings,
    DataImports,
    BackgroundSyncPlans,
    BackgroundSyncCommands,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open() {
    return AppDatabase(
      LazyDatabase(() async {
        final documents = await getApplicationDocumentsDirectory();
        final file = File(path.join(documents.path, appDatabaseFilename));
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  static Future<void> resetAppData({
    Future<Directory> Function()? documentsDirectory,
  }) async {
    final documents =
        await (documentsDirectory ?? getApplicationDocumentsDirectory)();
    const filenames = [
      appDatabaseFilename,
      '$appDatabaseFilename-wal',
      '$appDatabaseFilename-shm',
      '$appDatabaseFilename-journal',
      installedBikesFilename,
      installedSettingsFilename,
    ];
    for (final filename in filenames) {
      final file = File(path.join(documents.path, filename));
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await transaction(() async {
          await migrator.addColumn(bikes, bikes.odometerMeters);
          await migrator.addColumn(bikes, bikes.odometerReadAtMs);
        });
      }
      if (from < 3) {
        await migrator.alterTable(
          TableMigration(
            bikePreferences,
            newColumns: [bikePreferences.setOnConnect],
            columnTransformer: {
              bikePreferences.setOnConnect: const CustomExpression<String>(
                "'{' || "
                "'\"light\":' || CASE WHEN keep_light = 1 AND desired_light = 1 THEN 'true' ELSE 'null' END || ',' || "
                "'\"mode\":' || CASE WHEN keep_mode = 1 THEN CAST(desired_mode AS TEXT) ELSE 'null' END || ',' || "
                "'\"assist\":' || CASE WHEN keep_assist = 1 THEN CAST(desired_assist AS TEXT) ELSE 'null' END || '}'",
              ),
            },
          ),
        );
      }
      if (from < 4) {
        await migrator.createTable(backgroundSyncPlans);
        await migrator.createTable(backgroundSyncCommands);
      } else if (from < 5) {
        await migrator.deleteTable('background_sync_commands');
        await migrator.deleteTable('background_sync_plans');
        await migrator.createTable(backgroundSyncPlans);
        await migrator.createTable(backgroundSyncCommands);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  int get schemaVersion => 5;

  Future<void> refreshBackgroundSyncPlan() {
    return transaction(() async {
      await delete(backgroundSyncCommands).go();
      await delete(backgroundSyncPlans).go();

      final settings = await (select(
        appSettings,
      )..where((table) => table.singletonId.equals(1))).getSingleOrNull();
      final activeBikeId = settings?.activeBikeId;
      if (activeBikeId == null) {
        return;
      }

      final query = select(bikes).join([
        innerJoin(
          bikePreferences,
          bikePreferences.deviceId.equalsExp(bikes.deviceId),
        ),
      ])..where(bikes.deviceId.equals(activeBikeId));
      final row = await query.getSingleOrNull();
      if (row == null) {
        return;
      }
      final bike = row.readTable(bikes);
      final preferences = row.readTable(bikePreferences);
      final moduleSerial = bike.moduleSerial;
      if (!preferences.backgroundRequested ||
          preferences.backgroundConsentVersion < backgroundSyncConsentVersion ||
          preferences.setOnConnect.isEmpty ||
          moduleSerial == null) {
        return;
      }
      final serialBytes = _decodeModuleSerial(moduleSerial);
      if (serialBytes == null) {
        return;
      }

      await into(backgroundSyncPlans).insert(
        BackgroundSyncPlansCompanion.insert(
          singletonId: const Value(1),
          planVersion: 2,
          deviceId: bike.deviceId,
          scanManufacturerId: BikeGatt.manufacturerId,
          scanManufacturerData: serialBytes,
          scanManufacturerMask: Uint8List(serialBytes.length)..fillRange(
            0,
            serialBytes.length,
            0xff,
          ),
          authenticationServiceUuid: BikeGatt.authenticationService,
          authenticationChallengeUuid: BikeGatt.authenticationChallenge,
          authenticationResponseUuid: BikeGatt.authenticationResponse,
          authenticationStateUuid: BikeGatt.authenticationState,
          authenticationChallengeLength:
              BikeProtocol.defaultAuthenticationKey.length,
          authenticationDigest: 'SHA-1',
          authenticationKey: Uint8List.fromList(
            BikeProtocol.defaultAuthenticationKey,
          ),
          authenticatedState: Uint8List.fromList(const [1]),
          commandServiceUuid: BikeGatt.metricsService,
          commandCharacteristicUuid: BikeGatt.stateRegister,
        ),
      );
      await into(backgroundSyncCommands).insert(
        BackgroundSyncCommandsCompanion.insert(
          planSingletonId: 1,
          sequence: 0,
          payload: Uint8List.fromList(
            _backgroundControlFrame(bike, preferences),
          ),
        ),
      );
    });
  }

  Uint8List? _decodeModuleSerial(String serial) {
    if (!RegExp(r'^[0-9a-fA-F]{16}$').hasMatch(serial)) {
      return null;
    }
    return Uint8List.fromList([
      for (var offset = 0; offset < serial.length; offset += 2)
        int.parse(serial.substring(offset, offset + 2), radix: 16),
    ]);
  }

  List<int> _backgroundControlFrame(
    BikeRow bike,
    BikePreferenceRow preferences,
  ) {
    final patch = preferences.setOnConnect;
    final mode = switch ((bike.protocol, patch.mode)) {
      (_, null) => 0xff,
      (BikeProtocolVersion.v1, final mode?) =>
        mode +
            (bike.region == BikeRegion.eu.name
                ? BikeControlValues.modeCount
                : 0),
      (BikeProtocolVersion.v2, final mode?) => mode,
    };
    return [
      0,
      switch (bike.protocol) {
        BikeProtocolVersion.v1 => 0xd1,
        BikeProtocolVersion.v2 => 0xc1,
      },
      switch (patch.light) {
        true => 1,
        false => 0,
        null => 0xff,
      },
      patch.assist ?? 0xff,
      mode,
      0,
      0,
      0,
      0,
      0,
    ];
  }
}
