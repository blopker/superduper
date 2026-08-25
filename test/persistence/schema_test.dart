import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/persistence/app_database.dart';

import '../generated/schema.dart';

void main() {
  test('release schema snapshot matches the current database', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final database = AppDatabase(schema.newConnection());
    addTearDown(database.close);

    await database.validateDatabaseSchema();
  });
}
