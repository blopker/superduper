import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/persistence/app_database.dart';

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

  test('schema v1 bike data survives the odometer migration', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);

    final oldDatabase = GeneratedHelper().databaseForVersion(
      schema.newConnection(),
      1,
    );
    await oldDatabase.customStatement(
      "INSERT INTO bikes (device_id, display_name, advertised_name, protocol, region, color_key, sort_order, created_at_ms, updated_at_ms) VALUES ('bike', 'Commuter', 'SUPER73', 'v1', 'us', 'deep_space', 0, 1, 2)",
    );
    await oldDatabase.close();

    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 2);

    final bike = await database.select(database.bikes).getSingle();
    expect(bike.displayName, 'Commuter');
    expect(bike.odometerMeters, isNull);
    expect(bike.odometerReadAtMs, isNull);
  });
}
