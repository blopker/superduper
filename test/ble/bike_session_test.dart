import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';

import '../support/fake_bike_transport.dart';

void main() {
  late FakeBikeConnection connection;
  late BikeSession session;

  BikeSession createSession({
    RidePreferences preferences = const RidePreferences.defaults(),
    BikeRegion? region,
    BikeProtocolVersion protocol = BikeProtocolVersion.v1,
    List<int> authenticationKey = BikeProtocol.defaultAuthenticationKey,
    int correctiveAttempts = 2,
    ConfigurationConfirmed? onConfirmed,
    VersionsRead? onVersionsRead,
    List<Duration> confirmationRetryDelays = const [],
    List<Duration> reconnectDelays = const [],
    List<Duration> synchronizationRetryDelays = const [],
  }) {
    return BikeSession(
      connection: connection,
      preferredRegion: region,
      preferences: preferences,
      protocol: protocol,
      authenticationKey: authenticationKey,
      onConfigurationConfirmed: onConfirmed,
      onVersionsRead: onVersionsRead,
      pollInterval: null,
      reconnectDelays: reconnectDelays,
      synchronizationRetryDelays: synchronizationRetryDelays,
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
    expect(connection.authenticated, isTrue);
    expect(connection.notificationsEnabled, isTrue);
    final selectorWrites = connection.writes
        .where((write) => write.characteristicUuid == BikeGatt.registerSelector)
        .toList();
    expect(selectorWrites.map((write) => write.value), [
      BikeGatt.displayVersionSelector,
      BikeGatt.componentVersionsSelector,
      BikeGatt.v1StateSelector,
    ]);
    final authenticationWrite = connection.writes.singleWhere(
      (write) => write.characteristicUuid == BikeGatt.authenticationResponse,
    );
    expect(
      authenticationWrite.value,
      BikeProtocol.authenticationResponse(
        challenge: connection.authenticationChallenge,
        key: BikeProtocol.defaultAuthenticationKey,
      ),
    );
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      isEmpty,
    );
  });

  test('pushes matching locked settings on every connection', () async {
    connection.readFrames.addAll([
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
    ]);
    session = createSession(
      preferences: const RidePreferences(
        desiredLight: true,
        desiredMode: 0,
        desiredAssist: 4,
        keepLight: true,
        keepMode: false,
        keepAssist: true,
      ),
    );

    await session.connect();
    await session.pauseForBackground();
    await session.resumeFromBackground();

    final configurationWrites = connection.writes
        .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
        .toList();
    expect(configurationWrites, hasLength(2));
    expect(configurationWrites.map((write) => write.value), [
      [0, 0xd1, 1, 4, 3, 0, 0, 0, 0, 0],
      [0, 0xd1, 1, 4, 3, 0, 0, 0, 0, 0],
    ]);
    expect(session.state.value, isA<SessionReady>());
  });

  test(
    'rejects an invalid authentication response before reading state',
    () async {
      connection.authenticationKey = List<int>.filled(20, 0);
      session = createSession();

      await session.connect();

      expect(
        session.state.value,
        isA<SessionFailed>().having(
          (state) => state.failure,
          'failure',
          isA<BikeAuthenticationFailed>(),
        ),
      );
      expect(connection.authenticated, isFalse);
      expect(connection.notificationsEnabled, isFalse);
      expect(
        connection.reads.where(
          (read) => read.characteristicUuid == BikeGatt.stateRegister,
        ),
        isEmpty,
      );
    },
  );

  test('retries a transport failure during authentication', () async {
    connection
      ..firmwareRevision = null
      ..readErrors[BikeGatt.authenticationChallenge] =
          const BikeConnectionFailure('Read', 'The link was lost.');
    session = createSession(
      reconnectDelays: const [Duration(hours: 1)],
    );

    await session.connect();

    expect(session.state.value, isA<SessionReconnecting>());
  });

  test('firmware revision is metadata and does not affect protocol', () async {
    connection
      ..firmwareRevision = '260101'
      ..softwareRevision = '260101'
      ..readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession();

    await session.connect();

    expect(session.state.value, isA<SessionReady>());
    expect(session.protocolVersion, BikeProtocolVersion.v1);
    expect(session.versions.value?.firmwareRevision, '260101');
  });

  test('reads every bike version on each successful connection', () async {
    connection.readFrames.addAll([
      [0, 0, 2, 0, 1, 3],
      [0, 0, 2, 0, 1, 3],
    ]);
    final snapshots = <BikeVersionInfo>[];
    session = createSession(
      onVersionsRead: (versions) async {
        snapshots.add(versions);
      },
    );

    await session.connect();
    await session.pauseForBackground();
    await session.resumeFromBackground();

    const expected = BikeVersionInfo(
      hardwareRevision: 'v3.2.0',
      firmwareRevision: '221122',
      softwareRevision: '221122',
      stmFirmwareVersion: 0x010203,
      controllerVariant: 0x0196,
      bootloaderHandoff: 8,
      motorControllerVersion: 0x12345678,
      bmsVersion: 0xabcdef01,
    );
    expect(snapshots, [expected, expected]);
    expect(session.versions.value, expected);
    expect(
      connection.writes.where(
        (write) =>
            write.characteristicUuid == BikeGatt.registerSelector &&
            write.value[0] == 0xfc,
      ),
      hasLength(2),
    );
  });

  test('a version cache failure does not prevent ride readiness', () async {
    connection.readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession(
      onVersionsRead: (_) async {
        throw StateError('database unavailable');
      },
    );

    await session.connect();

    expect(session.state.value, isA<SessionReady>());
    expect(session.versions.value, isNotNull);
  });

  test('advertised-name protocol wins over firmware metadata', () async {
    connection
      ..firmwareRevision = '221122'
      ..readFrames.addAll([
        [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      ]);
    session = createSession(protocol: BikeProtocolVersion.v2);

    await session.connect();

    expect(session.state.value, isA<SessionReady>());
    expect(session.protocolVersion, BikeProtocolVersion.v2);
    expect(connection.authenticated, isTrue);
  });

  test(
    'advertised-name protocol works without revision characteristics',
    () async {
      connection
        ..firmwareRevision = null
        ..readFrames.add([3, 0, 2, 0, 1, 3, 0, 0, 0, 0]);
      session = createSession();

      await session.connect();

      expect(session.protocolVersion, BikeProtocolVersion.v1);
      expect(session.state.value, isA<SessionReady>());
      expect(session.versions.value, isNull);
    },
  );

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

  test('keeps reconnecting until a powered-off bike returns', () async {
    connection.readFrames.addAll([
      [0, 0, 2, 0, 1, 3],
      [0, 0, 2, 0, 1, 3],
    ]);
    session = createSession(
      reconnectDelays: const [Duration(milliseconds: 20)],
    );
    await session.connect();

    connection
      ..connectError = StateError('bike is off')
      ..emitState(BikeConnectionState.disconnected);
    await _waitUntil(() => connection.connectCalls == 2);
    connection.connectError = null;

    await _waitUntil(() => session.state.value is SessionReady);
    expect(connection.connectCalls, 3);
    expect(session.observed.value?.mode, 3);
  });

  test(
    'retries locked settings while the controller finishes booting',
    () async {
      connection.readFrames.addAll([
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 0],
        [0, 0, 2, 0, 1, 0],
        [0, 0, 2, 0, 1, 3],
      ]);
      session = createSession(
        preferences: const RidePreferences(
          desiredLight: true,
          desiredMode: 3,
          desiredAssist: 2,
          keepLight: true,
          keepMode: true,
          keepAssist: true,
        ),
        correctiveAttempts: 1,
        reconnectDelays: const [Duration.zero],
        synchronizationRetryDelays: const [Duration(milliseconds: 20)],
      );
      await session.connect();

      connection.emitState(BikeConnectionState.disconnected);
      await _waitUntil(() => connection.connectCalls == 2);
      await _waitUntil(
        () =>
            session.state.value is SessionReady &&
            session.observed.value?.mode == 3,
      );

      expect(
        connection.writes.where(
          (write) => write.characteristicUuid == BikeGatt.stateRegister,
        ),
        hasLength(2),
      );
    },
  );

  test(
    'a failed state read reconnects instead of ending the session',
    () async {
      connection.readFrames.addAll([
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 3],
      ]);
      session = createSession(
        reconnectDelays: const [Duration(milliseconds: 20)],
      );
      await session.connect();

      connection.readError = StateError('bike stopped responding');
      await expectLater(
        session.synchronize(),
        throwsA(isA<BikeSessionTransportFailure>()),
      );
      expect(session.state.value, isA<SessionReconnecting>());
      connection.readError = null;

      await _waitUntil(() => session.state.value is SessionReady);
      expect(connection.connectCalls, 2);
    },
  );

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
      preferences: const RidePreferences(
        desiredLight: false,
        desiredMode: 3,
        desiredAssist: 0,
        keepLight: false,
        keepMode: true,
        keepAssist: false,
      ),
    );

    await session.connect();

    expect(session.state.value, isA<SessionDegraded>());
    expect(session.canChangeConfiguration, isTrue);
    final configurationWrites = connection.writes
        .where(
          (write) => write.characteristicUuid == BikeGatt.stateRegister,
        )
        .toList();
    expect(configurationWrites, hasLength(2));
    expect(
      configurationWrites.map((write) => write.value),
      everyElement([0, 0xd1, 0, 0, 3, 0, 0, 0, 0, 0]),
    );
  });

  test('serializes user writes and persists only confirmed values', () async {
    connection.operationDelay = const Duration(milliseconds: 2);
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
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
    expect(persisted, hasLength(1));
    expect(persisted.single.light, isTrue);
    expect(persisted.last.assist, 4);
    expect(session.observed.value?.assist, 4);
  });

  test('coalesces rapid configuration changes to the latest value', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
      [0, 0, 0, 0, 0, 0],
    ]);
    session = createSession();
    await session.connect();
    connection.operationDelay = const Duration(milliseconds: 5);

    final first = session.setLight(true);
    await _waitUntil(
      () => connection.writes.any(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
    );
    final changes = [
      session.setLight(false),
      session.setLight(true),
      session.setLight(false),
    ];
    await Future.wait([first, ...changes]);

    final writes = connection.writes
        .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
        .toList();
    expect(writes, hasLength(2));
    expect(writes.first.value[2], 1);
    expect(writes.last.value[2], 0);
    expect(session.observed.value?.light, isFalse);
    expect(session.pending.value, isNull);
  });

  test(
    'a confirmed locked change updates in-memory enforcement immediately',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 0],
      ]);
      session = createSession(
        preferences: const RidePreferences(
          desiredLight: false,
          desiredMode: 0,
          desiredAssist: 0,
          keepLight: true,
          keepMode: false,
          keepAssist: false,
        ),
      );
      await session.connect();

      await session.setLight(true);
      final writesBeforeNotification = connection.writes
          .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
          .length;
      connection.emitNotification([3, 0, 0, 0, 1, 0, 0, 0, 0, 0]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        connection.writes.where(
          (write) => write.characteristicUuid == BikeGatt.stateRegister,
        ),
        hasLength(writesBeforeNotification),
      );
      expect(session.observed.value?.light, isTrue);
    },
  );

  test('retries a command when its first confirmation is unchanged', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
    ]);
    session = createSession(
      confirmationRetryDelays: const [Duration.zero, Duration.zero],
    );
    await session.connect();

    final confirmed = await session.setLight(true);

    expect(confirmed.light, isTrue);
    expect(session.state.value, isA<SessionReady>());
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      hasLength(2),
    );
  });

  test('an unconfirmed command leaves the connected session usable', () async {
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

    expect(session.state.value, isA<SessionDegraded>());
    expect(session.canChangeConfiguration, isTrue);
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
      ),
      confirmationRetryDelays: const [Duration.zero, Duration.zero],
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

  test('reads and writes the V2 control and ride-mode records', () async {
    connection.firmwareRevision = '250426';
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
    ]);
    session = createSession(protocol: BikeProtocolVersion.v2);
    await session.connect();

    final confirmed = await session.setMode(3);

    expect(session.protocolVersion, BikeProtocolVersion.v2);
    expect(confirmed.mode, 3);
    final write = connection.writes.lastWhere(
      (candidate) => candidate.characteristicUuid == BikeGatt.stateRegister,
    );
    expect(write.value, [0, 0xc1, 0, 1, 3, 0, 0, 0, 0, 0]);
  });

  test('uses V2 notifications as the live source of bike state', () async {
    connection.firmwareRevision = '250426';
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
    ]);
    session = createSession(protocol: BikeProtocolVersion.v2);
    await session.connect();
    final initialStateReads = connection.reads
        .where((read) => read.characteristicUuid == BikeGatt.stateRegister)
        .length;

    connection
      ..emitNotification([0, 0xd0, 4, 0, 1, 0, 0, 0, 0, 0])
      ..emitNotification([0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0]);
    await _waitUntil(
      () =>
          session.observed.value?.light == true &&
          session.observed.value?.assist == 4 &&
          session.observed.value?.mode == 3,
    );

    expect(
      connection.reads
          .where((read) => read.characteristicUuid == BikeGatt.stateRegister)
          .length,
      initialStateReads,
    );
  });

  test(
    'drops one malformed telemetry packet without failing the session',
    () async {
      connection.readFrames.add([0, 0, 2, 0, 1, 3]);
      session = createSession();
      await session.connect();

      connection.emitNotification([3]);
      await Future<void>.delayed(Duration.zero);

      expect(session.state.value, isA<SessionReady>());
      expect(session.observed.value?.mode, 3);
    },
  );

  test('requires an authoritative read after a command notification', () async {
    connection.firmwareRevision = '250426';
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
    ]);
    session = createSession(
      protocol: BikeProtocolVersion.v2,
      confirmationRetryDelays: const [Duration.zero],
    );
    await session.connect();
    final initialStateReads = connection.reads
        .where((read) => read.characteristicUuid == BikeGatt.stateRegister)
        .length;

    final change = session.setMode(3);
    await _waitUntil(
      () => connection.writes.any(
        (write) =>
            write.characteristicUuid == BikeGatt.stateRegister &&
            write.value[1] == 0xc1,
      ),
    );
    connection.emitNotification([0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0]);

    expect((await change).mode, 3);
    expect(
      connection.reads
          .where((read) => read.characteristicUuid == BikeGatt.stateRegister)
          .length,
      initialStateReads + 2,
    );
  });

  test('re-applies a locked setting changed by a V2 notification', () async {
    connection.firmwareRevision = '250426';
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
    ]);
    session = createSession(
      protocol: BikeProtocolVersion.v2,
      preferences: const RidePreferences(
        desiredLight: true,
        desiredMode: 0,
        desiredAssist: 0,
        keepLight: true,
        keepMode: false,
        keepAssist: false,
      ),
      confirmationRetryDelays: const [Duration.zero],
    );
    await session.connect();
    final initialConfigurationWrites = connection.writes
        .where(
          (write) =>
              write.characteristicUuid == BikeGatt.stateRegister &&
              write.value[1] == 0xc1,
        )
        .length;
    expect(initialConfigurationWrites, 1);

    connection.emitNotification([0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0]);
    await _waitUntil(
      () =>
          connection.writes
              .where(
                (write) =>
                    write.characteristicUuid == BikeGatt.stateRegister &&
                    write.value[1] == 0xc1,
              )
              .length ==
          initialConfigurationWrites + 1,
    );
    await _waitUntil(
      () =>
          session.state.value is SessionReady &&
          session.observed.value?.light == true,
    );

    expect(session.observed.value?.light, isTrue);
    expect(
      connection.writes.where(
        (write) =>
            write.characteristicUuid == BikeGatt.stateRegister &&
            write.value[1] == 0xc1,
      ),
      hasLength(2),
    );
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
      await expectLater(change, throwsA(isA<BikeSessionDisposedFailure>()));
      await disconnect;

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
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.authenticationResponse,
      ),
      hasLength(2),
    );
    expect(session.state.value, isA<SessionReady>());
  });

  test(
    'configuration changes publish an optimistic value immediately',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
      ]);
      session = createSession();
      await session.connect();
      connection.operationDelay = const Duration(milliseconds: 10);

      final change = session.setLight(true);

      expect(session.pending.value?.light, isTrue);
      expect(session.canChangeConfiguration, isTrue);
      await change;
      expect(session.pending.value, isNull);
      expect(session.observed.value?.light, isTrue);
    },
  );

  test(
    'locked-setting retries stop in a controllable degraded state',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 2],
      ]);
      session = createSession(
        preferences: const RidePreferences(
          desiredLight: false,
          desiredMode: 3,
          desiredAssist: 0,
          keepLight: false,
          keepMode: true,
          keepAssist: false,
        ),
        correctiveAttempts: 1,
        synchronizationRetryDelays: const [Duration(milliseconds: 1)],
      );

      await session.connect();
      await _waitUntil(() => session.state.value is SessionDegraded);

      expect(session.canChangeConfiguration, isTrue);
      await session.setMode(2);
      expect(session.observed.value?.mode, 2);
      expect(session.state.value, isA<SessionReady>());
    },
  );

  test(
    'backgrounding aborts a pending connect and resume starts a new one',
    () async {
      final gate = Completer<void>();
      connection.connectGate = gate;
      session = createSession();

      final firstConnect = session.connect();
      await _waitUntil(() => connection.connectCalls == 1);
      final pause = session.pauseForBackground();
      await _waitUntil(() => connection.disconnectCalls == 1);

      connection.connectGate = null;
      gate.complete();
      await Future.wait([firstConnect, pause]);
      connection.readFrames.add([0, 0, 0, 0, 0, 0]);
      await session.resumeFromBackground();

      expect(connection.connectCalls, 2);
      expect(session.state.value, isA<SessionReady>());
    },
  );

  test(
    'resuming invalidates a background pause queued behind a command',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1, 0],
      ]);
      session = createSession();
      await session.connect();

      final gate = Completer<void>();
      connection.operationGate = gate;
      final change = session.setLight(true);
      await _waitUntil(() => connection.concurrentOperations == 1);

      final pause = session.pauseForBackground();
      final resume = session.resumeFromBackground();
      gate.complete();

      await expectLater(change, throwsA(isA<BikeSessionDisposedFailure>()));
      await Future.wait([pause, resume]);

      expect(connection.connectCalls, 2);
      expect(session.state.value, isA<SessionReady>());
      expect(session.manualReconnectPaused, isFalse);
    },
  );

  test(
    'resuming while a pending connect is cancelled keeps the new connection',
    () async {
      final connectGate = Completer<void>();
      final disconnectGate = Completer<void>();
      connection
        ..connectGate = connectGate
        ..disconnectGate = disconnectGate;
      session = createSession();

      final firstConnect = session.connect();
      await _waitUntil(() => connection.connectCalls == 1);
      final pause = session.pauseForBackground();
      await _waitUntil(() => connection.disconnectCalls == 1);

      connection.connectGate = null;
      connection.readFrames.add([0, 0, 0, 0, 0, 0]);
      final resume = session.resumeFromBackground();
      disconnectGate.complete();
      await Future.wait([firstConnect, pause, resume]);

      expect(connection.connectCalls, 2);
      expect(connection.disconnectCalls, greaterThanOrEqualTo(1));
      expect(session.state.value, isA<SessionReady>());
    },
  );

  test('a quick reconnect invalidates a queued manual disconnect', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]);
    session = createSession();
    await session.connect();

    final disconnect = session.disconnect();
    final reconnect = session.connect();
    await Future.wait([disconnect, reconnect]);

    expect(connection.connectCalls, 2);
    expect(session.state.value, isA<SessionReady>());
    expect(session.manualReconnectPaused, isFalse);
  });

  test('a failed synchronization clears its optimistic value', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0xff],
    ]);
    session = createSession();
    await session.connect();

    await expectLater(
      session.updatePreferences(
        const RidePreferences(
          desiredLight: false,
          desiredMode: 3,
          desiredAssist: 0,
          keepLight: false,
          keepMode: true,
          keepAssist: false,
        ),
      ),
      throwsA(isA<BikeSessionFailure>()),
    );

    expect(session.pending.value, isNull);
    expect(session.state.value, isA<SessionFailed>());
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 1));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not reached before the test timeout.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}
