import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/features/hardware_test/bike_hardware_test_controller.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../../support/fake_bike_transport.dart';

void main() {
  late AppDatabase database;
  late FakeBikeTransport transport;
  late FakeBluetoothPermissionGateway permissions;
  late ActiveBikeCoordinator coordinator;
  late BikeHardwareTestController controller;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final bikes = BikeRepository(database: database);
    final settings = SettingsRepository(database: database);
    await settings.initialize();
    transport = FakeBikeTransport();
    permissions = FakeBluetoothPermissionGateway();
    coordinator = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: permissions,
      buildSession: (_) => throw StateError('No saved bike is expected.'),
    );
    await coordinator.start();
    controller = BikeHardwareTestController(
      transport: transport,
      permissions: permissions,
      activeBikeCoordinator: coordinator,
      scanDuration: const Duration(milliseconds: 100),
      notificationWait: Duration.zero,
      reconnectDelays: const [Duration.zero],
      confirmationRetryDelays: const [],
    );
  });

  tearDown(() async {
    await controller.dispose();
    await coordinator.dispose();
    await transport.dispose();
    await database.close();
  });

  test(
    'runs discovery, settings, reconnect, locked sync, and cleanup in order',
    () async {
      final connection = FakeBikeConnection(deviceId: 'bike')
        ..operationDelay = const Duration(milliseconds: 1);
      connection.readFrames.addAll([
        v1StateFrame(mode: 2, assist: 1),
        v1StateFrame(light: true, mode: 2, assist: 1),
        v1StateFrame(mode: 2, assist: 1),
        v1StateFrame(mode: 3, assist: 1),
        v1StateFrame(mode: 2, assist: 1),
        v1StateFrame(mode: 2, assist: 2),
        v1StateFrame(mode: 2, assist: 1),
        v1StateFrame(light: true, mode: 2, assist: 1),
        v1StateFrame(light: true, mode: 2, assist: 2),
        v1StateFrame(light: true, mode: 2, assist: 2),
        v1StateFrame(light: true, mode: 2, assist: 2),
        v1StateFrame(light: true, mode: 2, assist: 2),
        v1StateFrame(light: true, mode: 2, assist: 2),
        v1StateFrame(mode: 2, assist: 2),
        v1StateFrame(mode: 2, assist: 1),
      ]);
      transport.connections['bike'] = connection;

      final run = controller.start();
      await _waitForPhase(controller, BikeHardwareTestPhase.scanning);
      transport.emitResults(const [
        DiscoveredBike(
          deviceId: 'bike',
          name: 'SUPER73',
          rssi: -42,
          moduleSerial: '0102030405060708',
        ),
      ]);

      await _waitUntil(
        () => transport.connections['bike']?.notificationsEnabled ?? false,
      );
      connection.emitNotification([3, 0, 1, 0, 0, 2, 0, 0, 0, 0]);
      await _waitUntil(
        () => controller
            .createReport(
              appVersion: 'test',
              buildNumber: 'test',
              platform: 'test',
              operatingSystemVersion: 'test',
            )
            .contains('gatt.notification'),
      );
      await _waitForPhase(controller, BikeHardwareTestPhase.waitingForPowerOff);
      connection
        ..connectError = StateError('The fake bike is powered off.')
        ..emitState(BikeConnectionState.disconnected);

      await _waitForPhase(controller, BikeHardwareTestPhase.waitingForPowerOn);
      connection.connectError = null;
      await run.timeout(const Duration(seconds: 5));

      final result = controller.state.peek();
      expect(result.phase, BikeHardwareTestPhase.passed);
      expect(
        result.log.singleWhere((entry) => entry.label == 'Live notification'),
        isA<BikeHardwareTestLogEntry>()
            .having(
              (entry) => entry.status,
              'status',
              BikeHardwareTestLogStatus.passed,
            )
            .having(
              (entry) => entry.detail,
              'detail',
              'Received 1 live telemetry packet after subscribing.',
            ),
      );
      expect(
        result.log.map((entry) => entry.label),
        containsAllInOrder([
          'Bluetooth access',
          'Discovery',
          'Module serial',
          'First connection and authentication',
          'Protocol',
          'Version information',
          'Initial configuration',
          'Notification subscription',
          'Light toggle',
          'Mode toggle',
          'Assist toggle',
          'Live notification',
          'Locked-setting setup',
          'Power-off detection',
          'Reconnect and locked settings',
          'Cleanup',
        ]),
      );
      expect(
        connection.writes.where(
          (write) =>
              write.characteristicUuid == BikeGatt.authenticationResponse,
        ),
        hasLength(2),
      );
      final stateWrites = connection.writes
          .where(
            (write) => write.characteristicUuid == BikeGatt.stateRegister,
          )
          .toList();
      expect(
        stateWrites.last.value,
        [0, 0xd1, 0, 1, 2, 0, 0, 0, 0, 0],
        reason: 'cleanup must restore the exact starting configuration',
      );
      expect(connection.discoveryCalls, 2);
      expect(connection.isDisposed, isTrue);

      final report = controller.createReport(
        appVersion: '1.2.3',
        buildNumber: '45',
        platform: 'macos',
        operatingSystemVersion: 'macOS test',
        generatedAt: DateTime.utc(2026, 8, 24, 12),
      );
      expect(report, contains('SUPERDUPER BIKE TEST REPORT'));
      expect(report, contains('Generated: 2026-08-24T12:00:00.000Z'));
      expect(report, contains('Result: PASSED'));
      expect(report, contains('App: 1.2.3 (45)'));
      expect(report, contains('bike BLE identifier and module serial'));
      expect(report, contains('SUPER73 bike RSSI -42'));
      expect(report, contains('0102030405060708'));
      expect(report, contains('[PASS] Reconnect and locked settings'));
      expect(report, contains('BLE TRACE'));
      expect(report, contains('<redacted 20-byte authentication value>'));
      final authenticationResponse = BikeProtocol.authenticationResponse(
        challenge: List<int>.generate(20, (index) => index),
        key: BikeProtocol.defaultAuthenticationKey,
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
      expect(report, isNot(contains(authenticationResponse)));
    },
  );

  test('a repeated run does not select a replayed scan result', () async {
    transport.replayedScanResults = const [
      DiscoveredBike(deviceId: 'stale', name: 'SUPER73', rssi: -20),
    ];

    final run = controller.start();
    await _waitForPhase(controller, BikeHardwareTestPhase.scanning);
    await _waitUntil(() => transport.scanStarts == 1);
    await Future<void>.delayed(Duration.zero);

    expect(transport.connections, isEmpty);
    expect(controller.state.peek().phase, BikeHardwareTestPhase.scanning);

    await controller.cancel();
    await run;
    expect(controller.state.peek().phase, BikeHardwareTestPhase.cancelled);
  });

  test('cancel waits for an in-flight toggle before restoring', () async {
    final gate = Completer<void>();
    final connection = FakeBikeConnection(deviceId: 'bike')
      ..configurationWriteGate = gate;
    connection.readFrames.addAll([
      v1StateFrame(mode: 2, assist: 1),
      v1StateFrame(light: true, mode: 2, assist: 1),
      v1StateFrame(mode: 2, assist: 1),
    ]);
    transport.connections['bike'] = connection;

    final run = controller.start();
    await _waitForPhase(controller, BikeHardwareTestPhase.scanning);
    transport.emitResults(const [
      DiscoveredBike(deviceId: 'bike', name: 'SUPER73', rssi: -42),
    ]);
    await _waitUntil(() => connection.configurationWriteStarts == 1);

    final cancel = controller.cancel();
    gate.complete();
    await Future.wait([run, cancel]);

    final writes = connection.writes
        .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
        .toList();
    expect(writes, hasLength(2));
    expect(writes.last.value, [0, 0xd1, 0, 1, 2, 0, 0, 0, 0, 0]);
    expect(controller.state.peek().phase, BikeHardwareTestPhase.cancelled);
    expect(
      controller.state.peek().log.last,
      isA<BikeHardwareTestLogEntry>()
          .having(
            (entry) => entry.label,
            'label',
            'Cleanup',
          )
          .having(
            (entry) => entry.status,
            'status',
            BikeHardwareTestLogStatus.passed,
          ),
    );
  });

  test('backgrounding cannot count as a successful bike power-off', () async {
    await controller.dispose();
    controller = BikeHardwareTestController(
      transport: transport,
      permissions: permissions,
      activeBikeCoordinator: coordinator,
      scanDuration: const Duration(milliseconds: 100),
      notificationWait: Duration.zero,
      reconnectDelays: const [Duration.zero],
      confirmationRetryDelays: const [],
      cleanupTimeout: Duration.zero,
    );
    final connection = FakeBikeConnection(deviceId: 'bike');
    connection.readFrames.addAll([
      v1StateFrame(mode: 2, assist: 1),
      v1StateFrame(light: true, mode: 2, assist: 1),
      v1StateFrame(mode: 2, assist: 1),
      v1StateFrame(mode: 3, assist: 1),
      v1StateFrame(mode: 2, assist: 1),
      v1StateFrame(mode: 2, assist: 2),
      v1StateFrame(mode: 2, assist: 1),
      v1StateFrame(light: true, mode: 2, assist: 1),
      v1StateFrame(light: true, mode: 2, assist: 2),
      v1StateFrame(light: true, mode: 2, assist: 2),
      v1StateFrame(light: true, mode: 2, assist: 2),
      v1StateFrame(light: true, mode: 2, assist: 2),
      v1StateFrame(light: true, mode: 2, assist: 2),
      v1StateFrame(mode: 2, assist: 2),
      v1StateFrame(mode: 2, assist: 1),
    ]);
    transport.connections['bike'] = connection;

    final run = controller.start();
    await _waitForPhase(controller, BikeHardwareTestPhase.scanning);
    transport.emitResults(const [
      DiscoveredBike(deviceId: 'bike', name: 'SUPER73', rssi: -42),
    ]);
    await _waitForPhase(controller, BikeHardwareTestPhase.waitingForPowerOff);

    controller.setForeground(false);
    connection
      ..connectError = StateError('suspended')
      ..emitState(BikeConnectionState.disconnected);
    controller.setForeground(true);
    await run.timeout(const Duration(seconds: 5));

    expect(controller.state.peek().phase, BikeHardwareTestPhase.failed);
    expect(
      controller.state
          .peek()
          .log
          .lastWhere(
            (entry) => entry.label == 'Test stopped',
          )
          .detail,
      contains('left the foreground'),
    );
  });
}

Future<void> _waitForPhase(
  BikeHardwareTestController controller,
  BikeHardwareTestPhase phase,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (controller.state.peek().phase != phase) {
    if (!DateTime.now().isBefore(deadline)) {
      fail(
        'Expected $phase, found ${controller.state.peek().phase}: '
        '${controller.state.peek().detail}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (!DateTime.now().isBefore(deadline)) {
      fail('Timed out waiting for the test condition.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}
