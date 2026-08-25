import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';

import '../support/fake_bike_transport.dart';

void main() {
  testWidgets('starts at the bike setup workflow', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final services = AppServices(
      database: database,
      importer: InstalledDataImporter(
        database: database,
        documentsDirectory: () async =>
            Directory('scratch/widget_tests/no_installed_data'),
      ),
    );
    addTearDown(services.dispose);

    await tester.runAsync(services.startup.initialize);
    await tester.pumpWidget(SuperduperApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('ADD YOUR FIRST BIKE'), findsOneWidget);
    expect(find.text('NO SAVED BIKES'), findsOneWidget);
    expect(find.text('Add bike'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnnotatedRegion<SystemUiOverlayStyle> &&
            widget.value.statusBarBrightness == Brightness.light &&
            widget.value.statusBarIconBrightness == Brightness.dark,
      ),
      findsOneWidget,
    );
  });

  testWidgets('bootstrap can reset data when service creation throws', (
    tester,
  ) async {
    var attempts = 0;
    var resets = 0;
    AppServices? recovered;

    await tester.pumpWidget(
      SuperduperBootstrap(
        resetData: () async => resets++,
        createServices: () {
          attempts++;
          if (attempts == 1) {
            throw StateError('database failed to open');
          }
          final database = AppDatabase(NativeDatabase.memory());
          return recovered = AppServices(
            database: database,
            transport: FakeBikeTransport(),
            permissions: FakeBluetoothPermissionGateway(),
            importer: InstalledDataImporter(
              database: database,
              documentsDirectory: () async =>
                  Directory('scratch/widget_tests/bootstrap_retry'),
            ),
          );
        },
      ),
    );

    expect(
      find.text('Superduper could not open your saved bikes.'),
      findsOneWidget,
    );
    expect(find.text('Reset app data'), findsOneWidget);
    await tester.tap(find.text('Reset app data'));
    await tester.pumpAndSettle();
    expect(find.text('RESET APP DATA?'), findsOneWidget);
    expect(find.textContaining('permanently removes'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Reset app data').last,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (recovered == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await recovered!.startup.initialize();
    });
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(resets, 1);
    expect(find.text('ADD YOUR FIRST BIKE'), findsOneWidget);

    await tester.runAsync(recovered!.dispose);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('bootstrap can retry without deleting app data', (tester) async {
    var attempts = 0;
    var resets = 0;
    AppServices? recovered;

    await tester.pumpWidget(
      SuperduperBootstrap(
        resetData: () async => resets++,
        createServices: () {
          attempts++;
          if (attempts == 1) {
            throw StateError('database temporarily unavailable');
          }
          final database = AppDatabase(NativeDatabase.memory());
          return recovered = AppServices(
            database: database,
            transport: FakeBikeTransport(),
            permissions: FakeBluetoothPermissionGateway(),
            importer: InstalledDataImporter(
              database: database,
              documentsDirectory: () async =>
                  Directory('scratch/widget_tests/bootstrap_safe_retry'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (recovered == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await recovered!.startup.initialize();
    });
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(resets, 0);
    expect(find.text('ADD YOUR FIRST BIKE'), findsOneWidget);

    await tester.runAsync(recovered!.dispose);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
