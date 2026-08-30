import 'dart:async';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_session.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/exclusive_bluetooth_operation.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/domain/distance.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';
import 'package:superduper/src/user_facing_error.dart';

enum BikeHardwareTestPhase {
  idle,
  preparing,
  scanning,
  connecting,
  exercising,
  waitingForPowerOff,
  waitingForPowerOn,
  restoring,
  passed,
  failed,
  cancelled,
}

enum BikeHardwareTestLogStatus { passed, warning, failed }

final class BikeHardwareTestLogEntry {
  const BikeHardwareTestLogEntry({
    required this.recordedAt,
    required this.status,
    required this.label,
    required this.detail,
  });

  final DateTime recordedAt;
  final BikeHardwareTestLogStatus status;
  final String label;
  final String detail;
}

final class BikeHardwareTestTraceEntry {
  const BikeHardwareTestTraceEntry({
    required this.recordedAt,
    required this.event,
    required this.detail,
  });

  final DateTime recordedAt;
  final String event;
  final String detail;
}

final class BikeHardwareTestState {
  const BikeHardwareTestState({
    required this.phase,
    required this.title,
    required this.detail,
    this.log = const [],
  });

  const BikeHardwareTestState.idle()
    : phase = BikeHardwareTestPhase.idle,
      title = 'Ready for a real-bike test',
      detail = 'Keep the bike stationary with the rear wheel clear. Close any other app that may connect to it.',
      log = const [];

  final BikeHardwareTestPhase phase;
  final String title;
  final String detail;
  final List<BikeHardwareTestLogEntry> log;

  bool get isRunning => switch (phase) {
    BikeHardwareTestPhase.preparing ||
    BikeHardwareTestPhase.scanning ||
    BikeHardwareTestPhase.connecting ||
    BikeHardwareTestPhase.exercising ||
    BikeHardwareTestPhase.waitingForPowerOff ||
    BikeHardwareTestPhase.waitingForPowerOn ||
    BikeHardwareTestPhase.restoring => true,
    _ => false,
  };
}

typedef _BikeReleaseResult = ({
  bool settingsRestored,
  bool autoConnectResumed,
});

final class BikeHardwareTestController {
  BikeHardwareTestController({
    required this.transport,
    required this.permissions,
    required this.activeBikeCoordinator,
    this.scanDuration = const Duration(seconds: 8),
    this.notificationWait = const Duration(seconds: 8),
    this.reconnectDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    this.stepTimeout = const Duration(seconds: 75),
    this.cleanupTimeout = const Duration(seconds: 20),
  });

  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final ActiveBikeCoordinator activeBikeCoordinator;
  final Duration scanDuration;
  final Duration notificationWait;
  final List<Duration> reconnectDelays;
  final Duration stepTimeout;
  final Duration cleanupTimeout;
  late final ExclusiveBluetoothOperation _exclusiveBluetooth =
      ExclusiveBluetoothOperation(
        transport: transport,
        permissions: permissions,
        activeBikeCoordinator: activeBikeCoordinator,
      );
  final Signal<BikeHardwareTestState> _state = signal(
    const BikeHardwareTestState.idle(),
    options: const SignalOptions(name: 'bikeHardwareTest.state'),
  );
  final List<BikeHardwareTestTraceEntry> _trace = [];

  BikeSession? _session;
  EffectCleanup? _sessionStateCleanup;
  BikeConfiguration? _originalConfiguration;
  var _generation = 0;
  DateTime? _startedAt;
  var _traceTruncated = false;
  var _disposed = false;
  var _foreground = true;
  var _powerCycleInterrupted = false;
  Completer<void>? _foregroundResume;
  Future<_BikeReleaseResult>? _releaseFuture;

  ReadonlySignal<BikeHardwareTestState> get state => _state.readonly();

  void setForeground(bool foreground) {
    if (_disposed || foreground == _foreground) {
      return;
    }
    _foreground = foreground;
    if (!foreground) {
      final phase = _state.peek().phase;
      if (phase == BikeHardwareTestPhase.waitingForPowerOff ||
          phase == BikeHardwareTestPhase.waitingForPowerOn) {
        _powerCycleInterrupted = true;
      }
      _foregroundResume = Completer<void>();
      _addTrace('test.lifecycle', 'The app left the foreground.');
      return;
    }
    _addTrace('test.lifecycle', 'The app returned to the foreground.');
    final resume = _foregroundResume;
    _foregroundResume = null;
    if (resume != null && !resume.isCompleted) {
      resume.complete();
    }
  }

  String createReport({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String operatingSystemVersion,
    DateTime? generatedAt,
  }) {
    final current = _state.peek();
    final generated = (generatedAt ?? DateTime.now()).toUtc();
    final report = StringBuffer()
      ..writeln('SUPERDUPER BIKE TEST REPORT')
      ..writeln('Report format: 1')
      ..writeln('Generated: ${generated.toIso8601String()}')
      ..writeln(
        'Started: ${_startedAt?.toUtc().toIso8601String() ?? 'unknown'}',
      )
      ..writeln('Result: ${current.phase.name.toUpperCase()}')
      ..writeln('App: $appVersion ($buildNumber)')
      ..writeln('Platform: $platform')
      ..writeln('OS: ${operatingSystemVersion.replaceAll('\n', ' ')}')
      ..writeln()
      ..writeln(
        'PRIVACY: This report can contain the bike BLE identifier and module serial. Review it before sharing.',
      )
      ..writeln()
      ..writeln('SUMMARY');
    for (final entry in current.log) {
      report
        ..writeln(
          '${entry.recordedAt.toUtc().toIso8601String()} '
          '[${_logStatusLabel(entry.status)}] ${entry.label}',
        )
        ..writeln('  ${entry.detail.replaceAll('\n', '\n  ')}');
    }
    report
      ..writeln()
      ..writeln('BLE TRACE');
    for (final entry in _trace) {
      report.writeln(
        '${entry.recordedAt.toUtc().toIso8601String()} '
        '${entry.event} ${entry.detail}',
      );
    }
    if (_traceTruncated) {
      report.writeln(
        'TRACE TRUNCATED: only the newest $_maximumTraceEntries entries are included.',
      );
    }
    return report.toString();
  }

  Future<void> start() async {
    if (_disposed || _state.peek().isRunning) {
      return;
    }
    final generation = ++_generation;
    _startedAt = DateTime.now();
    _trace.clear();
    _traceTruncated = false;
    _powerCycleInterrupted = false;
    _addTrace('test.start', 'Beginning hardware verification.');
    _state.value = const BikeHardwareTestState(
      phase: BikeHardwareTestPhase.preparing,
      title: 'Preparing the test',
      detail: 'Pausing normal auto-connect so the test has one BLE owner.',
    );
    try {
      await _run(generation);
    } on _BikeHardwareTestCancelled {
      return;
    } on Object catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      _addTrace(
        'test.error',
        error.toString().replaceAll('\n', ' '),
      );
      _addLog(
        BikeHardwareTestLogStatus.failed,
        'Test stopped',
        _friendlyError(error),
      );
      _publish(
        BikeHardwareTestPhase.restoring,
        'Restoring the bike',
        'The test failed. Restoring the starting settings before releasing Bluetooth.',
      );
      final release = await _releaseBike(restore: true);
      if (_isCurrent(generation)) {
        _publish(
          BikeHardwareTestPhase.failed,
          'Test failed',
          release.autoConnectResumed
              ? 'Normal app control resumed. Review the failed step and any cleanup warning below.'
              : 'Normal app control could not resume. Review the failed step and cleanup warning below.',
        );
      }
    }
  }

  Future<void> cancel() async {
    if (_disposed ||
        !_state.peek().isRunning ||
        _state.peek().phase == BikeHardwareTestPhase.restoring) {
      return;
    }
    _generation++;
    _publish(
      BikeHardwareTestPhase.restoring,
      'Stopping the test',
      'Restoring the starting settings when the bike is reachable.',
    );
    final release = await _releaseBike(restore: true);
    if (!_disposed) {
      _publish(
        BikeHardwareTestPhase.cancelled,
        'Test stopped',
        switch (release) {
          (settingsRestored: true, autoConnectResumed: true) => 'Starting settings were restored and normal app auto-connect resumed.',
          (settingsRestored: false, autoConnectResumed: true) => 'Normal app auto-connect resumed, but the test could not restore every starting setting.',
          (settingsRestored: true, autoConnectResumed: false) => 'Starting settings were restored, but normal app auto-connect could not resume.',
          _ => 'The test could not restore every setting or resume normal app auto-connect.',
        },
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _generation++;
    await _releaseBike(restore: true);
    _disposed = true;
    _state.dispose();
  }

  Future<void> _run(int generation) async {
    final access = await _exclusiveBluetooth.acquire(
      requestPermission: true,
      adapterTimeout: const Duration(seconds: 5),
    );
    _checkCurrent(generation);
    if (access.permission != BluetoothPermissionState.granted) {
      throw BikeHardwareTestFailure(
        'Bluetooth permission is ${access.permission.name}.',
      );
    }
    if (access.scanPrerequisite ==
        BluetoothScanPrerequisite.locationServicesDisabled) {
      throw const BikeHardwareTestFailure(
        'Turn on Location Services before scanning. Android 10 and 11 require it for nearby Bluetooth discovery.',
      );
    }
    if (access.adapter != BikeAdapterState.on) {
      throw BikeHardwareTestFailure(
        'Bluetooth adapter is ${access.adapter.name}.',
      );
    }
    _addTrace(
      'bluetooth.ready',
      'Permission granted; adapter ${access.adapter.name}.',
    );
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Bluetooth access',
      'Permission granted and adapter powered on.',
    );

    final candidate = await _scanUntilFound(generation);
    _checkCurrent(generation);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Discovery',
      '${candidate.name} at ${candidate.rssi} dBm (${candidate.deviceId}).',
    );
    _addTrace(
      'scan.selected',
      '${candidate.name} ${candidate.deviceId} RSSI ${candidate.rssi} serial ${candidate.moduleSerial ?? 'unavailable'}',
    );
    if (candidate.moduleSerial case final serial?) {
      _addLog(BikeHardwareTestLogStatus.passed, 'Module serial', serial);
    } else {
      _addLog(
        BikeHardwareTestLogStatus.warning,
        'Module serial',
        'The Bluetooth advertisement did not include the module serial.',
      );
    }

    _publish(
      BikeHardwareTestPhase.connecting,
      'Connecting to ${candidate.name}',
      'Discovering GATT, authenticating, and reading bike information.',
    );
    final connection = _DiagnosticBikeConnection(
      transport.openConnection(candidate.deviceId),
      onTrace: _addTrace,
    );
    var versionReads = 0;
    var odometerReads = 0;
    var sawAuthenticationState = false;
    final session = BikeSession(
      connection: connection,
      preferredRegion: _preferredRegion(candidate.deviceId),
      setOnConnect: const BikeControlPatch(),
      protocol: BikeProtocolVersion.fromAdvertisedName(candidate.name)!,
      onVersionsRead: (_) async {
        versionReads++;
      },
      onOdometerRead: (_) async {
        odometerReads++;
      },
      reconnectDelays: reconnectDelays,
    );
    _session = session;
    _sessionStateCleanup = session.state.subscribe((sessionState) {
      _addTrace('session.state', _sessionStateTraceName(sessionState));
      if (sessionState is SessionAuthenticating) {
        sawAuthenticationState = true;
      }
      _publishSessionProgress(sessionState);
    });
    await session.connect();
    await _waitForReady(session, generation, timeout: stepTimeout);
    _checkCurrent(generation);

    _expect(connection.gattDiscoveries >= 1, 'GATT discovery did not run.');
    _expect(
      sawAuthenticationState && connection.authenticationWrites >= 1,
      'The authentication challenge-response path was not completed.',
    );
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'First connection and authentication',
      'Required GATT services found and challenge response accepted.',
    );

    final protocol = session.protocolVersion;
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Protocol',
      protocol.name.toUpperCase(),
    );

    final versions = session.versions.peek();
    _expect(
      versions != null && versionReads >= 1,
      'The complete bike version set could not be read.',
    );
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Version information',
      _formatVersions(versions!),
    );
    _addTrace('bike.versions', _formatVersions(versions));

    final odometer = session.odometerMeters.peek();
    _expect(
      odometer != null && odometerReads >= 1,
      'The bike odometer could not be read.',
    );
    final formattedOdometer = formatOdometerDistance(odometer!);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Odometer',
      '$formattedOdometer ($odometer meters).',
    );
    _addTrace('bike.odometer', '$odometer meters; $formattedOdometer');

    final initial = session.observed.peek();
    _expect(initial != null, 'The initial configuration was not read.');
    _originalConfiguration = initial;
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Initial configuration',
      _formatConfiguration(initial!, protocol: protocol),
    );
    _addTrace(
      'bike.configuration.initial',
      _formatConfiguration(initial, protocol: protocol),
    );
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Notification subscription',
      'The telemetry characteristic accepted notifications.',
    );

    _publish(
      BikeHardwareTestPhase.exercising,
      'Testing every setting',
      'Each value is changed after the bike acknowledges the write, then restored before the next setting.',
    );
    await _testSettingToggles(session, initial, generation);

    if (connection.telemetryPackets == 0) {
      _publish(
        BikeHardwareTestPhase.exercising,
        'Waiting for live bike data',
        'The settings passed. Listening briefly for an unsolicited bike update.',
      );
      await _waitFor(
        generation,
        () => connection.telemetryPackets > 0,
        timeout: notificationWait,
      );
    }
    if (connection.telemetryPackets > 0) {
      _addLog(
        BikeHardwareTestLogStatus.passed,
        'Live notification',
        'Received ${connection.telemetryPackets} live telemetry packet${connection.telemetryPackets == 1 ? '' : 's'} after subscribing.',
      );
    } else {
      _addLog(
        BikeHardwareTestLogStatus.warning,
        'Live notification',
        'The subscription succeeded, but no unsolicited packet arrived within ${notificationWait.inSeconds} seconds.',
      );
    }

    final setOnConnectTarget = initial.copyWith(
      light: true,
      assist: (initial.assist + 1) % 5,
    );
    _addTrace(
      'bike.configuration.set_on_connect_target',
      _formatConfiguration(setOnConnectTarget, protocol: protocol),
    );
    await session.setLight(setOnConnectTarget.light);
    _checkCurrent(generation);
    await session.setAssist(setOnConnectTarget.assist);
    _checkCurrent(generation);
    session.updateSetOnConnect(
      BikeControlPatch(
        light: true,
        assist: setOnConnectTarget.assist,
      ),
    );
    await _waitForReady(session, generation, timeout: stepTimeout);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Set on connect setup',
      'Light and assist are enabled; mode is deliberately left unchanged.',
    );

    final disconnectsBefore = connection.disconnectEvents;
    final connectsBefore = connection.connectCalls;
    final authWritesBefore = connection.authenticationWrites;
    final discoveriesBefore = connection.gattDiscoveries;
    final configWritesBefore = connection.configurationWrites.length;
    final versionReadsBefore = versionReads;
    final odometerReadsBefore = odometerReads;

    _publish(
      BikeHardwareTestPhase.waitingForPowerOff,
      'Turn the bike OFF',
      'The test is waiting for the BLE disconnect. It will tell you when to turn the bike back on.',
    );
    _addTrace('test.prompt', 'Waiting for the bike to power off.');
    await _waitForPowerOff(connection, generation, disconnectsBefore);
    _checkCurrent(generation);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Power-off detection',
      'The production session observed the bike disconnect.',
    );

    _publish(
      BikeHardwareTestPhase.waitingForPowerOn,
      'Now turn the bike ON',
      'Waiting for automatic reconnect, authentication, version refresh, and Set on connect.',
    );
    _addTrace('test.prompt', 'Waiting for the bike to power on.');
    await _waitForReady(session, generation, timeout: stepTimeout);
    _checkCurrent(generation);

    _expect(
      connection.connectCalls > connectsBefore,
      'The session did not make a reconnect attempt.',
    );
    _expect(
      connection.gattDiscoveries > discoveriesBefore,
      'GATT was not rediscovered after reconnect.',
    );
    _expect(
      connection.authenticationWrites > authWritesBefore,
      'Authentication did not run again after reconnect.',
    );
    _expect(
      versionReads > versionReadsBefore && session.versions.peek() != null,
      'Version information was not refreshed after reconnect.',
    );
    _expect(
      odometerReads > odometerReadsBefore &&
          session.odometerMeters.peek() != null,
      'The odometer was not refreshed after reconnect.',
    );
    _expect(
      connection.configurationWrites.length > configWritesBefore,
      'No configuration was written after reconnect.',
    );
    final reconnected = session.observed.peek();
    _expect(
      reconnected != null,
      'No configuration was observed after reconnect.',
    );
    _expect(
      reconnected!.light == setOnConnectTarget.light &&
          reconnected.assist == setOnConnectTarget.assist,
      'The Set on connect light and assist values were not applied.',
    );
    final expectedPacket = BikeProtocol.forVersion(
      session.protocolVersion,
    ).encodeConfiguration(reconnected);
    final writtenPacket = connection.configurationWrites.last;
    _expect(
      _listsEqual(writtenPacket, expectedPacket),
      'The reconnect configuration packet did not match the acknowledged state.',
    );
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Reconnect and Set on connect',
      'Reauthenticated, reread versions, wrote ${_hex(writtenPacket)}, and applied Set on connect values while preserving mode ${reconnected.mode}.',
    );

    _publish(
      BikeHardwareTestPhase.restoring,
      'Restoring the bike',
      'Returning the physical bike to the configuration it had before the test.',
    );
    final release = await _releaseBike(restore: true);
    _checkCurrent(generation);
    if (!release.settingsRestored || !release.autoConnectResumed) {
      _publish(
        BikeHardwareTestPhase.failed,
        'Checks passed, cleanup incomplete',
        switch (release) {
          (settingsRestored: false, autoConnectResumed: true) => 'The bike passed its checks, but its starting settings could not be fully restored.',
          (settingsRestored: true, autoConnectResumed: false) => 'The bike passed its checks, but normal app auto-connect could not resume.',
          _ => 'The bike passed its checks, but settings restoration and normal auto-connect were incomplete.',
        },
      );
      _addTrace('test.complete', 'Hardware checks passed; cleanup incomplete.');
      return;
    }
    _publish(
      BikeHardwareTestPhase.passed,
      'All hardware checks passed',
      'The starting bike settings were restored and normal app auto-connect has resumed.',
    );
    _addTrace('test.complete', 'All hardware checks passed.');
  }

  Future<DiscoveredBike> _scanUntilFound(int generation) async {
    var firstAttempt = true;
    while (true) {
      _checkCurrent(generation);
      _publish(
        BikeHardwareTestPhase.scanning,
        firstAttempt ? 'Looking for a bike' : 'Turn a bike ON',
        firstAttempt
            ? 'Scanning for compatible bike advertisements.'
            : 'No bike was found. Scanning continues automatically.',
      );
      _addTrace('scan.start', 'Timeout ${scanDuration.inSeconds}s.');
      DiscoveredBike? found;
      StreamSubscription<List<DiscoveredBike>>? subscription;
      var acceptResults = false;
      try {
        subscription = transport.scanResults.listen((results) {
          if (!acceptResults) {
            return;
          }
          for (final result in results) {
            if (BikeProtocolVersion.fromAdvertisedName(result.name) != null) {
              found ??= result;
              break;
            }
          }
        });
        await Future<void>.delayed(Duration.zero);
        acceptResults = true;
        await transport.startScan(timeout: scanDuration);
        _checkCurrent(generation);
        final deadline = DateTime.now().add(scanDuration);
        while (found == null && DateTime.now().isBefore(deadline)) {
          _checkCurrent(generation);
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      } finally {
        await transport.stopScan();
        await subscription?.cancel();
      }
      _checkCurrent(generation);
      if (found case final candidate?) {
        return candidate;
      }
      _addTrace('scan.empty', 'No supported bike found.');
      firstAttempt = false;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _testSettingToggles(
    BikeSession session,
    BikeConfiguration initial,
    int generation,
  ) async {
    final light = await session.setLight(!initial.light);
    _checkCurrent(generation);
    _expect(light.light != initial.light, 'Light did not toggle.');
    await session.setLight(initial.light);
    _checkCurrent(generation);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Light toggle',
      'Changed to ${light.light ? 'on' : 'off'}, acknowledged, and restored.',
    );

    final nextMode = (initial.mode + 1) % BikeControlValues.modeCount;
    final mode = await session.setMode(nextMode);
    _checkCurrent(generation);
    _expect(mode.mode == nextMode, 'Mode did not change to $nextMode.');
    await session.setMode(initial.mode);
    _checkCurrent(generation);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Mode toggle',
      'Changed to $nextMode, acknowledged, and restored to ${initial.mode}.',
    );

    final nextAssist = (initial.assist + 1) % 5;
    final assist = await session.setAssist(nextAssist);
    _checkCurrent(generation);
    _expect(
      assist.assist == nextAssist,
      'Assist did not change to $nextAssist.',
    );
    await session.setAssist(initial.assist);
    _checkCurrent(generation);
    _addLog(
      BikeHardwareTestLogStatus.passed,
      'Assist toggle',
      'Changed to $nextAssist, acknowledged, and restored to ${initial.assist}.',
    );
  }

  Future<void> _waitForReady(
    BikeSession session,
    int generation, {
    required Duration timeout,
  }) async {
    var remaining = timeout;
    while (true) {
      _checkCurrent(generation);
      await _waitForForeground(generation);
      if (_powerCycleInterrupted &&
          _state.peek().phase == BikeHardwareTestPhase.waitingForPowerOn) {
        throw const BikeHardwareTestFailure(
          'The app left the foreground during the power-cycle check. Run the test again and keep Superduper open.',
        );
      }
      final current = session.state.peek();
      if (current is SessionReady) {
        return;
      }
      if (current is SessionFailed) {
        throw current.failure;
      }
      if (current is SessionDisposed ||
          current is SessionDisconnected && current.manuallyPaused) {
        throw const BikeHardwareTestFailure(
          'The bike session stopped before becoming ready.',
        );
      }
      if (remaining <= Duration.zero) {
        throw BikeHardwareTestFailure(
          'The bike did not become ready within ${timeout.inSeconds} seconds.',
        );
      }
      final slice = remaining < const Duration(milliseconds: 150)
          ? remaining
          : const Duration(milliseconds: 150);
      final started = DateTime.now();
      await Future<void>.delayed(slice);
      if (_foreground) {
        remaining -= DateTime.now().difference(started);
      }
    }
  }

  Future<void> stopWithoutRestoring() async {
    if (_disposed || _state.peek().phase != BikeHardwareTestPhase.restoring) {
      return;
    }
    _generation++;
    try {
      await _session?.dispose();
    } on Object {
      // The release path still returns Bluetooth ownership to the app.
    }
    final release = await _releaseBike(restore: false);
    if (!_disposed) {
      _publish(
        BikeHardwareTestPhase.cancelled,
        'Test stopped without restoring',
        release.autoConnectResumed
            ? 'Normal app auto-connect resumed. The bike may still have settings changed by the test.'
            : 'The bike may still have test settings, and normal app auto-connect could not resume.',
      );
    }
  }

  Future<void> _waitForPowerOff(
    _DiagnosticBikeConnection connection,
    int generation,
    int disconnectsBefore,
  ) async {
    while (connection.disconnectEvents <= disconnectsBefore) {
      _checkCurrent(generation);
      await _waitForForeground(generation);
      if (_powerCycleInterrupted) {
        throw const BikeHardwareTestFailure(
          'The app left the foreground while checking for bike power-off. Run the test again and keep Superduper open.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    _checkCurrent(generation);
    if (_powerCycleInterrupted) {
      throw const BikeHardwareTestFailure(
        'The app left the foreground while checking for bike power-off. Run the test again and keep Superduper open.',
      );
    }
  }

  Future<void> _waitFor(
    int generation,
    bool Function() condition, {
    Duration? timeout,
  }) async {
    _checkCurrent(generation);
    var remaining = timeout;
    while (!condition()) {
      _checkCurrent(generation);
      await _waitForForeground(generation);
      if (remaining != null && remaining <= Duration.zero) {
        return;
      }
      final slice =
          remaining != null && remaining < const Duration(milliseconds: 150)
          ? remaining
          : const Duration(milliseconds: 150);
      final started = DateTime.now();
      await Future<void>.delayed(slice);
      if (_foreground && remaining != null) {
        remaining -= DateTime.now().difference(started);
      }
    }
    _checkCurrent(generation);
  }

  Future<void> _waitForForeground(int generation) async {
    while (!_foreground) {
      final resume = _foregroundResume;
      if (resume == null) {
        return;
      }
      await resume.future;
      _checkCurrent(generation);
    }
  }

  Future<_BikeReleaseResult> _releaseBike({required bool restore}) {
    if (_releaseFuture case final pending?) {
      return pending;
    }
    final pending = _performReleaseBike(restore: restore);
    _releaseFuture = pending;
    unawaited(
      pending.then<void>(
        (_) {
          if (identical(_releaseFuture, pending)) {
            _releaseFuture = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_releaseFuture, pending)) {
            _releaseFuture = null;
          }
        },
      ),
    );
    return pending;
  }

  Future<_BikeReleaseResult> _performReleaseBike({
    required bool restore,
  }) async {
    final session = _session;
    final original = _originalConfiguration;
    var settingsRestored = !restore || session == null || original == null;
    if (restore && session != null && original != null) {
      try {
        final restorable = await _waitUntilRestorable(session);
        if (restorable) {
          session.updateSetOnConnect(const BikeControlPatch());
          var current = session.pending.peek() ?? session.observed.peek();
          if (current?.light != original.light) {
            current = await session.setLight(original.light);
          }
          if (current?.mode != original.mode) {
            current = await session.setMode(original.mode);
          }
          if (current?.assist != original.assist) {
            await session.setAssist(original.assist);
          }
          _addLog(
            BikeHardwareTestLogStatus.passed,
            'Cleanup',
            'Restored ${_formatConfiguration(original, protocol: session.protocolVersion)}.',
          );
          settingsRestored = true;
        } else {
          _addLog(
            BikeHardwareTestLogStatus.warning,
            'Cleanup',
            'The bike was unreachable, so the test could not restore its starting settings.',
          );
          settingsRestored = false;
        }
      } on Object catch (error) {
        settingsRestored = false;
        _addLog(
          BikeHardwareTestLogStatus.warning,
          'Cleanup',
          'Could not restore every starting value: ${_friendlyError(error)}',
        );
      }
    }

    _sessionStateCleanup?.call();
    _sessionStateCleanup = null;
    _session = null;
    _originalConfiguration = null;
    if (session != null) {
      try {
        await session.dispose();
      } on Object {
        // Normal app control must still resume after a failed test disconnect.
      }
    }
    var autoConnectResumed = true;
    if (_exclusiveBluetooth.isAcquired) {
      try {
        await _exclusiveBluetooth.release();
        _addTrace('test.release', 'Normal auto-connect resumed.');
      } on Object catch (error) {
        autoConnectResumed = false;
        _addLog(
          BikeHardwareTestLogStatus.warning,
          'Normal connection resume',
          'The test released Bluetooth, but automatic connection could not resume: ${_friendlyError(error)}',
        );
        _addTrace('test.release', 'Normal auto-connect could not resume.');
      }
    } else {
      _addTrace('test.release', 'No paused auto-connect session to resume.');
    }
    return (
      settingsRestored: settingsRestored,
      autoConnectResumed: autoConnectResumed,
    );
  }

  Future<bool> _waitUntilRestorable(BikeSession session) async {
    final deadline = DateTime.now().add(cleanupTimeout);
    var retryAttempted = false;
    while (true) {
      final current = session.state.peek();
      if (session.canChangeConfiguration && current is SessionReady) {
        return true;
      }
      if (current is SessionDisposed ||
          current is SessionDisconnected && current.manuallyPaused ||
          current is SessionFailed && !current.canRetry) {
        return false;
      }
      if (current is SessionFailed && !retryAttempted) {
        retryAttempted = true;
        try {
          await session.retry();
        } on Object {
          // The resulting session state determines whether cleanup can proceed.
        }
        continue;
      }
      if (!DateTime.now().isBefore(deadline)) {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  BikeRegion? _preferredRegion(String deviceId) {
    for (final saved in activeBikeCoordinator.bikes.peek()) {
      if (saved.bike.deviceId == deviceId) {
        return saved.bike.region;
      }
    }
    return null;
  }

  void _publishSessionProgress(BikeSessionState sessionState) {
    final phase = _state.peek().phase;
    if (phase != BikeHardwareTestPhase.connecting &&
        phase != BikeHardwareTestPhase.waitingForPowerOn) {
      return;
    }
    final (title, detail) = switch (sessionState) {
      SessionConnecting() => (
        phase == BikeHardwareTestPhase.waitingForPowerOn
            ? 'Bike found, connecting'
            : 'Connecting to the bike',
        'Opening the Bluetooth connection.',
      ),
      SessionDiscovering() => (
        'Checking bike services',
        'Discovering the required Bluetooth characteristics.',
      ),
      SessionAuthenticating() => (
        'Authenticating the bike',
        'Completing the challenge-response handshake.',
      ),
      SessionConnected() || SessionSynchronizing() => (
        'Applying bike settings',
        'Reading versions and applying saved settings.',
      ),
      SessionReconnecting(:final retryAfter) => (
        'Turn the bike ON',
        'No connection yet. Trying again in ${retryAfter.inSeconds} seconds.',
      ),
      _ => (_state.peek().title, _state.peek().detail),
    };
    _publish(phase, title, detail);
  }

  void _publish(BikeHardwareTestPhase phase, String title, String detail) {
    if (_disposed) {
      return;
    }
    _state.value = BikeHardwareTestState(
      phase: phase,
      title: title,
      detail: detail,
      log: _state.peek().log,
    );
  }

  String _friendlyError(Object error) {
    return userFacingError(error, context: UserErrorContext.hardwareTest);
  }

  void _addLog(BikeHardwareTestLogStatus status, String label, String detail) {
    if (_disposed) {
      return;
    }
    final current = _state.peek();
    _state.value = BikeHardwareTestState(
      phase: current.phase,
      title: current.title,
      detail: current.detail,
      log: List.unmodifiable([
        ...current.log,
        BikeHardwareTestLogEntry(
          recordedAt: DateTime.now(),
          status: status,
          label: label,
          detail: detail,
        ),
      ]),
    );
  }

  void _addTrace(String event, String detail) {
    if (_disposed) {
      return;
    }
    if (_trace.length >= _maximumTraceEntries) {
      _traceTruncated = true;
      _trace.removeAt(0);
    }
    _trace.add(
      BikeHardwareTestTraceEntry(
        recordedAt: DateTime.now(),
        event: event,
        detail: detail.replaceAll('\n', ' '),
      ),
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _checkCurrent(int generation) {
    if (!_isCurrent(generation)) {
      throw const _BikeHardwareTestCancelled();
    }
  }

  void _expect(bool condition, String message) {
    if (!condition) {
      throw BikeHardwareTestFailure(message);
    }
  }

  static String _formatConfiguration(
    BikeConfiguration value, {
    required BikeProtocolVersion? protocol,
  }) {
    final settings =
        'light ${value.light ? 'on' : 'off'}, mode ${value.mode}, assist ${value.assist}';
    return protocol == BikeProtocolVersion.v1
        ? '$settings, ${value.region.label}'
        : settings;
  }

  static String _sessionStateTraceName(BikeSessionState state) {
    return switch (state) {
      SessionIdle() => 'idle',
      SessionConnecting() => 'connecting',
      SessionDiscovering() => 'discovering',
      SessionAuthenticating() => 'authenticating',
      SessionConnected() => 'connected',
      SessionSynchronizing() => 'synchronizing',
      SessionReady() => 'ready',
      SessionReconnecting() => 'reconnecting',
      SessionDisconnected() => 'disconnected',
      SessionFailed() => 'failed',
      SessionDisposed() => 'disposed',
    };
  }

  static String _formatVersions(BikeVersionInfo value) {
    return 'display ${value.firmwareRevision}, hardware ${value.hardwareRevision}, software ${value.softwareRevision}, STM ${_hexInt(value.stmFirmwareVersion, 6)}, motor ${_hexInt(value.motorControllerVersion, 8)}, BMS ${_hexInt(value.bmsVersion, 8)}';
  }

  static String _hexInt(int value, int digits) =>
      '0x${value.toRadixString(16).padLeft(digits, '0')}';

  static String _hex(List<int> value) =>
      value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

  static bool _listsEqual(List<int> left, List<int> right) {
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

  static String _logStatusLabel(BikeHardwareTestLogStatus status) {
    return switch (status) {
      BikeHardwareTestLogStatus.passed => 'PASS',
      BikeHardwareTestLogStatus.warning => 'NOTE',
      BikeHardwareTestLogStatus.failed => 'FAIL',
    };
  }

  static const _maximumTraceEntries = 2000;
}

final class _DiagnosticBikeConnection implements BikeConnection {
  _DiagnosticBikeConnection(this._delegate, {required this.onTrace});

  final BikeConnection _delegate;
  final void Function(String event, String detail) onTrace;
  final List<List<int>> configurationWrites = [];
  int connectCalls = 0;
  int disconnectEvents = 0;
  int gattDiscoveries = 0;
  int authenticationWrites = 0;
  int telemetryPackets = 0;

  @override
  String get deviceId => _delegate.deviceId;

  @override
  Stream<BikeConnectionState> get states => _delegate.states.map((state) {
    if (state == BikeConnectionState.disconnected) {
      disconnectEvents++;
    }
    onTrace('connection.state', state.name);
    return state;
  });

  @override
  Future<void> connect() async {
    connectCalls++;
    final attempt = connectCalls;
    onTrace('connection.connect', 'Attempt $attempt started.');
    try {
      await _delegate.connect();
      onTrace('connection.connect', 'Attempt $attempt succeeded.');
    } on Object catch (error) {
      onTrace('connection.connect', 'Attempt $attempt failed: $error');
      rethrow;
    }
  }

  @override
  Future<void> discoverRequiredGatt() async {
    gattDiscoveries++;
    final attempt = gattDiscoveries;
    onTrace('gatt.discover', 'Attempt $attempt started.');
    try {
      await _delegate.discoverRequiredGatt();
      onTrace('gatt.discover', 'Attempt $attempt succeeded.');
    } on Object catch (error) {
      onTrace('gatt.discover', 'Attempt $attempt failed: $error');
      rethrow;
    }
  }

  @override
  bool hasCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _delegate.hasCharacteristic(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    onTrace('gatt.read', '$serviceUuid/$characteristicUuid started.');
    try {
      final value = await _delegate.readCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      onTrace(
        'gatt.read',
        '$serviceUuid/$characteristicUuid ${_traceValue(characteristicUuid, value)}',
      );
      return value;
    } on Object catch (error) {
      onTrace('gatt.read', '$serviceUuid/$characteristicUuid failed: $error');
      rethrow;
    }
  }

  @override
  Future<void> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  }) async {
    if (serviceUuid == BikeGatt.authenticationService &&
        characteristicUuid == BikeGatt.authenticationResponse) {
      authenticationWrites++;
    }
    if (serviceUuid == BikeGatt.metricsService &&
        characteristicUuid == BikeGatt.stateRegister) {
      configurationWrites.add(List<int>.unmodifiable(value));
    }
    onTrace(
      'gatt.write',
      '$serviceUuid/$characteristicUuid ${_traceValue(characteristicUuid, value)}',
    );
    try {
      await _delegate.writeCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: value,
      );
      onTrace('gatt.write', '$serviceUuid/$characteristicUuid succeeded.');
    } on Object catch (error) {
      onTrace('gatt.write', '$serviceUuid/$characteristicUuid failed: $error');
      rethrow;
    }
  }

  @override
  Stream<List<int>> characteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _delegate
        .characteristicNotifications(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
        )
        .map((packet) {
          if (serviceUuid == BikeGatt.metricsService &&
              characteristicUuid == BikeGatt.telemetry) {
            telemetryPackets++;
          }
          onTrace(
            'gatt.notification',
            '$serviceUuid/$characteristicUuid ${BikeHardwareTestController._hex(packet)}',
          );
          return packet;
        });
  }

  @override
  Future<void> setCharacteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    onTrace(
      'gatt.notify',
      '$serviceUuid/$characteristicUuid ${enabled ? 'enable' : 'disable'} started.',
    );
    try {
      await _delegate.setCharacteristicNotifications(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        enabled: enabled,
      );
      onTrace(
        'gatt.notify',
        '$serviceUuid/$characteristicUuid ${enabled ? 'enabled' : 'disabled'}.',
      );
    } on Object catch (error) {
      onTrace('gatt.notify', '$serviceUuid/$characteristicUuid failed: $error');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    onTrace('connection.disconnect', 'Requested.');
    await _delegate.disconnect();
  }

  @override
  Future<void> dispose() async {
    onTrace('connection.dispose', 'Started.');
    await _delegate.dispose();
    onTrace('connection.dispose', 'Completed.');
  }

  static String _traceValue(String characteristicUuid, List<int> value) {
    if (characteristicUuid == BikeGatt.authenticationChallenge ||
        characteristicUuid == BikeGatt.authenticationResponse) {
      return '<redacted ${value.length}-byte authentication value>';
    }
    return BikeHardwareTestController._hex(value);
  }
}

final class _BikeHardwareTestCancelled implements Exception {
  const _BikeHardwareTestCancelled();
}
