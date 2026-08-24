import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/persistence/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the complete first schema with foreign keys enabled', () async {
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .map((row) => row.read<String>('name'))
        .get();
    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .map((row) => row.read<int>('foreign_keys'))
        .getSingle();

    expect(
      tables,
      containsAll([
        'app_settings',
        'bike_preferences',
        'bikes',
        'data_imports',
      ]),
    );
    expect(foreignKeys, 1);
  });
}
