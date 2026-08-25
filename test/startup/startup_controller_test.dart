import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late StartupController controller;
  late Directory documents;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    documents = Directory(
      'scratch/startup_tests/${DateTime.now().microsecondsSinceEpoch}',
    );
    await documents.create(recursive: true);
    final importer = InstalledDataImporter(
      database: database,
      documentsDirectory: () async => documents,
    );
    controller = StartupController(
      database: database,
      importer: importer,
      settingsRepository: SettingsRepository(database: database),
    );
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
    if (documents.existsSync()) {
      await documents.delete(recursive: true);
    }
  });

  test('becomes ready after opening the database', () async {
    expect(controller.state.value, isA<StartupLoading>());

    await controller.initialize();

    expect(controller.state.value, isA<StartupReady>());
  });

  test(
    'concurrent initialization callers join the same startup work',
    () async {
      final first = controller.initialize();
      final second = controller.initialize();

      expect(second, same(first));
      await first;
      expect(controller.state.value, isA<StartupReady>());
    },
  );

  test('offers recovery without changing malformed source data', () async {
    final source = File('${documents.path}/bikes.json');
    await source.writeAsString('not-json');

    await controller.initialize();

    expect(controller.state.value, isA<StartupMigrationRecovery>());
    expect(await source.readAsString(), 'not-json');
    expect(await database.select(database.dataImports).get(), isEmpty);
  });

  test('can continue after recovery without deleting the source', () async {
    final source = File('${documents.path}/bikes.json');
    await source.writeAsString('not-json');
    await controller.initialize();

    await controller.continueWithoutImport();

    expect(controller.state.value, isA<StartupReady>());
    expect(source.existsSync(), isTrue);
    final marker = await database.select(database.dataImports).getSingle();
    expect(marker.outcome, 'skipped_by_user');

    final nextLaunch = await InstalledDataImporter(
      database: database,
      documentsDirectory: () async => documents,
    ).run();
    expect(
      nextLaunch,
      isA<InstalledDataImportSuccess>()
          .having(
            (result) => result.outcome,
            'outcome',
            DataImportOutcome.skippedByUser,
          )
          .having(
            (result) => result.previouslyHandled,
            'previouslyHandled',
            isTrue,
          ),
    );
  });
}
