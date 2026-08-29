import 'dart:async';
import 'dart:convert';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';

sealed class BikeSessionFailure implements Exception {
  const BikeSessionFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class BikeSessionTransportFailure extends BikeSessionFailure {
  const BikeSessionTransportFailure(Object cause)
    : super('Bike communication failed: $cause');
}

final class BikeBluetoothUnavailable extends BikeSessionFailure {
  const BikeBluetoothUnavailable(super.message, {required this.canRetry});

  final bool canRetry;
}

final class BikeCommandTimedOut extends BikeSessionFailure {
  const BikeCommandTimedOut(String operation) : super('$operation timed out.');
}

final class BikeSessionDisposedFailure extends BikeSessionFailure {
  const BikeSessionDisposedFailure() : super('The bike session is disposed.');
}

final class BikeSessionNotReady extends BikeSessionFailure {
  const BikeSessionNotReady() : super('The bike is not ready for controls.');
}

final class BikeAuthenticationFailed extends BikeSessionFailure {
  const BikeAuthenticationFailed(String detail)
    : super('Bike authentication failed. $detail');
}

final class BikeProtocolNotSupported extends BikeSessionFailure {
  const BikeProtocolNotSupported(String detail)
    : super('The bike protocol is not supported. $detail');
}

sealed class BikeSessionState {
  const BikeSessionState();
}

final class SessionIdle extends BikeSessionState {
  const SessionIdle();
}

final class SessionConnecting extends BikeSessionState {
  const SessionConnecting();
}

final class SessionDiscovering extends BikeSessionState {
  const SessionDiscovering();
}

final class SessionConnected extends BikeSessionState {
  const SessionConnected();
}

final class SessionAuthenticating extends BikeSessionState {
  const SessionAuthenticating();
}

final class SessionSynchronizing extends BikeSessionState {
  const SessionSynchronizing({required this.attempt});

  final int attempt;
}

final class SessionReady extends BikeSessionState {
  const SessionReady({required this.configuration});

  final BikeConfiguration configuration;
}

final class SessionReconnecting extends BikeSessionState {
  const SessionReconnecting({
    required this.attempt,
    required this.retryAfter,
    required this.failure,
  });

  final int attempt;
  final Duration retryAfter;
  final BikeSessionFailure failure;
}

final class SessionDisconnected extends BikeSessionState {
  const SessionDisconnected({required this.manuallyPaused});

  final bool manuallyPaused;
}

final class SessionFailed extends BikeSessionState {
  const SessionFailed({required this.failure, required this.canRetry});

  final BikeSessionFailure failure;
  final bool canRetry;
}

final class SessionDisposed extends BikeSessionState {
  const SessionDisposed();
}

typedef VersionsRead = Future<void> Function(BikeVersionInfo versions);
typedef OdometerRead = Future<void> Function(int meters);

final class BikeSession {
  BikeSession({
    required this.connection,
    required BikeRegion? preferredRegion,
    required BikeControlPatch setOnConnect,
    required BikeProtocolVersion protocol,
    List<int> authenticationKey = BikeProtocol.defaultAuthenticationKey,
    VersionsRead? onVersionsRead,
    OdometerRead? onOdometerRead,
    this.readDiagnosticsOnConnect = true,
    Duration commandTimeout = const Duration(seconds: 15),
    Duration? pollInterval = const Duration(seconds: 30),
    List<Duration> reconnectDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    BikeProtocolDefinition? connectedProtocol,
  }) : _protocolVersion = protocol,
       // The public named parameter backs private mutable session state.
       // ignore: prefer_initializing_formals
       _preferredRegion = preferredRegion,
       _authenticationKey = List<int>.unmodifiable(authenticationKey),
       _nextConnectionIntent = setOnConnect,
       _connectionIntent = setOnConnect,
       // The public named parameter keeps the callback implementation private.
       // ignore: prefer_initializing_formals
       _onVersionsRead = onVersionsRead,
       // The public named parameter keeps the callback implementation private.
       // ignore: prefer_initializing_formals
       _onOdometerRead = onOdometerRead,
       // The public named parameter keeps command policy private.
       // ignore: prefer_initializing_formals
       _commandTimeout = commandTimeout,
       // The public named parameter keeps connection policy private.
       // ignore: prefer_initializing_formals
       _pollInterval = pollInterval,
       _reconnectDelays = List.unmodifiable(reconnectDelays) {
    _protocol =
        connectedProtocol ??
        BikeProtocol.connected(
          version: protocol,
          connection: connection,
          timed: _timed,
        );
    if (reconnectDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        reconnectDelays,
        'reconnectDelays',
        'Must not contain negative durations.',
      );
    }
    BikeProtocol.authenticationResponse(
      challenge: List<int>.filled(20, 0),
      key: _authenticationKey,
    );
    _connectionSubscription = connection.states.listen(_onConnectionState);
  }

  final BikeConnection connection;
  final VersionsRead? _onVersionsRead;
  final OdometerRead? _onOdometerRead;
  final bool readDiagnosticsOnConnect;
  final Duration _commandTimeout;
  final Duration? _pollInterval;
  final List<Duration> _reconnectDelays;
  final BikeProtocolVersion _protocolVersion;
  final List<int> _authenticationKey;
  late final BikeProtocolDefinition _protocol;
  final _SerialCommandQueue _commands = _SerialCommandQueue();
  final Signal<BikeSessionState> _state = signal(
    const SessionIdle(),
    options: const SignalOptions(name: 'bikeSession.state'),
  );
  final Signal<BikeConfiguration?> _observed = signal(
    null,
    options: const SignalOptions(name: 'bikeSession.observed'),
  );
  final Signal<BikeConfiguration?> _pending = signal(
    null,
    options: const SignalOptions(name: 'bikeSession.pending'),
  );
  final Signal<BikeVersionInfo?> _versions = signal(
    null,
    options: const SignalOptions(name: 'bikeSession.versions'),
  );
  final Signal<int?> _odometerMeters = signal(
    null,
    options: const SignalOptions(name: 'bikeSession.odometerMeters'),
  );

  late final StreamSubscription<BikeConnectionState> _connectionSubscription;
  StreamSubscription<List<int>>? _telemetrySubscription;
  BikeRegion? _preferredRegion;
  BikeControlPatch _nextConnectionIntent;
  BikeControlPatch _connectionIntent;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _disposed = false;
  var _manualReconnectPaused = false;
  var _foregroundPaused = false;
  var _disconnectRequested = false;
  var _expectedDisconnect = false;
  var _hasObservedConnection = false;
  Future<void>? _connectFuture;
  int? _connectFutureGeneration;
  int? _platformConnectGeneration;
  Future<BikeConfiguration>? _configurationChangeFuture;
  int? _configurationChangeGeneration;
  BikeControlPatch? _pendingControls;

  String get deviceId => connection.deviceId;
  ReadonlySignal<BikeSessionState> get state => _state.readonly();
  ReadonlySignal<BikeConfiguration?> get observed => _observed.readonly();
  ReadonlySignal<BikeConfiguration?> get pending => _pending.readonly();
  ReadonlySignal<BikeVersionInfo?> get versions => _versions.readonly();
  ReadonlySignal<int?> get odometerMeters => _odometerMeters.readonly();
  BikeProtocolVersion get protocolVersion => _protocolVersion;
  bool get canChangeConfiguration {
    if (_disposed ||
        _disconnectRequested ||
        !_hasObservedConnection ||
        _observed.peek() == null) {
      return false;
    }
    return switch (_state.peek()) {
      SessionReady() || SessionSynchronizing() => true,
      _ => false,
    };
  }

  Future<void> connect() {
    _ensureNotDisposed();
    final pending = _connectFuture;
    if (_connectFutureGeneration == _generation && pending != null) {
      return pending;
    }
    final currentState = _state.peek();
    if (!_disconnectRequested &&
        _hasObservedConnection &&
        (currentState is SessionReady ||
            currentState is SessionSynchronizing)) {
      return Future.value();
    }
    _invalidateConfigurationState();
    _manualReconnectPaused = false;
    _foregroundPaused = false;
    _disconnectRequested = false;
    _generation++;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    return _startConnect();
  }

  Future<void> retry() => connect();

  Future<void> synchronize() {
    _ensureNotDisposed();
    return _commands.add(() async {
      try {
        await _synchronizeNow();
      } on Object catch (error) {
        final failure = _asFailure(error);
        if (failure is BikeSessionDisposedFailure) {
          throw failure;
        }
        if (_isConnectionFailure(failure)) {
          _clearPendingConfiguration();
          _scheduleReconnect(failure);
        } else {
          _pending.value = null;
          _state.value = SessionFailed(failure: failure, canRetry: true);
        }
        throw failure;
      }
    });
  }

  Future<BikeConfiguration> setLight(bool value) {
    return setControls(BikeControlPatch(light: value));
  }

  Future<BikeConfiguration> setMode(int value) {
    BikeControlValues.validateMode(value);
    return setControls(BikeControlPatch(mode: value));
  }

  Future<BikeConfiguration> setAssist(int value) {
    BikeControlValues.validateAssist(value);
    return setControls(BikeControlPatch(assist: value));
  }

  Future<BikeConfiguration> setControls(BikeControlPatch controls) {
    return _changeConfiguration(controls);
  }

  void updateSetOnConnect(BikeControlPatch settings) {
    _nextConnectionIntent = settings;
  }

  void updatePreferredRegion(BikeRegion? region) {
    _preferredRegion = region;
    final current = _observed.peek();
    if (current != null && region != null) {
      _observed.value = current.copyWith(region: region);
    }
  }

  Future<void> disconnect() async {
    _ensureNotDisposed();
    _manualReconnectPaused = true;
    _foregroundPaused = false;
    await _enqueueDisconnect(manuallyPaused: true, abortPendingConnect: true);
  }

  Future<void> pauseForBackground() async {
    if (_disposed || _manualReconnectPaused || _foregroundPaused) {
      return;
    }
    _foregroundPaused = true;
    await _enqueueDisconnect(manuallyPaused: false, abortPendingConnect: true);
  }

  Future<void> resumeFromBackground() async {
    if (_disposed || _manualReconnectPaused || !_foregroundPaused) {
      return;
    }
    _foregroundPaused = false;
    _disconnectRequested = false;
    _generation++;
    _reconnectTimer?.cancel();
    await _startConnect();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _disconnectRequested = true;
    _generation++;
    _expectedDisconnect = true;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _commands.dispose();
    _invalidateConfigurationState();
    try {
      await connection.disconnect();
    } on Object {
      // Disconnect is best-effort during teardown.
    }
    try {
      await _commands.done;
    } on Object {
      // Pending callers receive their own command error.
    }
    try {
      await _disableNotifications(updatePeripheral: false);
    } on Object {
      // A torn-down stream may already be closed.
    }
    try {
      await _connectionSubscription.cancel();
    } on Object {
      // Subscription cancellation must not prevent the remaining cleanup.
    }
    try {
      await connection.dispose();
    } on Object {
      // The session is locally disposed even if platform teardown fails.
    }
    _state.value = const SessionDisposed();
    _state.dispose();
    _observed.dispose();
    _pending.dispose();
    _versions.dispose();
    _odometerMeters.dispose();
  }

  Future<void> _startConnect() {
    final existing = _connectFuture;
    if (_connectFutureGeneration == _generation && existing != null) {
      return existing;
    }
    final generation = _generation;
    final pending = _enqueueConnect();
    _connectFuture = pending;
    _connectFutureGeneration = generation;
    unawaited(
      pending.then<void>(
        (_) {
          if (identical(_connectFuture, pending)) {
            _connectFuture = null;
            _connectFutureGeneration = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_connectFuture, pending)) {
            _connectFuture = null;
            _connectFutureGeneration = null;
          }
        },
      ),
    );
    return pending;
  }

  Future<void> _enqueueConnect() {
    final generation = _generation;
    return _commands.add(() async {
      if (!_isCurrent(generation)) {
        return;
      }
      _expectedDisconnect = false;
      _connectionIntent = _nextConnectionIntent;
      _pollTimer?.cancel();
      _invalidateConfigurationState();
      await _disableNotifications(updatePeripheral: false);
      _versions.value = null;
      _odometerMeters.value = null;
      _state.value = const SessionConnecting();
      try {
        _platformConnectGeneration = generation;
        try {
          await _timed(connection.connect(), 'Connecting');
        } finally {
          if (_platformConnectGeneration == generation) {
            _platformConnectGeneration = null;
          }
        }
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionDiscovering();
        await _timed(connection.discoverRequiredGatt(), 'Service discovery');
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionAuthenticating();
        await _authenticate();
        if (!_isCurrent(generation)) {
          return;
        }
        await _enableNotifications();
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionConnected();
        await _synchronizeNow(forceSetOnConnectWrite: true);
        _reconnectAttempt = 0;
        if (readDiagnosticsOnConnect &&
            _isCurrent(generation) &&
            _hasObservedConnection) {
          await _refreshOdometer();
          await _refreshVersions();
        }
      } on Object catch (error) {
        if (!_isCurrent(generation)) {
          return;
        }
        final failure = _asFailure(error);
        if (failure case BikeBluetoothUnavailable(canRetry: false)) {
          _pending.value = null;
          _state.value = SessionFailed(failure: failure, canRetry: false);
        } else if (failure is _ProtocolSessionFailure ||
            failure is BikeAuthenticationFailed ||
            failure is BikeProtocolNotSupported) {
          _pending.value = null;
          _state.value = SessionFailed(failure: failure, canRetry: true);
        } else {
          _pending.value = null;
          _scheduleReconnect(failure);
        }
      }
    });
  }

  Future<void> _refreshVersions() async {
    const revisions = [
      BikeGatt.hardwareRevision,
      BikeGatt.firmwareRevision,
      BikeGatt.softwareRevision,
    ];
    if (revisions.any(
      (uuid) => !connection.hasCharacteristic(
        serviceUuid: BikeGatt.deviceInformationService,
        characteristicUuid: uuid,
      ),
    )) {
      return;
    }

    try {
      final hardware = _decodeRevision(
        await _timed(
          connection.readCharacteristic(
            serviceUuid: BikeGatt.deviceInformationService,
            characteristicUuid: BikeGatt.hardwareRevision,
          ),
          'Reading hardware revision',
        ),
      );
      final firmware = _decodeRevision(
        await _timed(
          connection.readCharacteristic(
            serviceUuid: BikeGatt.deviceInformationService,
            characteristicUuid: BikeGatt.firmwareRevision,
          ),
          'Reading firmware revision',
        ),
      );
      final software = _decodeRevision(
        await _timed(
          connection.readCharacteristic(
            serviceUuid: BikeGatt.deviceInformationService,
            characteristicUuid: BikeGatt.softwareRevision,
          ),
          'Reading software revision',
        ),
      );
      final info = BikeProtocol.decodeVersionInfo(
        hardwareRevision: hardware,
        firmwareRevision: firmware,
        softwareRevision: software,
        fcfc: await _protocol.readHistoryRecord(
          BikeGatt.displayVersionSelector,
        ),
        fafa: await _protocol.readHistoryRecord(
          BikeGatt.componentVersionsSelector,
        ),
      );
      _versions.value = info;
      try {
        await _onVersionsRead?.call(info);
      } on Object {
        // A cached version write must not prevent the bike becoming ride-ready.
      }
    } on Object {
      // Some bikes omit version data. Keep the last cache and continue setup.
    }
  }

  Future<void> _refreshOdometer() async {
    try {
      final meters = await _protocol.readOdometer(
        cachedMeters: _odometerMeters.peek(),
      );
      _odometerMeters.value = meters;
      try {
        await _onOdometerRead?.call(meters);
      } on Object {
        // A cached odometer write must not prevent the bike becoming ride-ready.
      }
    } on Object {
      // Missing odometer history is optional metadata, not a connection failure.
    }
  }

  String _decodeRevision(List<int> value) {
    return utf8.decode(value).replaceAll('\u0000', '').trim();
  }

  Future<void> _authenticate() async {
    final challenge = await _timed(
      connection.readCharacteristic(
        serviceUuid: BikeGatt.authenticationService,
        characteristicUuid: BikeGatt.authenticationChallenge,
      ),
      'Reading authentication challenge',
    );
    final response = BikeProtocol.authenticationResponse(
      challenge: challenge,
      key: _authenticationKey,
    );
    await _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.authenticationService,
        characteristicUuid: BikeGatt.authenticationResponse,
        value: response,
      ),
      'Writing authentication response',
    );
    final state = await _timed(
      connection.readCharacteristic(
        serviceUuid: BikeGatt.authenticationService,
        characteristicUuid: BikeGatt.authenticationState,
      ),
      'Verifying authentication',
    );
    if (state.length != 1 || state.single != 1) {
      throw const BikeAuthenticationFailed(
        'The bike rejected the challenge response.',
      );
    }
  }

  Future<void> _enableNotifications() async {
    await _telemetrySubscription?.cancel();
    _telemetrySubscription = connection
        .characteristicNotifications(
          serviceUuid: BikeGatt.metricsService,
          characteristicUuid: BikeGatt.telemetry,
        )
        .listen(_onTelemetry, onError: _onTelemetryError);
    try {
      await _timed(
        connection.setCharacteristicNotifications(
          serviceUuid: BikeGatt.metricsService,
          characteristicUuid: BikeGatt.telemetry,
          enabled: true,
        ),
        'Enabling bike updates',
      );
    } on Object {
      await _telemetrySubscription?.cancel();
      _telemetrySubscription = null;
      rethrow;
    }
  }

  Future<void> _disableNotifications({required bool updatePeripheral}) async {
    final subscription = _telemetrySubscription;
    _telemetrySubscription = null;
    if (subscription == null) {
      return;
    }
    if (updatePeripheral) {
      try {
        await _timed(
          connection.setCharacteristicNotifications(
            serviceUuid: BikeGatt.metricsService,
            characteristicUuid: BikeGatt.telemetry,
            enabled: false,
          ),
          'Disabling bike updates',
        );
      } on Object {
        // A disconnected peripheral no longer has an active notification
        // subscription to disable.
      }
    }
    await subscription.cancel();
  }

  void _onTelemetry(List<int> packet) {
    if (_disposed || _disconnectRequested || !_hasObservedConnection) {
      return;
    }
    try {
      final current = _observed.peek();
      if (current == null) {
        return;
      }
      final updated = _protocol.applyTelemetry(
        packet,
        current,
        preferredRegion: _preferredRegion,
      );
      if (updated == null) {
        return;
      }
      _publishObserved(updated);
    } on BikeProtocolFailure {
      // Notifications are advisory and may be partial or from an unsupported
      // telemetry family. Keep the last authoritative configuration; a later
      // valid notification or scheduled read can still update it.
    }
  }

  void _onTelemetryError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _generation++;
    _hasObservedConnection = false;
    _pollTimer?.cancel();
    _invalidateConfigurationState();
    unawaited(_disableNotifications(updatePeripheral: false));
    _scheduleReconnect(BikeSessionTransportFailure(error));
  }

  BikeConfiguration _publishObserved(BikeConfiguration configuration) {
    _observed.value = configuration;
    return configuration;
  }

  Future<void> _synchronizeNow({bool forceSetOnConnectWrite = false}) async {
    final generation = _generation;
    _pollTimer?.cancel();
    final confirmed = await _readConfiguration();
    if (!_isCurrent(generation) || !_hasObservedConnection) {
      throw const BikeSessionDisposedFailure();
    }
    _publishObserved(confirmed);

    final intent = _connectionIntent;
    if (intent.isEmpty) {
      _markReady(confirmed);
      return;
    }
    final target = intent.applyTo(
      confirmed.copyWith(region: _preferredRegion ?? confirmed.region),
    );
    if (!forceSetOnConnectWrite &&
        intent.matches(confirmed) &&
        _wireRegionMatches(target)) {
      _markReady(confirmed);
      return;
    }
    _state.value = const SessionSynchronizing(attempt: 1);
    await _protocol.writeConfiguration(target);
    if (!_isCurrent(generation) || !_hasObservedConnection) {
      throw const BikeSessionDisposedFailure();
    }
    _publishObserved(target);
    _markReady(target);
  }

  Future<BikeConfiguration> _changeConfiguration(BikeControlPatch controls) {
    _ensureNotDisposed();
    if (!canChangeConfiguration) {
      throw const BikeSessionNotReady();
    }
    final current = _pending.peek() ?? _observed.peek();
    if (current == null) {
      throw const BikeSessionNotReady();
    }
    _pendingControls = _pendingControls?.merge(controls) ?? controls;
    final target = _pendingControls!.applyTo(
      current.copyWith(region: _preferredRegion ?? current.region),
    );
    final generation = _generation;
    _pending.value = target;
    _state.value = const SessionSynchronizing(attempt: 1);
    final existing = _configurationChangeFuture;
    if (_configurationChangeGeneration == generation && existing != null) {
      return existing;
    }
    final pending = _commands.add(
      () => _drainConfigurationChanges(generation),
    );
    _configurationChangeFuture = pending;
    _configurationChangeGeneration = generation;
    return pending;
  }

  Future<BikeConfiguration> _drainConfigurationChanges(int generation) async {
    try {
      while (true) {
        if (!_isCurrent(generation) || !_hasObservedConnection) {
          throw const BikeSessionDisposedFailure();
        }
        final current = _observed.peek();
        if (_pending.peek() == null || current == null) {
          throw const BikeSessionNotReady();
        }
        final controls = _pendingControls!;
        final target = controls.applyTo(
          current.copyWith(region: _preferredRegion ?? current.region),
        );
        _pending.value = target;
        // An explicit control must reach the bike even when telemetry claims
        // the cached state already matches; the controller can lag that cache.
        _pollTimer?.cancel();
        late BikeConfiguration written;
        try {
          await _protocol.writeConfiguration(target);
          if (!_isCurrent(generation) || !_hasObservedConnection) {
            throw const BikeSessionDisposedFailure();
          }
          written = _publishObserved(target);
        } on Object catch (error) {
          final failure = _asFailure(error);
          _clearPendingConfiguration();
          if (_isConnectionFailure(failure)) {
            _scheduleReconnect(failure);
          } else if (failure is! BikeSessionDisposedFailure) {
            _state.value = SessionFailed(failure: failure, canRetry: true);
          }
          throw failure;
        }

        _clearPendingIf(target);
        if (_pending.peek() != null) {
          continue;
        }
        _markReady(written);
        return written;
      }
    } finally {
      if (_configurationChangeGeneration == generation) {
        _configurationChangeFuture = null;
        _configurationChangeGeneration = null;
      }
    }
  }

  Future<BikeConfiguration> _readConfiguration() async {
    return _protocol.readConfiguration(
      preferredRegion: _preferredRegion,
      fallbackRegion: _observed.peek()?.region,
      onOdometer: (meters) => _odometerMeters.value = meters,
    );
  }

  void _markReady(
    BikeConfiguration configuration, {
    BikeConfiguration? completedTarget,
  }) {
    if (_disposed || !_hasObservedConnection) {
      return;
    }
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    if (completedTarget != null) {
      _clearPendingIf(completedTarget);
    }
    if (_pending.peek() != null) {
      _state.value = const SessionSynchronizing(attempt: 1);
      return;
    }
    _state.value = SessionReady(configuration: configuration);
    if (_pollInterval case final interval?) {
      _pollTimer = Timer.periodic(interval, (_) {
        if (!_commands.isBusy && _state.peek() is SessionReady) {
          unawaited(_pollConfiguration().catchError((Object _) {}));
        }
      });
    }
  }

  Future<void> _pollConfiguration() {
    final generation = _generation;
    return _commands.add(() async {
      if (!_isCurrent(generation) ||
          !_hasObservedConnection ||
          _state.peek() is! SessionReady) {
        return;
      }
      try {
        final confirmed = await _readConfiguration();
        if (!_isCurrent(generation) || !_hasObservedConnection) {
          return;
        }
        final published = _publishObserved(confirmed);
        _state.value = SessionReady(configuration: published);
      } on Object catch (error) {
        if (!_isCurrent(generation)) {
          return;
        }
        final failure = _asFailure(error);
        if (_isConnectionFailure(failure)) {
          _scheduleReconnect(failure);
        } else if (failure is! BikeSessionDisposedFailure) {
          _state.value = SessionFailed(failure: failure, canRetry: true);
        }
      }
    });
  }

  void _clearPendingIf(BikeConfiguration target) {
    if (_pending.peek() == target) {
      _clearPendingConfiguration();
    }
  }

  void _clearPendingConfiguration() {
    _pending.value = null;
    _pendingControls = null;
  }

  Future<void> _enqueueDisconnect({
    required bool manuallyPaused,
    required bool abortPendingConnect,
  }) async {
    final previousGeneration = _generation;
    final hadPendingConnect =
        abortPendingConnect && _platformConnectGeneration == previousGeneration;
    _disconnectRequested = true;
    final disconnectGeneration = ++_generation;
    _expectedDisconnect = true;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _invalidateConfigurationState();
    if (hadPendingConnect) {
      try {
        await connection.disconnect();
      } on Object {
        // Disconnecting is also the cancellation mechanism for a platform
        // connection attempt, so this is best-effort.
      }
    }
    return _commands.add(() async {
      if (!_isCurrent(disconnectGeneration) || !_disconnectRequested) {
        return;
      }
      await _disconnectNow(manuallyPaused: manuallyPaused);
    });
  }

  Future<void> _disconnectNow({
    required bool manuallyPaused,
    bool disconnectPeripheral = true,
  }) async {
    _hasObservedConnection = false;
    _invalidateConfigurationState();
    await _disableNotifications(updatePeripheral: true);
    if (disconnectPeripheral) {
      try {
        await _timed(connection.disconnect(), 'Disconnecting');
      } on Object {
        // The local session is still paused even if the platform already lost
        // the link before it could acknowledge the disconnect.
      }
    }
    if (!_disposed) {
      _state.value = SessionDisconnected(manuallyPaused: manuallyPaused);
    }
  }

  void _onConnectionState(BikeConnectionState connectionState) {
    if (_disposed) {
      return;
    }
    if (connectionState == BikeConnectionState.connected) {
      _hasObservedConnection = true;
      return;
    }
    if (!_hasObservedConnection) {
      return;
    }
    _hasObservedConnection = false;
    _invalidateConfigurationState();
    if (_expectedDisconnect ||
        _manualReconnectPaused ||
        _foregroundPaused ||
        _state.peek() is SessionIdle) {
      return;
    }
    _reconnectTimer?.cancel();
    _generation++;
    _pollTimer?.cancel();
    unawaited(_disableNotifications(updatePeripheral: false));
    _scheduleReconnect(
      const BikeSessionTransportFailure('The bike disconnected.'),
    );
  }

  void _scheduleReconnect(BikeSessionFailure failure) {
    if (_disposed || _manualReconnectPaused || _foregroundPaused) {
      return;
    }
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    _invalidateConfigurationState();
    if (_reconnectDelays.isEmpty) {
      _state.value = SessionFailed(failure: failure, canRetry: true);
      return;
    }
    final delayIndex = _reconnectAttempt < _reconnectDelays.length
        ? _reconnectAttempt
        : _reconnectDelays.length - 1;
    final delay = _reconnectDelays[delayIndex];
    _reconnectAttempt++;
    _state.value = SessionReconnecting(
      attempt: _reconnectAttempt,
      retryAfter: delay,
      failure: failure,
    );
    final generation = _generation;
    _reconnectTimer = Timer(delay, () {
      if (_isCurrent(generation) &&
          !_manualReconnectPaused &&
          !_foregroundPaused) {
        unawaited(_startConnect());
      }
    });
  }

  Future<T> _timed<T>(Future<T> operation, String name) async {
    try {
      return await operation.timeout(_commandTimeout);
    } on TimeoutException {
      throw BikeCommandTimedOut(name);
    }
  }

  BikeSessionFailure _asFailure(Object error) {
    return switch (error) {
      final BikeSessionFailure failure => failure,
      final BikeAdapterUnavailable failure => BikeBluetoothUnavailable(
        failure.message,
        canRetry: failure.canRetry,
      ),
      final BikeGattNotSupported failure => BikeProtocolNotSupported(
        failure.message,
      ),
      final BikeProtocolFailure failure => _ProtocolSessionFailure(failure),
      _ => BikeSessionTransportFailure(error),
    };
  }

  bool _isConnectionFailure(BikeSessionFailure failure) {
    return failure is BikeSessionTransportFailure ||
        failure is BikeCommandTimedOut ||
        failure is BikeBluetoothUnavailable && failure.canRetry;
  }

  bool _wireRegionMatches(BikeConfiguration target) {
    return _protocol.wireRegionMatches(target);
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _invalidateConfigurationState() {
    _clearPendingConfiguration();
    _observed.value = null;
    _protocol.reset();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const BikeSessionDisposedFailure();
    }
  }
}

final class _ProtocolSessionFailure extends BikeSessionFailure {
  const _ProtocolSessionFailure(BikeProtocolFailure failure)
    : super('The bike returned invalid data: $failure');
}

final class _SerialCommandQueue {
  Future<void> _tail = Future.value();
  var _pending = 0;
  var _disposed = false;

  bool get isBusy => _pending > 0;
  Future<void> get done => _tail;

  Future<T> add<T>(Future<T> Function() command) {
    if (_disposed) {
      return Future.error(const BikeSessionDisposedFailure());
    }
    final previous = _tail;
    final released = Completer<void>();
    final result = Completer<T>();
    _tail = released.future;
    _pending++;

    unawaited(() async {
      try {
        await previous;
        if (_disposed) {
          throw const BikeSessionDisposedFailure();
        }
        result.complete(await command());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        _pending--;
        released.complete();
      }
    }());
    return result.future;
  }

  void dispose() {
    _disposed = true;
  }
}
