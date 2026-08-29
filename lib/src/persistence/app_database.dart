import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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

@DriftDatabase(
  tables: [Bikes, BikePreferences, BikeVersions, AppSettings, DataImports],
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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  int get schemaVersion => 3;
}
