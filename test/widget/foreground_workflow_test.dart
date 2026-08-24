import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

import '../support/fake_bike_transport.dart';

void main() {
  testWidgets('Home reports ready only after startup enforcement confirms', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final transport = FakeBikeTransport();
    final permissions = FakeBluetoothPermissionGateway();
    final services = AppServices(
      database: database,
      transport: transport,
      permissions: permissions,
      importer: _emptyImporter(database, 'ready'),
    );
    addTearDown(services.dispose);
    await services.bikeRepository.addBike(
      deviceId: 'active-bike',
      displayName: 'Commuter',
    );
    await services.bikeRepository.setModeLock(
      'active-bike',
      enabled: true,
      confirmedValue: 3,
    );
    transport.readFramesOnOpen['active-bike'] = [
      [0, 0, 2, 0, 1, 0],
      [0, 0, 2, 0, 1, 3],
    ];

    await tester.runAsync(() async {
      await services.startup.initialize();
      await _waitForReady(services.activeBikeCoordinator);
    });
    await tester.pumpWidget(SuperduperApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Ready to ride'), findsOneWidget);
    expect(find.textContaining('Commuter'), findsWidgets);
    final configurationWrites = transport.connections['active-bike']!.writes
        .where((write) => write.characteristicUuid == BikeGatt.stateRegister);
    expect(configurationWrites.single.value, [0, 0xd1, 1, 2, 3, 0, 0, 0, 0, 0]);

    await tester.tap(find.text('Open controls'));
    await tester.pumpAndSettle();
    expect(find.text('Ride controls'), findsOneWidget);
    expect(find.text('Set up your ride'), findsOneWidget);
    expect(find.text('Keep on connect'), findsWidgets);
  });

  testWidgets('Add Bike explains a blocked Bluetooth permission', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final transport = FakeBikeTransport();
    final permissions = FakeBluetoothPermissionGateway();
    final services = AppServices(
      database: database,
      transport: transport,
      permissions: permissions,
      importer: _emptyImporter(database, 'add'),
    );
    addTearDown(services.dispose);
    permissions.state = BluetoothPermissionState.permanentlyDenied;
    await tester.runAsync(services.startup.initialize);
    await tester.pumpWidget(SuperduperApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bike'));
    await tester.pump();
    await tester.runAsync(() => _waitUntil(() => permissions.requests == 1));
    await tester.pump();
    expect(find.text('Bluetooth permission needed'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(transport.scanStarts, 0);
  });

  testWidgets('Ride controls render before bike settings are available', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final transport = FakeBikeTransport();
    final services = AppServices(
      database: database,
      transport: transport,
      permissions: FakeBluetoothPermissionGateway(),
      importer: _emptyImporter(database, 'pending_controls'),
    );
    addTearDown(services.dispose);
    await services.bikeRepository.addBike(
      deviceId: 'pending-bike',
      displayName: 'Pending Bike',
    );
    transport.readFramesOnOpen['pending-bike'] = [
      [1],
    ];

    await tester.runAsync(() async {
      await services.startup.initialize();
      await _waitUntil(() {
        final state = services.activeBikeCoordinator.state.peek();
        return state is ActiveBikeSessionStatus &&
            state.sessionState is SessionFailed;
      });
    });
    await tester.pumpWidget(SuperduperApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open controls'));
    await tester.pumpAndSettle();
    expect(find.text('Ride controls'), findsOneWidget);
    expect(find.text('Waiting for bike'), findsWidgets);
  });
}

InstalledDataImporter _emptyImporter(AppDatabase database, String suffix) {
  return InstalledDataImporter(
    database: database,
    documentsDirectory: () async =>
        Directory('scratch/widget_tests/foreground_$suffix'),
  );
}

Future<void> _waitForReady(ActiveBikeCoordinator coordinator) async {
  final current = coordinator.state.peek();
  if (current is ActiveBikeSessionStatus &&
      current.sessionState is SessionReady) {
    return;
  }
  final completer = Completer<void>();
  late final void Function() cleanup;
  cleanup = coordinator.state.subscribe((state) {
    if (!completer.isCompleted &&
        state is ActiveBikeSessionStatus &&
        state.sessionState is SessionReady) {
      completer.complete();
      cleanup();
    }
  });
  await completer.future.timeout(
    const Duration(seconds: 2),
    onTimeout: () {
      final state = coordinator.state.peek();
      final sessionState = state is ActiveBikeSessionStatus
          ? state.sessionState.runtimeType
          : null;
      throw TimeoutException(
        'Ready was not reached: ${state.runtimeType}, session: $sessionState, bikes: ${coordinator.bikes.peek().length}.',
      );
    },
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('The workflow did not reach its expected state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
