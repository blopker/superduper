import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('BikeRow')
class Bikes extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get region => text().nullable()();
  TextColumn get colorKey => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get lastConnectedAtMs => integer().nullable()();
  TextColumn get moduleSerial => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(device_id) > 0)',
    'CHECK (length(display_name) > 0)',
    "CHECK (region IS NULL OR region IN ('us', 'eu'))",
    'CHECK (length(color_key) > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

@DataClassName('BikePreferenceRow')
class BikePreferences extends Table {
  TextColumn get deviceId =>
      text().references(Bikes, #deviceId, onDelete: KeyAction.cascade)();
  BoolColumn get desiredLight => boolean()();
  IntColumn get desiredMode => integer()();
  IntColumn get desiredAssist => integer()();
  BoolColumn get keepLight => boolean()();
  BoolColumn get keepMode => boolean()();
  BoolColumn get keepAssist => boolean()();
  BoolColumn get backgroundRequested => boolean()();
  IntColumn get backgroundConsentVersion => integer()();

  @override
  List<String> get customConstraints => [
    'CHECK (desired_mode BETWEEN 0 AND 3)',
    'CHECK (desired_assist BETWEEN 0 AND 4)',
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
  AppDatabase(super.executor);

  factory AppDatabase.open() {
    return AppDatabase(
      LazyDatabase(() async {
        final documents = await getApplicationDocumentsDirectory();
        final file = File(path.join(documents.path, 'superduper.sqlite'));
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(bikeVersions);
      }
      if (from < 3) {
        await migrator.addColumn(bikes, bikes.moduleSerial);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  @override
  int get schemaVersion => 3;
}
