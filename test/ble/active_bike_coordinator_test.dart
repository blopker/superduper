import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/persistence/app_database.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/repositories/bike_repository.dart';
import 'package:superduper/src/repositories/settings_repository.dart';

import '../support/fake_bike_transport.dart';

void main() {
  late AppDatabase database;
  late BikeRepository bikes;
  late SettingsRepository settings;
  late FakeBluetoothPermissionGateway permissions;
  late ActiveBikeCoordinator coordinator;
  late Map<String, List<FakeBikeConnection>> connections;
  late Map<String, List<List<int>>> connectionFrames;
  late bool throwWhenBuildingSession;
  late bool databaseClosed;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    permissions = FakeBluetoothPermissionGateway();
    connections = {};
    connectionFrames = {};
    throwWhenBuildingSession = false;
    databaseClosed = false;
    await settings.initialize();
    await bikes.addBike(deviceId: 'first', displayName: 'First');
    await bikes.addBike(deviceId: 'second', displayName: 'Second');
    coordinator = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: permissions,
      buildSession: (bike) {
        if (throwWhenBuildingSession) {
          throw StateError('session factory unavailable');
        }
        final connection = FakeBikeConnection(deviceId: bike.bike.deviceId)
          ..readFrames.addAll(
            connectionFrames[bike.bike.deviceId]?.map(List<int>.from) ??
                const [
                  [0, 0, 0, 0, 0, 0],
                ],
          );
        connections.putIfAbsent(bike.bike.deviceId, () => []).add(connection);
        return BikeSession(
          connection: connection,
          preferredRegion: bike.bike.region,
          preferences: bike.preferences,
          protocol: bike.bike.protocol,
          pollInterval: null,
          reconnectDelays: const [],
        );
      },
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    if (!databaseClosed) {
      await database.close();
    }
  });

  test('automatically connects the persisted active bike at startup', () async {
    await coordinator.start();

    final state = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;

    expect(state.bike.bike.deviceId, 'first');
    expect(state.isTemporary, isFalse);
    expect(connections['first']?.single.connectCalls, 1);
    expect(permissions.requests, 1);
  });

  test('startup applies every kept value before reporting ready', () async {
    await bikes.setLightLock('first', enabled: true, confirmedValue: true);
    await bikes.setModeLock('first', enabled: true, confirmedValue: 3);
    await bikes.setAssistLock('first', enabled: true, confirmedValue: 4);
    connectionFrames['first'] = [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 4, 0, 1, 3],
    ];

    await coordinator.start();
    final ready = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;

    final state = ready.sessionState as SessionReady;
    expect(state.configuration.light, isTrue);
    expect(state.configuration.mode, 3);
    expect(state.configuration.assist, 4);
    final writes = connections['first']!.single.writes.where(
      (write) => write.characteristicUuid == BikeGatt.stateRegister,
    );
    expect(writes.single.value, [0, 0xd1, 1, 4, 3, 0, 0, 0, 0, 0]);
  });

  test('temporary selection never changes the persisted active bike', () async {
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );

    await coordinator.selectTemporarily('second');
    final temporary = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.bike.bike.deviceId == 'second' &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;

    expect(temporary.isTemporary, isTrue);
    expect((await settings.get()).activeBikeId, 'first');
    expect(connections['first']?.single.disposeCalls, 1);

    await coordinator.returnToActiveBike();
    final restored = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.bike.bike.deviceId == 'first' &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;
    expect(restored.isTemporary, isFalse);
    expect(connections['first'], hasLength(2));
  });

  test('making another bike active switches the persisted session', () async {
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );

    await coordinator.makeBikeActive('second');
    final active = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.bike.bike.deviceId == 'second' &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;

    expect(active.isTemporary, isFalse);
    expect((await settings.get()).activeBikeId, 'second');
  });

  test('changing the saved protocol rebuilds the active session', () async {
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );
    connectionFrames['first'] = [
      [0, 0xd0, 2, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
    ];

    await bikes.updateBikeDetails(
      'first',
      displayName: 'First',
      region: null,
      color: BikeColor.royalHorizon,
      protocol: BikeProtocolVersion.v2,
    );
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.bike.bike.protocol == BikeProtocolVersion.v2 &&
          state.sessionState is SessionReady &&
          _sessionOf(coordinator)?.protocolVersion == BikeProtocolVersion.v2,
    );

    expect(connections['first'], hasLength(2));
    expect(connections['first']!.first.disposeCalls, 1);
    expect(
      coordinator.bikes.value
          .singleWhere((saved) => saved.bike.deviceId == 'first')
          .bike
          .protocol,
      BikeProtocolVersion.v2,
    );
    expect(_sessionOf(coordinator)?.protocolVersion, BikeProtocolVersion.v2);
    expect(
      coordinator.state.value,
      isA<ActiveBikeSessionStatus>().having(
        (state) => state.sessionState,
        'sessionState',
        isA<SessionReady>(),
      ),
    );
  });

  test('permission denial is visible and does not create a session', () async {
    permissions.state = BluetoothPermissionState.permanentlyDenied;

    await coordinator.start();
    final state = await _waitFor(
      coordinator.state,
      (state) => state is ActiveBikePermissionRequired,
    );

    expect(
      (state as ActiveBikePermissionRequired).permission,
      BluetoothPermissionState.permanentlyDenied,
    );
    expect(_sessionOf(coordinator), isNull);
    expect(connections, isEmpty);
  });

  test('permission gateway errors become coordinator failures', () async {
    permissions.ensureError = StateError('permission channel unavailable');

    await coordinator.start();
    final state = await _waitFor(
      coordinator.state,
      (state) => state is ActiveBikeCoordinatorFailure,
    );

    expect(
      state,
      isA<ActiveBikeCoordinatorFailure>().having(
        (value) => value.error.toString(),
        'error',
        contains('permission channel unavailable'),
      ),
    );
  });

  test('session factory errors become coordinator failures', () async {
    throwWhenBuildingSession = true;

    await coordinator.start();
    final state = await _waitFor(
      coordinator.state,
      (state) => state is ActiveBikeCoordinatorFailure,
    );

    expect(
      (state as ActiveBikeCoordinatorFailure).error.toString(),
      contains('session factory unavailable'),
    );
  });

  test('foreground resume rechecks a permission granted in settings', () async {
    permissions.state = BluetoothPermissionState.permanentlyDenied;
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) => state is ActiveBikePermissionRequired,
    );

    permissions.state = BluetoothPermissionState.granted;
    await coordinator.setForeground(true);
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );

    expect(permissions.requests, 1);
    expect(permissions.checks, 2);
  });

  test(
    'foreground resume never overlaps the startup permission request',
    () async {
      final permissionGate = Completer<void>();
      permissions.ensureGate = permissionGate;

      await coordinator.start();
      while (permissions.checks == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      final resumed = coordinator.setForeground(true);
      permissionGate.complete();
      await resumed;
      await _waitFor(
        coordinator.state,
        (state) =>
            state is ActiveBikeSessionStatus &&
            state.sessionState is SessionReady,
      );

      expect(permissions.maxConcurrentChecks, 1);
      expect(permissions.requests, 1);
    },
  );

  test(
    'foreground resume reconnects and resynchronizes the active bike',
    () async {
      await coordinator.start();
      await _waitFor(
        coordinator.state,
        (state) =>
            state is ActiveBikeSessionStatus &&
            state.sessionState is SessionReady,
      );
      final connection = connections['first']!.single;

      await coordinator.setForeground(false);
      expect(
        coordinator.state.value,
        isA<ActiveBikeSessionStatus>().having(
          (state) => state.sessionState,
          'sessionState',
          isA<SessionDisconnected>(),
        ),
      );
      connection.readFrames.add([0, 0, 0, 0, 0, 0]);
      await coordinator.setForeground(true);
      await _waitFor(
        coordinator.state,
        (state) =>
            state is ActiveBikeSessionStatus &&
            state.sessionState is SessionReady,
      );

      expect(connection.disconnectCalls, 1);
      expect(connection.connectCalls, 2);
    },
  );

  test('discovery pause defers a session switch until resume', () async {
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );

    final pause = await coordinator.acquireDiscoveryPause();
    expect(pause, isNotNull);
    expect(coordinator.state.value, isA<ActiveBikeLoading>());
    await settings.makeBikeActive('second');
    await _waitUntil(() => coordinator.activeBikeId.peek() == 'second');

    expect(connections['second'], isNull);

    await pause!.release();
    final resumed = await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.bike.bike.deviceId == 'second' &&
          state.sessionState is SessionReady,
    ) as ActiveBikeSessionStatus;

    expect(resumed.bike.bike.deviceId, 'second');
    expect(connections['second'], hasLength(1));
  });

  test('a failed temporary selection still releases its pause', () async {
    final temporaryBike = (await bikes.getBikes()).last;
    final pause = await coordinator.acquireDiscoveryPause();
    expect(pause, isNotNull);
    await database.close();
    databaseClosed = true;

    await expectLater(
      pause!.release(temporarilySelect: temporaryBike),
      throwsA(anything),
    );

    final nextPause = await coordinator.acquireDiscoveryPause();
    expect(nextPause, isNotNull);
    await nextPause!.release();
  });

  test(
    'discovery pause invalidates permission work already in flight',
    () async {
      final permissionGate = Completer<void>();
      permissions.ensureGate = permissionGate;
      await coordinator.start();
      while (permissions.requests == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      final pause = await coordinator.acquireDiscoveryPause();
      expect(pause, isNotNull);
      permissionGate.complete();
      await _waitUntil(() => permissions.concurrentChecks == 0);

      expect(connections, isEmpty);
      expect(_sessionOf(coordinator), isNull);
      await pause!.release();
    },
  );

  test(
    'forgetting the active bike promotes and connects the next bike',
    () async {
      await coordinator.start();
      await _waitFor(
        coordinator.state,
        (state) =>
            state is ActiveBikeSessionStatus &&
            state.sessionState is SessionReady,
      );

      await coordinator.forgetBike('first');
      final promoted = await _waitFor(
        coordinator.state,
        (state) =>
            state is ActiveBikeSessionStatus &&
            state.bike.bike.deviceId == 'second' &&
            state.sessionState is SessionReady,
      ) as ActiveBikeSessionStatus;

      expect(promoted.isTemporary, isFalse);
      expect((await settings.get()).activeBikeId, 'second');
      expect(connections['first']?.single.disposeCalls, 1);
      expect(connections['first'], hasLength(1));
      expect(connections['second']?.single.connectCalls, 1);
    },
  );

  test('manual disconnect pauses until an explicit retry', () async {
    await coordinator.start();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );
    final connection = connections['first']!.single;

    await coordinator.disconnectManually();
    expect(
      coordinator.state.value,
      isA<ActiveBikeSessionStatus>().having(
        (state) => state.sessionState,
        'sessionState',
        isA<SessionDisconnected>().having(
          (state) => state.manuallyPaused,
          'manuallyPaused',
          isTrue,
        ),
      ),
    );
    connection.readFrames.add([0, 0, 0, 0, 0, 0]);
    await coordinator.retry();
    await _waitFor(
      coordinator.state,
      (state) =>
          state is ActiveBikeSessionStatus &&
          state.sessionState is SessionReady,
    );

    expect(connection.connectCalls, 2);
  });
}

Future<ActiveBikeState> _waitFor(
  ReadonlySignal<ActiveBikeState> signal,
  bool Function(ActiveBikeState state) matches,
) {
  final current = signal.peek();
  if (matches(current)) {
    return Future.value(current);
  }
  final completer = Completer<ActiveBikeState>();
  late final EffectCleanup cleanup;
  cleanup = signal.subscribe((state) {
    if (!completer.isCompleted && matches(state)) {
      completer.complete(state);
      cleanup();
    }
  });
  return completer.future.timeout(const Duration(seconds: 2));
}

BikeSession? _sessionOf(ActiveBikeCoordinator coordinator) {
  return switch (coordinator.state.peek()) {
    ActiveBikeSessionStatus(:final session) => session,
    _ => null,
  };
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (!DateTime.now().isBefore(deadline)) {
      fail('Timed out waiting for the coordinator test condition.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}
