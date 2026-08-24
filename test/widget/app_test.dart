import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/features/startup/startup_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';

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
    expect(services.startup.state.value, isA<StartupReady>());
    expect(services.activeBikeCoordinator.state.value, isA<NoActiveBike>());
    await tester.pumpWidget(SuperduperApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Add your first bike'), findsOneWidget);
    expect(find.text('No saved bikes'), findsOneWidget);
    expect(find.text('Add bike'), findsOneWidget);
  });
}
