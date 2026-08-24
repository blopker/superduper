import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';

import '../generated/schema.dart';

void main() {
  test('schema version 6 snapshot matches the current database', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(6);
    addTearDown(schema.close);
    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);

    await database.validateDatabaseSchema();
  });

  test('migration from v1 preserves bikes and ride preferences', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    schema.rawDatabase.execute(
      'INSERT INTO bikes '
      '(device_id, display_name, region, color_key, sort_order, created_at_ms, '
      'updated_at_ms, last_connected_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'Commuter', 'eu', 'midnight_sky', 0, 10, 20, 30],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_preferences '
      '(device_id, desired_light, desired_mode, desired_assist, keep_light, '
      'keep_mode, keep_assist, background_requested, '
      'background_consent_version) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 1, 3, 4, 1, 1, 1, 0, 0],
    );
    schema.rawDatabase.execute(
      'INSERT INTO app_settings '
      '(singleton_id, active_bike_id, last_viewed_bike_id, '
      'migration_notice_pending) VALUES (?, ?, ?, ?)',
      [1, 'bike', 'bike', 0],
    );

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 6);

    final bike = await database.select(database.bikes).getSingle();
    final preferences = await database
        .select(database.bikePreferences)
        .getSingle();
    expect(bike.deviceId, 'bike');
    expect(bike.displayName, 'Commuter');
    expect(bike.advertisedName, 'SUPER73');
    expect(bike.protocol, BikeProtocolVersion.v1);
    expect(bike.moduleSerial, isNull);
    expect(preferences.desiredMode, 3);
    expect(preferences.desiredAssist, 4);
    expect(preferences.keepMode, isTrue);
    expect(await database.select(database.bikeVersions).get(), isEmpty);
  });

  test('migration from v2 preserves cached versions', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);
    addTearDown(schema.close);
    schema.rawDatabase.execute(
      'INSERT INTO bikes '
      '(device_id, display_name, region, color_key, sort_order, created_at_ms, '
      'updated_at_ms, last_connected_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'Commuter', 'us', 'midnight_sky', 0, 10, 20, 30],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_preferences '
      '(device_id, desired_light, desired_mode, desired_assist, keep_light, '
      'keep_mode, keep_assist, background_requested, '
      'background_consent_version) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 1, 2, 3, 1, 1, 1, 0, 0],
    );
    schema.rawDatabase.execute(
      'INSERT INTO app_settings '
      '(singleton_id, active_bike_id, last_viewed_bike_id, '
      'migration_notice_pending) VALUES (?, ?, ?, ?)',
      [1, 'bike', 'bike', 0],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_versions '
      '(device_id, hardware_revision, firmware_revision, software_revision, '
      'stm_firmware_version, controller_variant, bootloader_handoff, '
      'motor_controller_version, bms_version, read_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'bike',
        'v3.3.0',
        '250426',
        '250426',
        0x010203,
        407,
        8,
        0x12345678,
        0xabcdef01,
        40,
      ],
    );

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 6);

    final bike = await database.select(database.bikes).getSingle();
    final versions = await database.select(database.bikeVersions).getSingle();
    expect(bike.moduleSerial, isNull);
    expect(bike.region, isNull);
    expect(bike.advertisedName, 'S73 FTEX');
    expect(bike.protocol, BikeProtocolVersion.v2);
    expect(versions.firmwareRevision, '250426');
    expect(versions.stmFirmwareVersion, 0x010203);
    expect(versions.bmsVersion, 0xabcdef01);
  });

  test('migration from v3 clears obsolete V2 regions', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.close);
    schema.rawDatabase.execute(
      'INSERT INTO bikes '
      '(device_id, display_name, region, color_key, sort_order, created_at_ms, '
      'updated_at_ms, last_connected_at_ms, module_serial) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'V2 Bike', 'eu', 'midnight_sky', 0, 10, 20, 30, null],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_preferences '
      '(device_id, desired_light, desired_mode, desired_assist, keep_light, '
      'keep_mode, keep_assist, background_requested, '
      'background_consent_version) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 1, 2, 3, 1, 1, 1, 0, 0],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_versions '
      '(device_id, hardware_revision, firmware_revision, software_revision, '
      'stm_firmware_version, controller_variant, bootloader_handoff, '
      'motor_controller_version, bms_version, read_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'v3.3.0', '250426', '250426', 1, 2, 3, 4, 5, 40],
    );

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 6);

    final bike = await database.select(database.bikes).getSingle();
    expect(bike.region, isNull);
    expect(bike.advertisedName, 'S73 FTEX');
    expect(bike.protocol, BikeProtocolVersion.v2);
  });

  test(
    'migration from v5 derives the initial protocol from the name',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(5);
      addTearDown(schema.close);
      schema.rawDatabase.execute(
        'INSERT INTO bikes '
        '(device_id, display_name, advertised_name, region, color_key, '
        'sort_order, created_at_ms, updated_at_ms, last_connected_at_ms, '
        'module_serial) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'bike',
          'V2 Bike',
          'S73 FTEX',
          null,
          'midnight_sky',
          0,
          10,
          20,
          30,
          null,
        ],
      );

      final database = AppDatabase(schema.newConnection());
      addTearDown(database.close);
      await verifier.migrateAndValidate(database, 6);

      final bike = await database.select(database.bikes).getSingle();
      expect(bike.advertisedName, 'S73 FTEX');
      expect(bike.protocol, BikeProtocolVersion.v2);
    },
  );

  test('a failed multi-step migration rolls back its schema changes', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
      CREATE TRIGGER reject_region_migration
      BEFORE UPDATE ON bikes
      BEGIN
        SELECT RAISE(ABORT, 'simulated migration failure');
      END
    ''');
    schema.rawDatabase.execute(
      'INSERT INTO bikes '
      '(device_id, display_name, region, color_key, sort_order, created_at_ms, '
      'updated_at_ms, last_connected_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'V2 Bike', 'eu', 'midnight_sky', 0, 10, 20, 30],
    );
    schema.rawDatabase.execute(
      'INSERT INTO bike_versions '
      '(device_id, hardware_revision, firmware_revision, software_revision, '
      'stm_firmware_version, controller_variant, bootloader_handoff, '
      'motor_controller_version, bms_version, read_at_ms) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bike', 'v3.3.0', '250426', '250426', 1, 2, 3, 4, 5, 40],
    );
    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);

    await expectLater(
      verifier.migrateAndValidate(database, 6),
      throwsA(isA<Exception>()),
    );

    final columns = schema.rawDatabase
        .select('PRAGMA table_info(bikes)')
        .map((row) => row['name'])
        .toList();
    expect(columns, isNot(contains('module_serial')));
  });
}
