import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/domain/bike.dart';

import '../support/fake_bike_transport.dart';

void main() {
  late FakeBikeConnection connection;
  late BikeSession session;

  BikeSession createSession({
    RidePreferences preferences = const RidePreferences.defaults(),
    BikeRegion? region,
    int correctiveAttempts = 2,
    ConfigurationConfirmed? onConfirmed,
    List<Duration> confirmationRetryDelays = const [],
  }) {
    return BikeSession(
      connection: connection,
      preferredRegion: region,
      preferences: preferences,
      onConfigurationConfirmed: onConfirmed,
      pollInterval: null,
      reconnectDelays: const [],
      correctiveAttempts: correctiveAttempts,
      confirmationRetryDelays: confirmationRetryDelays,
    );
  }

  setUp(() {
    connection = FakeBikeConnection(deviceId: 'bike');
  });

  tearDown(() async {
    await session.dispose();
  });

  test('connects, discovers, reads, and becomes ready without locks', () async {
    connection.readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession();

    await session.connect();

    expect(connection.connectCalls, 1);
    expect(connection.discoveryCalls, 1);
    expect(session.state.value, isA<SessionReady>());
    expect(
      session.observed.value,
      const BikeConfiguration(
        light: true,
        mode: 3,
        assist: 2,
        region: BikeRegion.us,
      ),
    );
    expect(connection.writes, hasLength(1));
    expect(
      connection.writes.single.characteristicUuid,
      BikeGatt.registerSelector,
    );
    expect(connection.writes.single.value, BikeGatt.selectCurrentState);
  });

  test('ignores the connection stream initial disconnected snapshot', () async {
    connection.emitInitialDisconnectedState = true;
    connection.readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession();

    await session.connect();
    await Future<void>.delayed(Duration.zero);

    expect(session.state.value, isA<SessionReady>());
    expect(connection.connectCalls, 1);
    expect(connection.discoveryCalls, 1);
  });

  test('applies all locked settings in one write and confirms them', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 4, 0, 1, 3],
    ]);
    session = createSession(
      preferences: const RidePreferences(
        desiredLight: true,
        desiredMode: 3,
        desiredAssist: 4,
        keepLight: true,
        keepMode: true,
        keepAssist: true,
        backgroundRequested: false,
        backgroundConsentVersion: 0,
      ),
    );

    await session.connect();

    final configurationWrites = connection.writes
        .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
        .toList();
    expect(configurationWrites, hasLength(1));
    expect(configurationWrites.single.value, [0, 0xd1, 1, 4, 3, 0, 0, 0, 0, 0]);
    expect(session.state.value, isA<SessionReady>());
  });

  test('caps corrective retries when the bike rejects settings', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]);
    session = createSession(
      correctiveAttempts: 2,
      preferences: const RidePreferences(
        desiredLight: false,
        desiredMode: 3,
        desiredAssist: 0,
        keepLight: false,
        keepMode: true,
        keepAssist: false,
        backgroundRequested: false,
        backgroundConsentVersion: 0,
      ),
    );

    await session.connect();

    expect(
      session.state.value,
      isA<SessionFailed>().having(
        (state) => state.failure,
        'failure',
        isA<BikeSettingsNotApplied>(),
      ),
    );
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      hasLength(2),
    );
  });

  test('serializes user writes and persists only confirmed values', () async {
    connection.operationDelay = const Duration(milliseconds: 2);
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
      [0, 0, 4, 0, 1, 0],
    ]);
    final persisted = <BikeConfiguration>[];
    session = createSession(
      onConfirmed: (configuration) async {
        persisted.add(configuration);
      },
    );
    await session.connect();

    final light = session.setLight(true);
    final assist = session.setAssist(4);
    await Future.wait([light, assist]);

    expect(connection.maxConcurrentOperations, 1);
    expect(persisted, hasLength(2));
    expect(persisted.last.assist, 4);
    expect(session.observed.value?.assist, 4);
  });

  test('waits for the state register to reflect a command', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
    ]);
    session = createSession(confirmationRetryDelays: const [Duration.zero]);
    await session.connect();

    final confirmed = await session.setLight(true);

    expect(confirmed.light, isTrue);
    expect(session.state.value, isA<SessionReady>());
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      hasLength(1),
    );
  });

  test('an unconfirmed command leaves a healthy session usable', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]);
    session = createSession();
    await session.connect();

    await expectLater(
      session.setLight(true),
      throwsA(isA<BikeSettingsNotApplied>()),
    );

    expect(session.state.value, isA<SessionReady>());
    expect(session.observed.value?.light, isFalse);
  });

  test('waits for locked settings without writing them twice', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
    ]);
    session = createSession(
      preferences: const RidePreferences(
        desiredLight: true,
        desiredMode: 0,
        desiredAssist: 0,
        keepLight: true,
        keepMode: false,
        keepAssist: false,
        backgroundRequested: false,
        backgroundConsentVersion: 0,
      ),
      confirmationRetryDelays: const [Duration.zero],
    );

    await session.connect();

    expect(session.state.value, isA<SessionReady>());
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      hasLength(1),
    );
  });

  test('uses the persisted region for configuration writes', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 7],
    ]);
    session = createSession(region: BikeRegion.eu);
    await session.connect();

    await session.setMode(3);

    final write = connection.writes.lastWhere(
      (candidate) => candidate.characteristicUuid == BikeGatt.stateRegister,
    );
    expect(write.value[4], 7);
    expect(session.observed.value?.region, BikeRegion.eu);
  });

  test(
    'manual disconnect pauses reconnect and disposal rejects commands',
    () async {
      connection.readFrames.add([0, 0, 0, 0, 0, 0]);
      session = createSession();
      await session.connect();

      await session.disconnect();

      expect(session.manualReconnectPaused, isTrue);
      expect(
        session.state.value,
        isA<SessionDisconnected>().having(
          (state) => state.manuallyPaused,
          'manuallyPaused',
          isTrue,
        ),
      );

      await session.dispose();
      expect(
        () => session.setLight(true),
        throwsA(isA<BikeSessionDisposedFailure>()),
      );
    },
  );

  test(
    'disconnect waits for a pending command without overlapping GATT',
    () async {
      connection.operationDelay = const Duration(milliseconds: 5);
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
      ]);
      session = createSession();
      await session.connect();

      final change = session.setLight(true);
      while (connection.concurrentOperations == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      final disconnect = session.disconnect();
      await Future.wait([change, disconnect]);

      expect(connection.maxConcurrentOperations, 1);
      expect(connection.disconnectCalls, 1);
      expect(session.state.value, isA<SessionDisconnected>());
    },
  );

  test('foreground pause is idempotent and resume reconnects once', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]);
    session = createSession();
    await session.connect();

    await Future.wait([
      session.pauseForBackground(),
      session.pauseForBackground(),
    ]);
    await session.resumeFromBackground();

    expect(connection.disconnectCalls, 1);
    expect(connection.connectCalls, 2);
    expect(session.state.value, isA<SessionReady>());
  });
}
