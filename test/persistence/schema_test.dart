import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../generated/schema.dart';

void main() {
  for (final version in GeneratedHelper.versions) {
    test('schema v$version opens as the current database', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(version);
      addTearDown(schema.close);
      final database = AppDatabase(schema.newConnection());
      addTearDown(database.close);

      await database.validateDatabaseSchema();
    });
  }

  test('schema v1 bike data survives all migrations', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);

    final oldDatabase = GeneratedHelper().databaseForVersion(
      schema.newConnection(),
      1,
    );
    final advertisedName = BikeProtocolVersion.v1.advertisedName;
    await oldDatabase.customStatement(
      "INSERT INTO bikes (device_id, display_name, advertised_name, protocol, region, color_key, sort_order, created_at_ms, updated_at_ms, module_serial) VALUES ('bike', 'Commuter', '$advertisedName', 'v1', 'us', 'deep_space', 0, 1, 2, '00112233aabbccdd')",
    );
    await oldDatabase.close();

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, database.schemaVersion);

    final bike = await database.select(database.bikes).getSingle();
    expect(bike.displayName, 'Commuter');
    expect(bike.odometerMeters, isNull);
    expect(bike.odometerReadAtMs, isNull);
  });

  test('schema v2 enabled set-on-connect values survive migration', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);
    addTearDown(schema.close);

    final oldDatabase = GeneratedHelper().databaseForVersion(
      schema.newConnection(),
      2,
    );
    final advertisedName = BikeProtocolVersion.v1.advertisedName;
    await oldDatabase.customStatement(
      "INSERT INTO bikes (device_id, display_name, advertised_name, protocol, region, color_key, sort_order, created_at_ms, updated_at_ms, module_serial) VALUES ('bike', 'Commuter', '$advertisedName', 'v1', 'us', 'deep_space', 0, 1, 2, '00112233aabbccdd')",
    );
    await oldDatabase.customStatement(
      "INSERT INTO bike_preferences (device_id, desired_light, desired_mode, desired_assist, keep_light, keep_mode, keep_assist, background_requested, background_consent_version) VALUES ('bike', 1, 3, 4, 1, 0, 1, 1, 2)",
    );
    await oldDatabase.close();

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, database.schemaVersion);

    final preferences = await database
        .select(database.bikePreferences)
        .getSingle();
    expect(
      preferences.setOnConnect,
      const BikeControlPatch(light: true, assist: 4),
    );
    expect(preferences.backgroundRequested, isTrue);
    expect(preferences.backgroundConsentVersion, 2);

    await SettingsRepository(database: database).initialize();
    expect(
      (await database.select(database.backgroundSyncCommands).getSingle())
          .payload,
      [0, 0xd1, 1, 4, 0xff, 0, 0, 0, 0, 0],
    );
  });
}
