import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
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

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bikes = BikeRepository(database: database);
    settings = SettingsRepository(database: database);
    permissions = FakeBluetoothPermissionGateway();
    connections = {};
    connectionFrames = {};
    await settings.initialize();
    await bikes.addBike(deviceId: 'first', displayName: 'First');
    await bikes.addBike(deviceId: 'second', displayName: 'Second');
    coordinator = ActiveBikeCoordinator(
      bikeRepository: bikes,
      settingsRepository: settings,
      permissions: permissions,
      buildSession: (bike) {
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
          pollInterval: null,
          reconnectDelays: const [],
        );
      },
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await database.close();
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

  test('permission denial is visible and does not create a session', () async {
    permissions.state = BluetoothPermissionState.permanentlyDenied;

    await coordinator.start();
    final state = await _waitFor(
      coordinator.state,
      (state) => state is ActiveBikePermissionRequired,
    );

    expect(state, isA<ActiveBikePermissionRequired>());
    expect(coordinator.session.value, isNull);
    expect(connections, isEmpty);
  });

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

    await coordinator.pauseForDiscovery();
    await settings.makeBikeActive('second');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(connections['second'], isNull);

    await coordinator.resumeAfterDiscovery();
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
