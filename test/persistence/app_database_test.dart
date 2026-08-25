import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:superduper/src/persistence/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the complete schema with foreign keys enabled', () async {
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
        'bike_versions',
        'bikes',
        'data_imports',
      ]),
    );
    expect(foreignKeys, 1);
  });

  test('enforces protocol-specific bike regions', () async {
    Future<void> insert({
      required String id,
      required String protocol,
      required String region,
    }) {
      return database.customStatement(
        'INSERT INTO bikes '
        '(device_id, display_name, advertised_name, protocol, region, color_key, sort_order, created_at_ms, updated_at_ms) '
        "VALUES ('$id', 'Bike', 'SUPER73', '$protocol', $region, 'dark_mode', 0, 0, 0)",
      );
    }

    await expectLater(
      insert(id: 'v1-null', protocol: 'v1', region: 'NULL'),
      throwsA(anything),
    );
    await expectLater(
      insert(id: 'v2-region', protocol: 'v2', region: "'us'"),
      throwsA(anything),
    );
    await expectLater(
      insert(id: 'unknown', protocol: 'v3', region: 'NULL'),
      throwsA(anything),
    );
    await insert(id: 'v1', protocol: 'v1', region: "'us'");
    await insert(id: 'v2', protocol: 'v2', region: 'NULL');

    expect(await database.select(database.bikes).get(), hasLength(2));
  });

  test('reset removes current and installed-version app data', () async {
    final directory = Directory(
      'scratch/database_reset_tests/${DateTime.now().microsecondsSinceEpoch}',
    );
    await directory.create(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    const removedNames = [
      appDatabaseFilename,
      '$appDatabaseFilename-wal',
      '$appDatabaseFilename-shm',
      '$appDatabaseFilename-journal',
      installedBikesFilename,
      installedSettingsFilename,
    ];
    for (final filename in [...removedNames, 'keep.txt']) {
      await File(path.join(directory.path, filename)).writeAsString('data');
    }

    await AppDatabase.resetAppData(
      documentsDirectory: () async => directory,
    );

    for (final filename in removedNames) {
      expect(File(path.join(directory.path, filename)).existsSync(), isFalse);
    }
    expect(File(path.join(directory.path, 'keep.txt')).existsSync(), isTrue);
  });
}
