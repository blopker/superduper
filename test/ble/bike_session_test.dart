import 'dart:async';

import 'package:fake_async/fake_async.dart';
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
    BikeControlPatch setOnConnect = const BikeControlPatch(),
    BikeRegion? region,
    BikeProtocolVersion protocol = BikeProtocolVersion.v1,
    List<int> authenticationKey = BikeProtocol.defaultAuthenticationKey,
    int correctiveAttempts = 2,
    VersionsRead? onVersionsRead,
    OdometerRead? onOdometerRead,
    List<Duration> confirmationRetryDelays = const [],
    List<Duration> reconnectDelays = const [],
    List<Duration> synchronizationRetryDelays = const [],
    bool readDiagnosticsOnConnect = true,
    Duration? pollInterval,
    BikeProtocolDefinition? connectedProtocol,
  }) {
    return BikeSession(
      connection: connection,
      preferredRegion: region,
      setOnConnect: setOnConnect,
      protocol: protocol,
      authenticationKey: authenticationKey,
      onVersionsRead: onVersionsRead,
      onOdometerRead: onOdometerRead,
      readDiagnosticsOnConnect: readDiagnosticsOnConnect,
      pollInterval: pollInterval,
      reconnectDelays: reconnectDelays,
      synchronizationRetryDelays: synchronizationRetryDelays,
      correctiveAttempts: correctiveAttempts,
      confirmationRetryDelays: confirmationRetryDelays,
      connectedProtocol: connectedProtocol,
    );
  }

  setUp(() {
    connection = FakeBikeConnection(deviceId: 'bike');
  });

  tearDown(() async {
    await session.dispose();
  });

  test(
    'connects, discovers, reads, and becomes ready without settings',
    () async {
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
          .where(
            (write) => write.characteristicUuid == BikeGatt.registerSelector,
          )
          .toList();
      expect(selectorWrites.map((write) => write.value), [
        BikeGatt.displayVersionSelector,
        BikeGatt.v1StateSelector,
        BikeGatt.v1OdometerSelector,
        BikeGatt.displayVersionSelector,
        BikeGatt.componentVersionsSelector,
      ]);
      expect(session.odometerMeters.value, connection.odometerMeters);
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
    },
  );

  test('session orchestration can use a connected protocol object', () async {
    const configuration = BikeConfiguration(
      light: false,
      mode: 2,
      assist: 3,
      region: BikeRegion.us,
    );
    final protocol = _FakeConnectedProtocol(configuration);
    session = createSession(
      readDiagnosticsOnConnect: false,
      connectedProtocol: protocol,
    );

    await session.connect();

    expect(session.observed.value, configuration);
    expect(session.state.value, isA<SessionReady>());
    expect(protocol.configurationReads, 1);
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.registerSelector,
      ),
      isEmpty,
    );
  });

  test('invalidates a same-ID history result before accepting state', () async {
    connection
      ..selectedHistoryId = List<int>.from(BikeGatt.v1StateSelector)
      ..delayHistorySelectionUntilRead = true
      ..readFrames.addAll([
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 0, 3],
      ]);
    session = createSession(readDiagnosticsOnConnect: false);

    await session.connect();

    expect(session.observed.value?.light, isFalse);
  });

  test(
    'invalidates a same-ID V2 control result before accepting state',
    () async {
      connection
        ..selectedHistoryId = List<int>.from(BikeGatt.v2ControlSelector)
        ..delayHistorySelectionUntilRead = true
        ..readFrames.addAll([
          [0, 0xd0, 2, 0, 1, 0, 0, 0, 0, 0],
          [0, 0xd0, 2, 0, 0, 0, 0, 0, 0, 0],
          [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
        ]);
      session = createSession(
        protocol: BikeProtocolVersion.v2,
        readDiagnosticsOnConnect: false,
      );

      await session.connect();

      expect(session.observed.value?.light, isFalse);
      expect(session.observed.value?.mode, 3);
    },
  );

  test('continues when the optional cache-barrier record is absent', () async {
    connection
      ..displayVersionFrame = [0xaa, 0xaa, 0, 0, 0, 0, 0, 0, 0, 0]
      ..readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession(readDiagnosticsOnConnect: false);

    await session.connect();

    expect(session.state.value, isA<SessionReady>());
    expect(session.observed.value?.light, isTrue);
  });

  test('does not add a barrier between different V2 selectors', () async {
    connection.readFrames.addAll([
      [0, 0xd0, 2, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
      [0, 0xd0, 2, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
    ]);
    session = createSession(
      protocol: BikeProtocolVersion.v2,
      readDiagnosticsOnConnect: false,
    );
    await session.connect();
    final initialBarriers = connection.writes
        .where(
          (write) =>
              write.characteristicUuid == BikeGatt.registerSelector &&
              _sameBytes(write.value, BikeGatt.displayVersionSelector),
        )
        .length;

    await session.setMode(2);

    final barriers = connection.writes.where(
      (write) =>
          write.characteristicUuid == BikeGatt.registerSelector &&
          _sameBytes(write.value, BikeGatt.displayVersionSelector),
    );
    expect(initialBarriers, 1);
    expect(barriers, hasLength(1));
  });

  test('a retained wrong history record fails the session', () async {
    connection.readFrames.add([0xaa, 0xaa, 0, 0, 0, 0, 0, 0, 0, 0]);
    session = createSession(readDiagnosticsOnConnect: false);

    await session.connect();

    expect(
      session.state.value,
      isA<SessionFailed>().having(
        (state) => state.failure.message,
        'failure message',
        contains('invalid data'),
      ),
    );
  });

  test('invalidates observed configuration when the connection ends', () async {
    connection.readFrames.add([0, 0, 2, 0, 1, 3]);
    session = createSession(readDiagnosticsOnConnect: false);
    await session.connect();

    await session.pauseForBackground();

    expect(session.observed.value, isNull);
  });

  test('pushes matching Set on connect settings on every connection', () async {
    connection.readFrames.addAll([
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
      [0, 0, 4, 0, 1, 3],
    ]);
    session = createSession(
      setOnConnect: const BikeControlPatch(light: true, assist: 4),
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
    'retries one fixed startup target when an unselected value changes',
    () async {
      connection.readFrames.addAll([
        [3, 0, 1, 0, 0, 0],
        [3, 0, 2, 0, 0, 0],
        [3, 0, 2, 0, 0, 3],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(mode: 3),
        readDiagnosticsOnConnect: false,
      );

      await session.connect();

      final writes = connection.writes
          .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
          .map((write) => write.value)
          .toList();
      expect(writes, hasLength(2));
      expect(writes[0], writes[1]);
      expect(writes[0][3], 1);
    },
  );

  test(
    'a startup write preserves controls that are not in the intent',
    () async {
      connection.readFrames.addAll([
        [3, 0, 2, 0, 1, 2],
        [3, 0, 2, 0, 1, 3],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(mode: 3),
        readDiagnosticsOnConnect: false,
      );

      await session.connect();

      final write = connection.writes.singleWhere(
        (candidate) => candidate.characteristicUuid == BikeGatt.stateRegister,
      );
      expect(write.value[2], 1);
      expect(session.observed.value?.light, isTrue);
      expect(
        session.state.value,
        isA<SessionReady>().having(
          (state) => state.configuration.light,
          'configuration.light',
          isTrue,
        ),
      );
    },
  );

  test(
    'a V2 startup write preserves controls that are not in the intent',
    () async {
      connection.readFrames.addAll([
        [0, 0xd0, 0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
        [0, 0xd0, 0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0xd9, 0, 0, 0, 3, 0, 0, 0, 0],
      ]);
      session = createSession(
        protocol: BikeProtocolVersion.v2,
        setOnConnect: const BikeControlPatch(mode: 3),
        readDiagnosticsOnConnect: false,
      );

      await session.connect();

      final write = connection.writes.singleWhere(
        (candidate) => candidate.characteristicUuid == BikeGatt.stateRegister,
      );
      expect(write.value[2], 1);
      expect(session.observed.value?.light, isTrue);
    },
  );

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
      hasLength(4),
    );
  });

  test('reads and publishes the V1 odometer on every connection', () async {
    connection
      ..odometerMeters = 12345678
      ..readFrames.addAll([
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 3],
      ]);
    final readings = <int>[];
    session = createSession(
      onOdometerRead: (meters) async => readings.add(meters),
    );

    await session.connect();
    await session.pauseForBackground();
    await session.resumeFromBackground();

    expect(readings, [12345678, 12345678]);
    expect(session.odometerMeters.value, 12345678);
    expect(
      connection.writes.where(
        (write) =>
            write.characteristicUuid == BikeGatt.registerSelector &&
            write.value[0] == 0x02 &&
            write.value[1] == 0x02,
      ),
      hasLength(2),
    );
  });

  test('reuses the V2 control record as its odometer reading', () async {
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 0, 0, 0x40, 0xe2, 0x01, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
    ]);
    final readings = <int>[];
    session = createSession(
      protocol: BikeProtocolVersion.v2,
      onOdometerRead: (meters) async => readings.add(meters),
    );

    await session.connect();

    expect(readings, [123456]);
    expect(session.odometerMeters.value, 123456);
    expect(
      connection.writes.where(
        (write) =>
            write.characteristicUuid == BikeGatt.registerSelector &&
            write.value[0] == 0 &&
            write.value[1] == 0xd0,
      ),
      hasLength(1),
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
    'reconnect and control confirmation use the bike-reported state',
    () async {
      connection.readFrames.addAll([
        [3, 0, 2, 0, 1, 3],
        [3, 0, 2, 0, 1, 3],
      ]);
      session = createSession(
        readDiagnosticsOnConnect: false,
        reconnectDelays: const [Duration.zero],
      );
      await session.connect();
      expect(session.observed.value?.light, isTrue);

      connection.emitState(BikeConnectionState.disconnected);
      await _waitUntil(
        () =>
            connection.connectCalls == 2 && session.state.value is SessionReady,
      );

      expect(session.observed.value?.light, isTrue);
      final readsBeforeWrite = connection.reads
          .where(
            (read) => read.characteristicUuid == BikeGatt.stateRegister,
          )
          .length;

      final confirmed = await session.setLight(false);

      expect(confirmed.light, isFalse);
      expect(session.observed.value?.light, isFalse);
      expect(
        connection.reads.where(
          (read) => read.characteristicUuid == BikeGatt.stateRegister,
        ),
        hasLength(readsBeforeWrite),
      );
      expect(
        connection.writes
            .where(
              (write) => write.characteristicUuid == BikeGatt.stateRegister,
            )
            .single
            .value[2],
        0,
      );
    },
  );

  test('re-arms reconnect after a late platform disconnect event', () async {
    connection.readErrors[BikeGatt.authenticationChallenge] =
        const BikeConnectionFailure('Read', 'The link was lost.');
    session = createSession(
      reconnectDelays: const [Duration(milliseconds: 20)],
    );

    await session.connect();
    expect(session.state.value, isA<SessionReconnecting>());
    expect(connection.connectCalls, 1);

    connection.emitState(BikeConnectionState.disconnected);
    await _waitUntil(() => connection.connectCalls > 1);

    expect(session.state.value, isA<SessionReconnecting>());
  });

  test(
    'retries Set on connect while the controller finishes booting',
    () async {
      connection.readFrames.addAll([
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 3],
        [0, 0, 2, 0, 1, 0],
        [0, 0, 2, 0, 1, 0],
        [0, 0, 2, 0, 1, 3],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(
          light: true,
          mode: 3,
          assist: 2,
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

  test('applies all Set on connect settings in one write', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 4, 0, 1, 3],
    ]);
    session = createSession(
      setOnConnect: const BikeControlPatch(
        light: true,
        mode: 3,
        assist: 4,
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
      setOnConnect: const BikeControlPatch(mode: 3),
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

  test('serializes live control writes', () async {
    connection.operationDelay = const Duration(milliseconds: 2);
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 4, 0, 1, 0],
    ]);
    session = createSession();
    await session.connect();

    final light = session.setLight(true);
    final assist = session.setAssist(4);
    await Future.wait([light, assist]);

    expect(connection.maxConcurrentOperations, 1);
    expect(session.observed.value?.assist, 4);
  });

  test(
    'live controls preserve physical changes to Set on connect fields',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 3],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(light: true),
      );
      await session.connect();
      connection.emitNotification([3, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
      await _waitUntil(() => session.observed.value?.light == false);

      await session.setMode(3);

      final write = connection.writes.lastWhere(
        (candidate) => candidate.characteristicUuid == BikeGatt.stateRegister,
      );
      expect(write.value[2], 0);
      expect(write.value[4], 3);
    },
  );

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
    'writes the final explicit command when cached state already matches it',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1, 0],
      ]);
      session = createSession();
      await session.connect();

      final off = session.setLight(false);
      final on = session.setLight(true);
      await Future.wait([off, on]);

      final writes = connection.writes
          .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
          .toList();
      expect(writes, hasLength(1));
      expect(writes.single.value[2], 1);
      expect(session.observed.value?.light, isTrue);
    },
  );

  test(
    'preserves a user command queued during Set on connect',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 3],
        [0, 0, 0, 0, 1, 3],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(mode: 3),
        confirmationRetryDelays: const [Duration(milliseconds: 10)],
      );

      final connect = session.connect();
      await _waitUntil(() => connection.configurationWriteStarts == 1);
      final change = session.setLight(true);

      await connect;
      final confirmed = await change;

      expect(confirmed.light, isTrue);
      expect(confirmed.mode, 3);
      expect(session.pending.value, isNull);
      expect(session.state.value, isA<SessionReady>());
    },
  );

  test(
    'a confirmed command updates the observed configuration immediately',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 0],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(light: true),
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

  test(
    'waits for Set on connect confirmation without a second write',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(light: true),
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
    },
  );

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
    'uses selected V1 region for every write and confirms the wire family',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 1],
        [0, 0, 0, 0, 1, 1],
        [0, 0, 0, 0, 1, 5],
      ]);
      session = createSession(
        region: BikeRegion.eu,
        confirmationRetryDelays: const [Duration.zero, Duration.zero],
      );
      await session.connect();

      final confirmed = await session.setLight(true);

      final writes = connection.writes
          .where((write) => write.characteristicUuid == BikeGatt.stateRegister)
          .toList();
      expect(writes, hasLength(2));
      expect(writes.map((write) => write.value[4]), everyElement(5));
      expect(confirmed.region, BikeRegion.eu);
      expect(session.observed.value?.region, BikeRegion.eu);
    },
  );

  test('does not leak periodic poll timers when readiness is republished', () {
    fakeAsync((async) {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
      ]);
      session = BikeSession(
        connection: connection,
        preferredRegion: null,
        setOnConnect: const BikeControlPatch(),
        protocol: BikeProtocolVersion.v1,
        reconnectDelays: const [],
        confirmationRetryDelays: const [],
      );
      unawaited(session.connect());
      async.flushMicrotasks();
      expect(async.periodicTimerCount, 1);

      unawaited(session.setLight(false));
      async.flushMicrotasks();
      expect(async.periodicTimerCount, 1);

      unawaited(session.dispose());
      async.flushMicrotasks();
      expect(async.periodicTimerCount, 0);
    });
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

  test('does not re-apply a set-on-connect value after telemetry', () async {
    connection.firmwareRevision = '250426';
    connection.readFrames.addAll([
      [0, 0xd0, 1, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
      [0, 0xd0, 1, 0, 1, 0, 0, 0, 0, 0],
      [0, 0xd9, 0, 0, 0, 2, 0, 0, 0, 0],
    ]);
    session = createSession(
      protocol: BikeProtocolVersion.v2,
      setOnConnect: const BikeControlPatch(light: true),
      confirmationRetryDelays: const [Duration.zero],
    );
    await session.connect();
    await Future<void>.delayed(Duration.zero);
    expect(session.state.value, isA<SessionReady>());
    final initialConfigurationWrites = connection.writes
        .where(
          (write) =>
              write.characteristicUuid == BikeGatt.stateRegister &&
              write.value[1] == 0xc1,
        )
        .length;
    expect(initialConfigurationWrites, 1);

    connection.emitNotification([0, 0xd0, 1, 0, 0, 0, 0, 0, 0, 0]);
    await _waitUntil(() => session.observed.value?.light == false);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(session.observed.value?.light, isFalse);
    expect(
      connection.writes.where(
        (write) =>
            write.characteristicUuid == BikeGatt.stateRegister &&
            write.value[1] == 0xc1,
      ),
      hasLength(initialConfigurationWrites),
    );
  });

  test(
    'polling observes changes without re-applying set-on-connect values',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(light: true),
        pollInterval: const Duration(milliseconds: 5),
      );
      await session.connect();
      await _waitUntil(() => session.observed.value?.light == false);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(session.observed.value?.light, isFalse);
      expect(
        connection.writes.where(
          (write) => write.characteristicUuid == BikeGatt.stateRegister,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'manual disconnect pauses reconnect and disposal rejects commands',
    () async {
      connection.readFrames.add([0, 0, 0, 0, 0, 0]);
      session = createSession();
      await session.connect();

      await session.disconnect();

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
    'Set on connect retries stop in a controllable degraded state',
    () async {
      connection.readFrames.addAll([
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 2],
      ]);
      session = createSession(
        setOnConnect: const BikeControlPatch(mode: 3),
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
  });

  test('Set on connect edits wait until the next connection', () async {
    connection.readFrames.addAll([
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 1, 0],
    ]);
    session = createSession();
    await session.connect();
    final writesBeforeEdit = connection.writes.where(
      (write) => write.characteristicUuid == BikeGatt.stateRegister,
    );

    session.updateSetOnConnect(
      const BikeControlPatch(light: true),
    );
    await Future<void>.delayed(Duration.zero);
    expect(writesBeforeEdit, isEmpty);

    await session.pauseForBackground();
    await session.resumeFromBackground();

    expect(session.state.value, isA<SessionReady>());
    expect(
      connection.writes.where(
        (write) => write.characteristicUuid == BikeGatt.stateRegister,
      ),
      hasLength(1),
    );
  });
}

final class _FakeConnectedProtocol extends BikeProtocolDefinition {
  _FakeConnectedProtocol(this.configuration);

  final BikeConfiguration configuration;
  int configurationReads = 0;

  @override
  BikeControlPatch? decodeTelemetry(List<int> packet) => null;

  @override
  List<int> encodeConfiguration(BikeConfiguration configuration) {
    throw UnsupportedError('Writes are overridden in this test.');
  }

  @override
  Future<BikeConfiguration> readConfiguration({
    required BikeRegion? preferredRegion,
    required BikeRegion? fallbackRegion,
    void Function(int meters)? onOdometer,
  }) async {
    configurationReads++;
    return configuration;
  }

  @override
  Future<List<int>> readHistoryRecord(List<int> selector) {
    throw UnsupportedError('Diagnostics are disabled in this test.');
  }

  @override
  Future<int> readOdometer({required int? cachedMeters}) {
    throw UnsupportedError('Diagnostics are disabled in this test.');
  }

  @override
  void reset() {}

  @override
  bool wireRegionMatches(BikeConfiguration target) => true;

  @override
  Future<void> writeConfiguration(BikeConfiguration configuration) async {}
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

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
