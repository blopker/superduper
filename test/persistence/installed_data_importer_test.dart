import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late Directory documents;
  late InstalledDataImporter importer;
  var directorySequence = 0;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    documents = Directory(
      path.join(
        Directory.current.path,
        'scratch',
        'importer_tests',
        '${DateTime.now().microsecondsSinceEpoch}_${directorySequence++}',
      ),
    );
    await documents.create(recursive: true);
    importer = InstalledDataImporter(
      database: database,
      documentsDirectory: () async => documents,
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
  });

  tearDown(() async {
    await database.close();
    if (documents.existsSync()) {
      await documents.delete(recursive: true);
    }
  });

  test('a fresh install records that no legacy source exists', () async {
    final result = await importer.run() as InstalledDataImportSuccess;

    expect(result.outcome, DataImportOutcome.noSource);
    expect(result.bikesImported, 0);
    final marker = await database.select(database.dataImports).getSingle();
    expect(marker.importKey, installedJsonImportKey);
    expect(marker.outcome, 'no_source');
  });

  test('an intentionally empty bike list completes successfully', () async {
    await _writeJson(documents, 'bikes.json', []);

    final result = await importer.run() as InstalledDataImportSuccess;

    expect(result.outcome, DataImportOutcome.completed);
    expect(result.bikesImported, 0);
    expect(await database.select(database.bikes).get(), isEmpty);
  });

  test('imports the sanitized installed-version fixture', () async {
    final fixtureDirectory = Directory(
      path.join(
        Directory.current.path,
        'test',
        'fixtures',
        'installed_data',
        'v0_7_8',
      ),
    );
    await File(path.join(fixtureDirectory.path, 'bikes.json'))
        .copy(path.join(documents.path, 'bikes.json'));
    await File(path.join(fixtureDirectory.path, 'settings.json'))
        .copy(path.join(documents.path, 'settings.json'));

    final result = await importer.run() as InstalledDataImportSuccess;
    final bikes = await BikeRepository(database: database).getBikes();
    final settings = await SettingsRepository(database: database).get();

    expect(result.bikesImported, 2);
    expect(bikes.first.bike.deviceId, 'sanitized-bike-01');
    expect(bikes.first.bike.region, BikeRegion.us);
    expect(bikes.last.bike.region, BikeRegion.eu);
    expect(settings.activeBikeId, 'sanitized-bike-01');
    expect(settings.lastViewedBikeId, 'sanitized-bike-02');
  });

  test(
    'imports legacy values, flags, regions, ordering, and last viewed',
    () async {
      final bikesSource = [
        _bike(
          'first',
          name: 'First Bike',
          region: 200,
          light: true,
          mode: 3,
          assist: 4,
          color: 31,
          lightLocked: true,
          modeLocked: true,
          assistLocked: true,
          modeLock: true,
        ),
        _bike('second', region: 'EU', color: 1),
      ];
      await _writeJson(documents, 'bikes.json', bikesSource);
      await _writeJson(documents, 'settings.json', {'currentBike': 'second'});

      final result = await importer.run() as InstalledDataImportSuccess;
      final repository = BikeRepository(database: database);
      final bikes = await repository.getBikes();
      final settings = await SettingsRepository(database: database).get();

      expect(result.bikesImported, 2);
      expect(bikes.map((saved) => saved.bike.deviceId), ['first', 'second']);
      expect(bikes.first.bike.region, BikeRegion.us);
      expect(bikes.first.bike.color, BikeColor.midnightSky);
      expect(bikes.first.setOnConnect.light, isTrue);
      expect(bikes.first.setOnConnect.mode, 3);
      expect(bikes.first.setOnConnect.assist, 4);
      expect(bikes.first.backgroundPreference.requested, isTrue);
      expect(bikes.first.backgroundPreference.consentVersion, 0);
      expect(bikes.last.bike.region, BikeRegion.eu);
      expect(settings.activeBikeId, 'first');
      expect(settings.lastViewedBikeId, 'second');
    },
  );

  test('maps every frozen legacy color index to its persistence key', () async {
    await _writeJson(documents, 'bikes.json', [
      for (var index = 0; index < 32; index++)
        _bike('bike-$index', color: index),
    ]);

    await importer.run();

    final rows = await (database.select(
      database.bikes,
    )..orderBy([(table) => OrderingTerm.asc(table.sortOrder)])).get();
    expect(
      rows.map((row) => row.colorKey),
      BikeColor.values.map((color) => color.key),
    );
  });

  test('uses safe defaults without clamping invalid required values', () async {
    await _writeJson(documents, 'bikes.json', [
      _bike('valid')
        ..remove('name')
        ..remove('color'),
      _bike('bad-mode', mode: 4),
      _bike('bad-assist', assist: -1),
      _bike('bad-light')..['light'] = 1,
    ]);

    final result = await importer.run() as InstalledDataImportSuccess;
    final bikes = await BikeRepository(database: database).getBikes();

    expect(result.bikesImported, 1);
    expect(bikes.single.bike.displayName, isNotEmpty);
    expect(bikes.single.bike.color, BikeColor.royalHorizon);
    expect(
      result.warnings.where((warning) => warning.code == 'invalid_bike'),
      hasLength(3),
    );
  });

  test(
    'the last valid duplicate wins but keeps its first list position',
    () async {
      await _writeJson(documents, 'bikes.json', [
        _bike('duplicate', name: 'Old'),
        _bike('other', name: 'Other'),
        _bike('duplicate', name: 'New', mode: 3, modeLocked: true),
      ]);

      final result = await importer.run() as InstalledDataImportSuccess;
      final bikes = await BikeRepository(database: database).getBikes();

      expect(bikes.map((saved) => saved.bike.deviceId), ['duplicate', 'other']);
      expect(bikes.first.bike.displayName, 'New');
      expect(bikes.first.bike.sortOrder, 0);
      expect(bikes.first.setOnConnect.mode, 3);
      expect(
        result.warnings.any((warning) => warning.code == 'duplicate_bike'),
        isTrue,
      );
    },
  );

  test('malformed or wholly invalid bike sources require recovery', () async {
    await File(path.join(documents.path, 'bikes.json')).writeAsString('{oops');

    final malformed = await importer.run();
    expect(
      malformed,
      isA<InstalledDataImportRecovery>().having(
        (result) => result.reason,
        'reason',
        ImportRecoveryReason.malformedBikes,
      ),
    );
    expect(await database.select(database.dataImports).get(), isEmpty);

    await _writeJson(documents, 'bikes.json', [
      {'id': 'incomplete'},
    ]);
    final invalid = await importer.run();
    expect(
      invalid,
      isA<InstalledDataImportRecovery>().having(
        (result) => result.reason,
        'reason',
        ImportRecoveryReason.noValidBikes,
      ),
    );
    expect(await database.select(database.bikes).get(), isEmpty);
    expect(await database.select(database.dataImports).get(), isEmpty);
  });

  test('existing V2 data and its valid active bike always win', () async {
    final repository = BikeRepository(database: database);
    await SettingsRepository(database: database).initialize();
    await repository.addBike(deviceId: 'existing', displayName: 'V2 Name');
    await _writeJson(documents, 'bikes.json', [
      _bike('existing', name: 'Legacy Name'),
      _bike('imported'),
    ]);

    final result = await importer.run() as InstalledDataImportSuccess;
    final bikes = await repository.getBikes();

    expect(result.bikesImported, 1);
    expect(
      bikes
          .singleWhere((saved) => saved.bike.deviceId == 'existing')
          .bike
          .displayName,
      'V2 Name',
    );
    expect(
      (await SettingsRepository(database: database).get()).activeBikeId,
      'existing',
    );
  });

  test(
    'a failed transaction rolls back every row and can be retried',
    () async {
      await _writeJson(documents, 'bikes.json', [
        _bike('first'),
        _bike('second'),
      ]);
      final observed = <List<String>>[];
      final initialEmission = Completer<void>();
      final committedEmission = Completer<void>();
      final subscription = BikeRepository(database: database)
          .watchBikes()
          .listen((bikes) {
            observed.add(bikes.map((saved) => saved.bike.deviceId).toList());
            if (!initialEmission.isCompleted) {
              initialEmission.complete();
            }
            if (bikes.isNotEmpty && !committedEmission.isCompleted) {
              committedEmission.complete();
            }
          });
      await initialEmission.future;
      await database.customStatement('''
      CREATE TRIGGER reject_import
      BEFORE INSERT ON data_imports
      BEGIN
        SELECT RAISE(ABORT, 'simulated failure');
      END
    ''');

      await expectLater(importer.run(), throwsA(isA<Exception>()));
      expect(await database.select(database.bikes).get(), isEmpty);
      expect(await database.select(database.bikePreferences).get(), isEmpty);
      expect(await database.select(database.dataImports).get(), isEmpty);

      await database.customStatement('DROP TRIGGER reject_import');
      final retry = await importer.run() as InstalledDataImportSuccess;
      await committedEmission.future;
      await subscription.cancel();

      expect(retry.bikesImported, 2);
      expect(
        observed,
        everyElement(anyOf(isEmpty, equals(['first', 'second']))),
      );
    },
  );

  test(
    'completed imports are idempotent and never mutate source JSON',
    () async {
      final source = jsonEncode([_bike('bike', name: 'Original')]);
      final sourceFile = File(path.join(documents.path, 'bikes.json'));
      await sourceFile.writeAsString(source);

      await importer.run();
      expect(await sourceFile.readAsString(), source);

      final changedSource = jsonEncode([_bike('other')]);
      await sourceFile.writeAsString(changedSource);
      final repeated = await importer.run() as InstalledDataImportSuccess;

      expect(repeated.previouslyHandled, isTrue);
      expect(
        (await database.select(database.bikes).get()).single.deviceId,
        'bike',
      );
      expect(await sourceFile.readAsString(), changedSource);
      expect(sourceFile.existsSync(), isTrue);
    },
  );

  test('a skipped recovery remains explicitly retryable', () async {
    await File(path.join(documents.path, 'bikes.json')).writeAsString('bad');
    expect(await importer.run(), isA<InstalledDataImportRecovery>());

    final skipped = await importer.continueWithoutImport();
    expect(skipped.outcome, DataImportOutcome.skippedByUser);
    expect(skipped.previouslyHandled, isFalse);
    final handled = await importer.run() as InstalledDataImportSuccess;
    expect(handled.outcome, DataImportOutcome.skippedByUser);
    expect(handled.previouslyHandled, isTrue);

    await _writeJson(documents, 'bikes.json', [_bike('recovered')]);
    final retried = await importer.retry() as InstalledDataImportSuccess;
    expect(retried.outcome, DataImportOutcome.completed);
    expect(retried.bikesImported, 1);
  });

  test('malformed settings warn but do not block valid bikes', () async {
    await _writeJson(documents, 'bikes.json', [_bike('bike')]);
    await File(path.join(documents.path, 'settings.json')).writeAsString('bad');

    final result = await importer.run() as InstalledDataImportSuccess;

    expect(result.bikesImported, 1);
    expect(
      result.warnings.map((warning) => warning.code),
      contains('malformed_settings'),
    );
    final settings = await database.select(database.appSettings).getSingle();
    expect(settings.migrationNoticePending, isTrue);
  });
}

Map<String, Object?> _bike(
  String id, {
  String name = 'Bike',
  Object? region,
  bool light = false,
  int mode = 0,
  int assist = 0,
  int color = 0,
  bool lightLocked = false,
  bool modeLocked = false,
  bool assistLocked = false,
  bool modeLock = false,
}) {
  return {
    'id': id,
    'name': name,
    'region': region,
    'light': light,
    'mode': mode,
    'assist': assist,
    'color': color,
    'lightLocked': lightLocked,
    'modeLocked': modeLocked,
    'assistLocked': assistLocked,
    'modeLock': modeLock,
  };
}

Future<void> _writeJson(Directory directory, String name, Object? value) {
  return File(path.join(directory.path, name)).writeAsString(jsonEncode(value));
}
