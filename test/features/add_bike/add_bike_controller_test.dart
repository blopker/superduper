import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/features/add_bike/add_bike_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../../support/fake_bike_transport.dart';

void main() {
  late AppDatabase database;
  late BikeRepository bikes;
  late SettingsRepository settings;
  late FakeBikeTransport transport;
  late FakeBluetoothPermissionGateway permissions;
  late ActiveBikeCoordinator coordinator;
  late AddBikeController controller;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    transport = FakeBikeTransport();
    permissions = FakeBluetoothPermissionGateway();
    await settings.initialize();
    coordinator = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: permissions,
      buildSession: (bike) => BikeSession(
        connection: transport.openConnection(bike.bike.deviceId),
        preferredRegion: bike.bike.region,
        preferences: bike.preferences,
        protocol: bike.bike.protocol,
        pollInterval: null,
        reconnectDelays: const [],
      ),
    );
    await coordinator.start();
    controller = AddBikeController(
      transport: transport,
      permissions: permissions,
      bikeRepository: bikes,
      activeBikeCoordinator: coordinator,
    );
  });

  tearDown(() async {
    await controller.dispose();
    await coordinator.dispose();
    await transport.dispose();
    await database.close();
  });

  test('permission denial is explicit and scanning never starts', () async {
    permissions.state = BluetoothPermissionState.permanentlyDenied;

    await controller.start();

    expect(
      controller.state.value,
      isA<AddBikePermissionRequired>().having(
        (state) => state.permission,
        'permission',
        BluetoothPermissionState.permanentlyDenied,
      ),
    );
    expect(transport.scanStarts, 0);
  });

  test('a permission adapter failure becomes actionable state', () async {
    permissions.ensureError = StateError('platform channel unavailable');

    await controller.start();

    expect(
      controller.state.value,
      isA<AddBikeFailure>().having(
        (state) => state.message,
        'message',
        contains('Bluetooth setup could not be started'),
      ),
    );
    expect(transport.scanStarts, 0);
  });

  test('adapter off is explicit and scanning never starts', () async {
    transport.currentAdapterState = BikeAdapterState.off;

    await controller.start();

    expect(controller.state.value, isA<AddBikeAdapterUnavailable>());
    expect(transport.scanStarts, 0);
  });

  test(
    'a started scan remains in progress after the initial stream value',
    () async {
      await controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.state.value,
        isA<AddBikeScanning>().having(
          (state) => state.isScanning,
          'isScanning',
          isTrue,
        ),
      );
    },
  );

  test('discovers, verifies, confirms, and persists a bike', () async {
    transport.readFramesOnOpen['new-bike'] = [
      [0, 0, 3, 0, 1, 6],
    ];
    await controller.start();
    const candidate = DiscoveredBike(
      deviceId: 'new-bike',
      name: 'SUPER73',
      rssi: -42,
      moduleSerial: '00112233aabbccdd',
    );
    transport.emitResults(const [candidate]);
    await _waitFor(
      controller.state,
      (state) => state is AddBikeScanning && state.results.contains(candidate),
    );

    await controller.selectCandidate(candidate);
    final confirmation = controller.state.value as AddBikeConfirming;
    expect(confirmation.configuration.mode, 2);
    expect(confirmation.configuration.region, BikeRegion.eu);

    final saved = await controller.confirm(
      displayName: 'My Bike',
      region: BikeRegion.eu,
      color: BikeColor.oceanMirage,
    );

    expect(controller.state.value, isA<AddBikeCompleted>());
    expect(saved.bike.displayName, 'My Bike');
    expect(saved.bike.advertisedName, 'SUPER73');
    expect(saved.bike.protocol, BikeProtocolVersion.v1);
    expect(saved.bike.region, BikeRegion.eu);
    expect(saved.bike.moduleSerial, '00112233aabbccdd');
    expect(saved.preferences.desiredLight, isTrue);
    expect(saved.preferences.desiredMode, 2);
    expect(saved.preferences.desiredAssist, 3);
    expect(
      saved.versions?.info,
      const BikeVersionInfo(
        hardwareRevision: 'v3.2.0',
        firmwareRevision: '221122',
        softwareRevision: '221122',
        stmFirmwareVersion: 0x010203,
        controllerVariant: 0x0196,
        bootloaderHandoff: 8,
        motorControllerVersion: 0x12345678,
        bmsVersion: 0xabcdef01,
      ),
    );
    expect((await settings.get()).activeBikeId, 'new-bike');
  });

  test(
    'firmware revision is metadata and does not affect setup',
    () async {
      const candidate = DiscoveredBike(
        deviceId: 'future-bike',
        name: 'SUPER73',
        rssi: -42,
      );
      (transport.openConnection(candidate.deviceId) as FakeBikeConnection)
        ..firmwareRevision = '260101'
        ..softwareRevision = '260101'
        ..readFrames.add([0, 0, 2, 0, 1, 3]);

      await controller.start();
      await controller.selectCandidate(candidate);

      final confirmation = controller.state.value as AddBikeConfirming;
      expect(confirmation.protocol, BikeProtocolVersion.v1);
      expect(confirmation.versions?.firmwareRevision, '260101');
    },
  );

  test('V2 bikes are persisted without a region', () async {
    const candidate = DiscoveredBike(
      deviceId: 'v2-bike',
      name: 'S73 FTEX',
      rssi: -42,
    );
    (transport.openConnection(candidate.deviceId) as FakeBikeConnection)
      ..firmwareRevision = '250426'
      ..softwareRevision = '250426'
      ..readFrames.addAll(const [
        [0, 0xd0, 3, 0, 1, 0, 0, 0, 0, 0],
        [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      ]);

    await controller.start();
    await controller.selectCandidate(candidate);

    final confirmation = controller.state.value as AddBikeConfirming;
    expect(confirmation.protocol, BikeProtocolVersion.v2);

    final saved = await controller.confirm(
      displayName: 'V2 Bike',
      region: BikeRegion.eu,
      color: BikeColor.oceanMirage,
    );

    expect(saved.bike.region, isNull);
    expect(saved.bike.advertisedName, 'S73 FTEX');
    expect(saved.bike.protocol, BikeProtocolVersion.v2);
  });

  test('already saved bikes are filtered from scan results', () async {
    await bikes.addBike(deviceId: 'saved');
    await controller.start();

    transport.emitResults(const [
      DiscoveredBike(
        deviceId: 'saved',
        name: 'SUPER73',
        rssi: -20,
        moduleSerial: '00112233aabbccdd',
      ),
      DiscoveredBike(deviceId: 'new', name: 'SUPER73', rssi: -30),
    ]);
    final state = await _waitFor(
      controller.state,
      (state) => state is AddBikeScanning && state.results.isNotEmpty,
    ) as AddBikeScanning;

    expect(state.results.map((result) => result.deviceId), ['new']);
    await _waitUntil(
      () async =>
          (await bikes.getBikes()).single.bike.moduleSerial ==
          '00112233aabbccdd',
    );
  });

  test('cancel stops discovery and never creates a bike', () async {
    await controller.start();

    await controller.cancel();

    expect(controller.state.value, isA<AddBikeIdle>());
    expect(transport.scanStops, 1);
    expect(await bikes.getBikes(), isEmpty);
  });

  test('an incompatible GATT shape fails before confirmation', () async {
    const candidate = DiscoveredBike(
      deviceId: 'unsupported',
      name: 'SUPER73',
      rssi: -40,
    );
    (transport.openConnection(
      candidate.deviceId,
    ) as FakeBikeConnection).discoveryError = const BikeGattNotSupported(
      'Required service missing.',
    );
    await controller.start();

    await controller.selectCandidate(candidate);

    expect(controller.state.value, isA<AddBikeFailure>());
    expect(await bikes.getBikes(), isEmpty);
  });
}

Future<void> _waitUntil(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not reached before the test timeout.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

Future<AddBikeState> _waitFor(
  ReadonlySignal<AddBikeState> signal,
  bool Function(AddBikeState state) matches,
) {
  final current = signal.peek();
  if (matches(current)) {
    return Future.value(current);
  }
  final completer = Completer<AddBikeState>();
  late final EffectCleanup cleanup;
  cleanup = signal.subscribe((state) {
    if (!completer.isCompleted && matches(state)) {
      completer.complete(state);
      cleanup();
    }
  });
  return completer.future.timeout(const Duration(seconds: 2));
}
