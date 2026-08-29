import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/app.dart';
import 'package:superduper/src/app_services.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_identity_resolver.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/persistence/installed_data_importer.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';
import 'package:superduper/src/theme/app_theme.dart';
import 'package:superduper/src/widgets/app_design.dart';

import '../support/fake_bike_transport.dart';

void main() {
  testWidgets('ready active bike opens controls and ignores inactive', (
    tester,
  ) async {
    final fixture = await _pumpReadyBikeApp(tester, 'ready');

    expect(find.text('RIDE CONTROLS'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Light'), findsOneWidget);
    expect(find.byTooltip('Disconnect'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(fixture.connection.disconnectCalls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final configurationWrites = fixture.connection.writes.where(
      (write) => write.characteristicUuid == BikeGatt.stateRegister,
    );
    expect(configurationWrites.single.value, [0, 0xd1, 0, 2, 3, 0, 0, 0, 0, 0]);
  });

  testWidgets('bike color theme stays scoped to bike routes', (tester) async {
    await _pumpReadyBikeApp(tester, 'theme');

    expect(
      Theme.of(
        tester.element(find.text('RIDE CONTROLS')),
      ).colorScheme.primary,
      BikeColor.frostedMint.gradientColors.last,
    );
    await tester.tap(find.byTooltip('Help & tips'));
    await tester.pumpAndSettle();

    expect(find.text('HELP & TIPS'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('HELP & TIPS'))).colorScheme.primary,
      AppColors.magenta,
    );
  });

  testWidgets('Background Sync can identify an existing bike', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(defaultTargetPlatform, TargetPlatform.android);
    final fixture = await _pumpReadyBikeApp(
      tester,
      'background_identity',
      moduleSerial: null,
    );

    await tester.tap(find.byTooltip('Bike settings'));
    await tester.pumpAndSettle();
    expect(find.text('BIKE SETTINGS'), findsOneWidget);
    expect(find.text('Bike not found'), findsNothing);
    final label = find.text('Background Sync');
    await tester.ensureVisible(label);
    await tester.pump();

    final backgroundSwitch = find.ancestor(
      of: label,
      matching: find.byType(SwitchListTile),
    );
    expect(backgroundSwitch, findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(backgroundSwitch).onChanged,
      isNotNull,
    );
    expect(
      (await fixture.services.bikeRepository.getBikes())
          .single
          .bike
          .moduleSerial,
      '00112233aabbccdd',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Set on connect is configured separately from live controls', (
    tester,
  ) async {
    final fixture = await _pumpReadyBikeApp(tester, 'set_on_connect');
    final writesBeforeSettings = fixture.connection.configurationWriteStarts;

    final modeIndicator = find.byKey(
      const ValueKey('set-on-connect-indicator-mode'),
    );
    expect(modeIndicator, findsOneWidget);
    expect(
      find.descendant(of: modeIndicator, matching: find.text('4')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('set-on-connect-mode')), findsNothing);

    expect(
      find.descendant(of: modeIndicator, matching: find.byType(TextButton)),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Bike settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('BIKE SETTINGS'), findsOneWidget);

    final modeSwitch = find.byKey(const Key('set-on-connect-mode'));
    final assistSwitch = find.byKey(const Key('set-on-connect-assist'));
    expect(modeSwitch, findsOneWidget);
    expect(assistSwitch, findsOneWidget);
    expect(tester.widget<SwitchListTile>(modeSwitch).value, isTrue);
    expect(tester.widget<SwitchListTile>(assistSwitch).value, isFalse);

    await tester.tap(assistSwitch);
    await tester.pump();
    await tester.runAsync(
      () => _waitUntilAsync(
        () async =>
            (await fixture.services.bikeRepository.getBikes())
                .single
                .setOnConnect
                .assist !=
            null,
      ),
    );
    await tester.pump();

    final saved = (await fixture.services.bikeRepository.getBikes()).single;
    expect(saved.setOnConnect.assist, isNotNull);
    expect(fixture.connection.configurationWriteStarts, writesBeforeSettings);
  });

  testWidgets(
    'bike settings save automatically and confirm protocol changes',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = await _pumpReadyBikeApp(tester, 'settings');

      await tester.tap(find.byTooltip('Bike settings'));
      await tester.pumpAndSettle();
      expect(find.text('BIKE SETTINGS'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Daily Rider');
      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      await tester.runAsync(() async {
        nameField.onChanged?.call('Daily Rider');
        await _waitUntilAsync(
          () async =>
              (await fixture.services.bikeRepository.getBikes())
                  .single
                  .bike
                  .displayName ==
              'Daily Rider',
        );
      });
      await tester.pump();

      expect(
        fixture.services.activeBikeCoordinator.bikes
            .peek()
            .single
            .bike
            .displayName,
        'Daily Rider',
      );
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('V1 — SUPER73'), findsOneWidget);
      await tester.ensureVisible(find.text('V1 — SUPER73'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('V1 — SUPER73'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('V2 — S73 FTEX').last);
      await tester.pumpAndSettle();

      expect(find.text('CHANGE BIKE PROTOCOL?'), findsOneWidget);
      expect(find.text('Change protocol'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        fixture.services.activeBikeCoordinator.bikes
            .peek()
            .single
            .bike
            .protocol,
        BikeProtocolVersion.v1,
      );

      await tester.scrollUntilVisible(
        find.text('BIKE INFORMATION'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('BIKE INFORMATION'), findsOneWidget);
      expect(find.text('123.5 km · 76.7 mi'), findsOneWidget);
      expect(find.text('v3.2.0'), findsOneWidget);
      expect(find.text('00112233aabbccdd'), findsOneWidget);
      expect(find.text('221122'), findsNWidgets(2));
      expect(find.text('66051'), findsOneWidget);
      expect(find.text('305419896'), findsOneWidget);
      expect(find.text('2882400001'), findsOneWidget);
    },
  );

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
    expect(find.text('ADD BIKE'), findsOneWidget);
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
      moduleSerial: '00112233aabbccdd',
    );
    transport.readFramesOnOpen['pending-bike'] = [
      [3, 0, 0, 0, 2, 0, 0, 0, 0, 0],
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
    expect(find.text('RIDE CONTROLS'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Assist'), findsOneWidget);
    expect(find.text('Waiting for bike'), findsNothing);
  });
}

typedef _ReadyBikeFixture = ({
  AppServices services,
  FakeBikeConnection connection,
});

Future<_ReadyBikeFixture> _pumpReadyBikeApp(
  WidgetTester tester,
  String suffix, {
  String? moduleSerial = '00112233aabbccdd',
}) async {
  final database = AppDatabase(NativeDatabase.memory());
  final transport = FakeBikeTransport();
  final permissions = FakeBluetoothPermissionGateway();
  final bikeRepository = BikeRepository(database: database);
  final settingsRepository = SettingsRepository(database: database);
  final coordinator = ActiveBikeCoordinator(
    bikeRepository: bikeRepository,
    settingsRepository: settingsRepository,
    permissions: permissions,
    identityResolver: BikeIdentityResolver(
      bikeRepository: bikeRepository,
      transport: transport,
    ),
    buildSession: (bike) => BikeSession(
      connection: transport.openConnection(bike.bike.deviceId),
      preferredRegion: bike.bike.region,
      setOnConnect: bike.setOnConnect,
      protocol: bike.bike.protocol,
      confirmationRetryDelays: const [],
      onVersionsRead: (versions) async {
        await bikeRepository.saveVersions(bike.bike.deviceId, versions);
      },
      onOdometerRead: (meters) async {
        await bikeRepository.saveOdometer(bike.bike.deviceId, meters);
      },
    ),
  );
  final services = AppServices(
    database: database,
    transport: transport,
    permissions: permissions,
    bikeRepository: bikeRepository,
    settingsRepository: settingsRepository,
    activeBikeCoordinator: coordinator,
    importer: _emptyImporter(database, suffix),
  );
  addTearDown(services.dispose);
  await services.bikeRepository.addBike(
    deviceId: 'active-bike',
    displayName: 'Commuter',
    moduleSerial: moduleSerial,
    color: BikeColor.frostedMint,
  );
  if (moduleSerial == null) {
    transport.replayedScanResults = const [
      DiscoveredBike(
        deviceId: 'ACTIVE-BIKE',
        name: 'SUPER73',
        rssi: -20,
        moduleSerial: '00112233aabbccdd',
      ),
    ];
  }
  await services.bikeRepository.setOnConnect(
    'active-bike',
    const BikeControlPatch(
      mode: 3,
    ),
  );
  transport.readFramesOnOpen['active-bike'] = [
    v1StateFrame(light: true, assist: 2),
    v1StateFrame(mode: 3, assist: 2),
  ];

  await tester.runAsync(() async {
    await services.startup.initialize();
    await _waitForReady(services.activeBikeCoordinator);
  });
  await tester.pumpWidget(SuperduperApp(services: services));
  await tester.pumpAndSettle();
  return (
    services: services,
    connection: transport.connections['active-bike']!,
  );
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
    await current.session.connect();
    return;
  }
  final completer = Completer<BikeSession>();
  late final void Function() cleanup;
  cleanup = coordinator.state.subscribe((state) {
    if (!completer.isCompleted &&
        state is ActiveBikeSessionStatus &&
        state.sessionState is SessionReady) {
      completer.complete(state.session);
      cleanup();
    }
  });
  final session = await completer.future.timeout(
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
  await session.connect();
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

Future<void> _waitUntilAsync(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('The workflow did not reach its expected state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
