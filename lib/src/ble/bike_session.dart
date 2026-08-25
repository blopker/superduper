import 'dart:async';
import 'dart:convert';

import 'package:signals/signals.dart';
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/ble/locked_configuration_policy.dart';
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

final class BikeSettingsNotApplied extends BikeSessionFailure {
  const BikeSettingsNotApplied()
    : super('The bike did not keep the requested settings.');
}

final class BikeSessionDisposedFailure extends BikeSessionFailure {
  const BikeSessionDisposedFailure() : super('The bike session is disposed.');
}

final class BikeSessionNotReady extends BikeSessionFailure {
  const BikeSessionNotReady() : super('The bike is not ready for controls.');
}

final class BikeSettingsPersistenceFailure extends BikeSessionFailure {
  const BikeSettingsPersistenceFailure()
    : super('The bike changed, but its saved setting could not be updated.');
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

final class SessionDegraded extends BikeSessionState {
  const SessionDegraded({required this.configuration, required this.failure});

  final BikeConfiguration configuration;
  final BikeSettingsNotApplied failure;
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

typedef ConfigurationConfirmed = Future<void> Function(
  BikeConfiguration configuration,
);
typedef VersionsRead = Future<void> Function(BikeVersionInfo versions);

final class BikeSession {
  BikeSession({
    required this.connection,
    required BikeRegion? preferredRegion,
    required RidePreferences preferences,
    required BikeProtocolVersion protocol,
    List<int> authenticationKey = BikeProtocol.defaultAuthenticationKey,
    ConfigurationConfirmed? onConfigurationConfirmed,
    VersionsRead? onVersionsRead,
    Duration commandTimeout = const Duration(seconds: 15),
    Duration? pollInterval = const Duration(seconds: 30),
    List<Duration> reconnectDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    List<Duration> synchronizationRetryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
    List<Duration> confirmationRetryDelays = const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 750),
      Duration(seconds: 1),
    ],
    int correctiveAttempts = 2,
  }) : _protocolVersion = protocol,
       // The public named parameter backs private mutable session state.
       // ignore: prefer_initializing_formals
       _preferredRegion = preferredRegion,
       _authenticationKey = List<int>.unmodifiable(authenticationKey),
       // The public named parameter backs private mutable session state.
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // The public named parameter keeps the callback implementation private.
       // ignore: prefer_initializing_formals
       _onConfigurationConfirmed = onConfigurationConfirmed,
       // The public named parameter keeps the callback implementation private.
       // ignore: prefer_initializing_formals
       _onVersionsRead = onVersionsRead,
       // The public named parameter keeps connection policy private.
       // ignore: prefer_initializing_formals
       _commandTimeout = commandTimeout,
       // The public named parameter keeps connection policy private.
       // ignore: prefer_initializing_formals
       _pollInterval = pollInterval,
       _reconnectDelays = List.unmodifiable(reconnectDelays),
       _synchronizationRetryDelays = List.unmodifiable(
         synchronizationRetryDelays,
       ),
       _confirmationRetryDelays = List.unmodifiable(confirmationRetryDelays),
       _correctiveAttempts = correctiveAttempts {
    if (correctiveAttempts < 1) {
      throw ArgumentError.value(
        correctiveAttempts,
        'correctiveAttempts',
        'Must be at least one.',
      );
    }
    if (confirmationRetryDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        confirmationRetryDelays,
        'confirmationRetryDelays',
        'Must not contain negative durations.',
      );
    }
    if (reconnectDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        reconnectDelays,
        'reconnectDelays',
        'Must not contain negative durations.',
      );
    }
    if (synchronizationRetryDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        synchronizationRetryDelays,
        'synchronizationRetryDelays',
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
  final ConfigurationConfirmed? _onConfigurationConfirmed;
  final VersionsRead? _onVersionsRead;
  final Duration _commandTimeout;
  final Duration? _pollInterval;
  final List<Duration> _reconnectDelays;
  final List<Duration> _synchronizationRetryDelays;
  final List<Duration> _confirmationRetryDelays;
  final int _correctiveAttempts;
  final BikeProtocolVersion _protocolVersion;
  final List<int> _authenticationKey;
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

  late final StreamSubscription<BikeConnectionState> _connectionSubscription;
  StreamSubscription<List<int>>? _telemetrySubscription;
  BikeRegion? _preferredRegion;
  RidePreferences _preferences;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _synchronizationRetryTimer;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _synchronizationRetryAttempt = 0;
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
  BikeRegion? _lastV1WireRegion;

  String get deviceId => connection.deviceId;
  ReadonlySignal<BikeSessionState> get state => _state.readonly();
  ReadonlySignal<BikeConfiguration?> get observed => _observed.readonly();
  ReadonlySignal<BikeConfiguration?> get pending => _pending.readonly();
  ReadonlySignal<BikeVersionInfo?> get versions => _versions.readonly();
  bool get manualReconnectPaused => _manualReconnectPaused;
  BikeProtocolVersion get protocolVersion => _protocolVersion;
  bool get canChangeConfiguration {
    if (_disposed ||
        _disconnectRequested ||
        !_hasObservedConnection ||
        _observed.peek() == null) {
      return false;
    }
    return switch (_state.peek()) {
      SessionReady() || SessionSynchronizing() || SessionDegraded() => true,
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
    _manualReconnectPaused = false;
    _foregroundPaused = false;
    _disconnectRequested = false;
    _generation++;
    _reconnectAttempt = 0;
    _synchronizationRetryAttempt = 0;
    _reconnectTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    return _startConnect();
  }

  Future<void> retry() {
    if (_state.peek() is SessionDegraded && _hasObservedConnection) {
      _synchronizationRetryAttempt = 0;
      return synchronize();
    }
    return connect();
  }

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
        if (failure is BikeSettingsNotApplied && _hasObservedConnection) {
          _scheduleSynchronizationRetry(failure);
        } else if (_isConnectionFailure(failure)) {
          _pending.value = null;
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
    return _changeConfiguration((current) => current.copyWith(light: value));
  }

  Future<BikeConfiguration> setMode(int value) {
    if (value < 0 || value > 3) {
      throw RangeError.range(value, 0, 3, 'mode');
    }
    return _changeConfiguration((current) => current.copyWith(mode: value));
  }

  Future<BikeConfiguration> setAssist(int value) {
    if (value < 0 || value > 4) {
      throw RangeError.range(value, 0, 4, 'assist');
    }
    return _changeConfiguration((current) => current.copyWith(assist: value));
  }

  Future<void> updatePreferences(RidePreferences preferences) {
    if (_preferences == preferences) {
      return Future.value();
    }
    final requiresSynchronization = !LockedConfigurationPolicy.sameEnforcement(
      _preferences,
      preferences,
    );
    _preferences = preferences;
    if (requiresSynchronization && canChangeConfiguration) {
      return synchronize();
    }
    return Future.value();
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
    _synchronizationRetryTimer?.cancel();
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
    _synchronizationRetryTimer?.cancel();
    _commands.dispose();
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
      _pollTimer?.cancel();
      _synchronizationRetryTimer?.cancel();
      _pending.value = null;
      await _disableNotifications(updatePeripheral: false);
      _versions.value = null;
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
        await _synchronizeNow(forceLockedWrite: true);
        _reconnectAttempt = 0;
        if (_isCurrent(generation) && _hasObservedConnection) {
          await _refreshVersions();
        }
      } on Object catch (error) {
        if (!_isCurrent(generation)) {
          return;
        }
        final failure = _asFailure(error);
        if (failure is BikeSettingsNotApplied && _hasObservedConnection) {
          _scheduleSynchronizationRetry(failure);
        } else if (failure case BikeBluetoothUnavailable(canRetry: false)) {
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
        fcfc: await _readHistoryRecord(BikeGatt.displayVersionSelector),
        fafa: await _readHistoryRecord(BikeGatt.componentVersionsSelector),
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
    if (_disposed) {
      return;
    }
    try {
      var updated = BikeProtocol.applyTelemetry(
        version: _protocolVersion,
        packet: packet,
        current: _observed.peek(),
      );
      if (updated == null) {
        return;
      }
      if (_protocolVersion == BikeProtocolVersion.v1) {
        _lastV1WireRegion = updated.region;
      }
      if (_preferredRegion case final region?) {
        updated = updated.copyWith(region: region);
      }
      _publishObserved(updated);
      final target = LockedConfigurationPolicy.effective(
        observed: updated,
        preferences: _preferences,
        preferredRegion: _preferredRegion,
      );
      if (_state.peek() is SessionReady &&
          !LockedConfigurationPolicy.lockedValuesMatch(
            observed: updated,
            target: target,
            preferences: _preferences,
          ) &&
          !_commands.isBusy) {
        unawaited(synchronize().catchError((Object _) {}));
      }
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
    _synchronizationRetryTimer?.cancel();
    _pending.value = null;
    unawaited(_disableNotifications(updatePeripheral: false));
    _scheduleReconnect(BikeSessionTransportFailure(error));
  }

  void _publishObserved(BikeConfiguration configuration) {
    _observed.value = configuration;
  }

  Future<void> _synchronizeNow({bool forceLockedWrite = false}) async {
    final generation = _generation;
    _pollTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    var confirmed = await _readConfiguration();
    if (!_isCurrent(generation) || !_hasObservedConnection) {
      throw const BikeSessionDisposedFailure();
    }
    _publishObserved(confirmed);
    var mustWrite =
        forceLockedWrite &&
        LockedConfigurationPolicy.hasLockedSettings(_preferences);

    for (var attempt = 1; attempt <= _correctiveAttempts; attempt++) {
      final target = LockedConfigurationPolicy.effective(
        observed: confirmed,
        preferences: _preferences,
        preferredRegion: _preferredRegion,
      );
      if (!mustWrite &&
          LockedConfigurationPolicy.lockedValuesMatch(
            observed: confirmed,
            target: target,
            preferences: _preferences,
          )) {
        _markReady(confirmed);
        return;
      }
      _state.value = SessionSynchronizing(attempt: attempt);
      await _writeConfiguration(target);
      if (!_isCurrent(generation) || !_hasObservedConnection) {
        throw const BikeSessionDisposedFailure();
      }
      mustWrite = false;
      confirmed = await _readConfigurationUntil(
        (candidate) =>
            LockedConfigurationPolicy.lockedValuesMatch(
              observed: candidate,
              target: target,
              preferences: _preferences,
            ) &&
            _wireRegionMatches(target),
      );
      if (!_isCurrent(generation) || !_hasObservedConnection) {
        throw const BikeSessionDisposedFailure();
      }
      _publishObserved(confirmed);
      if (LockedConfigurationPolicy.lockedValuesMatch(
            observed: confirmed,
            target: target,
            preferences: _preferences,
          ) &&
          _wireRegionMatches(target)) {
        _markReady(confirmed);
        return;
      }
    }
    throw const BikeSettingsNotApplied();
  }

  Future<BikeConfiguration> _changeConfiguration(
    BikeConfiguration Function(BikeConfiguration current) update,
  ) {
    _ensureNotDisposed();
    if (!canChangeConfiguration) {
      throw const BikeSessionNotReady();
    }
    final current = _pending.peek() ?? _observed.peek();
    if (current == null) {
      throw const BikeSessionNotReady();
    }
    final enforced = LockedConfigurationPolicy.effective(
      observed: current,
      preferences: _preferences,
      preferredRegion: _preferredRegion,
    );
    final target = update(enforced).copyWith(
      region: _preferredRegion ?? current.region,
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
    BikeSettingsPersistenceFailure? persistenceFailure;
    try {
      while (true) {
        if (!_isCurrent(generation) || !_hasObservedConnection) {
          throw const BikeSessionDisposedFailure();
        }
        final target = _pending.peek();
        final current = _observed.peek();
        if (target == null || current == null) {
          throw const BikeSessionNotReady();
        }
        if (target == current) {
          _clearPendingIf(target);
          if (_pending.peek() != null) {
            continue;
          }
          _markReady(current);
          if (persistenceFailure != null) {
            throw persistenceFailure;
          }
          return current;
        }

        _pollTimer?.cancel();
        _synchronizationRetryTimer?.cancel();
        late BikeConfiguration confirmed;
        try {
          await _writeConfiguration(target);
          if (!_isCurrent(generation) || !_hasObservedConnection) {
            throw const BikeSessionDisposedFailure();
          }
          confirmed = await _readConfigurationUntil(
            (candidate) => candidate == target && _wireRegionMatches(target),
            retryWrite: () {
              if (_pending.peek() != target) {
                return Future.value();
              }
              return _writeConfiguration(target);
            },
          );
          if (!_isCurrent(generation) || !_hasObservedConnection) {
            throw const BikeSessionDisposedFailure();
          }
          _publishObserved(confirmed);
          if (confirmed != target || !_wireRegionMatches(target)) {
            throw const BikeSettingsNotApplied();
          }
        } on Object catch (error) {
          final failure = _asFailure(error);
          final latest = _pending.peek();
          final hasNewerTarget = latest != null && latest != target;
          if (failure is BikeSettingsNotApplied &&
              hasNewerTarget &&
              _hasObservedConnection) {
            continue;
          }
          _pending.value = null;
          final observed = _observed.peek();
          if (failure is BikeSettingsNotApplied &&
              _hasObservedConnection &&
              observed != null) {
            _markDegraded(observed, failure);
          } else if (_isConnectionFailure(failure)) {
            _scheduleReconnect(failure);
          } else if (failure is! BikeSessionDisposedFailure) {
            _state.value = SessionFailed(failure: failure, canRetry: true);
          }
          throw failure;
        }

        _preferences = _preferences.copyWith(
          desiredLight: confirmed.light,
          desiredMode: confirmed.mode,
          desiredAssist: confirmed.assist,
        );
        try {
          await _onConfigurationConfirmed?.call(confirmed);
        } on Object {
          persistenceFailure = const BikeSettingsPersistenceFailure();
        }
        _clearPendingIf(target);
        if (_pending.peek() != null) {
          continue;
        }
        _markReady(confirmed);
        if (persistenceFailure != null) {
          throw persistenceFailure;
        }
        return confirmed;
      }
    } finally {
      if (_configurationChangeGeneration == generation) {
        _configurationChangeFuture = null;
        _configurationChangeGeneration = null;
      }
    }
  }

  Future<BikeConfiguration> _readConfigurationUntil(
    bool Function(BikeConfiguration configuration) matches, {
    Future<void> Function()? retryWrite,
  }) async {
    if (_confirmationRetryDelays.isEmpty) {
      final confirmed = await _readConfiguration();
      _publishObserved(confirmed);
      return confirmed;
    }

    BikeConfiguration? confirmed;
    for (var index = 0; index < _confirmationRetryDelays.length; index++) {
      final delay = _confirmationRetryDelays[index];
      await Future<void>.delayed(delay);
      if (index > 0) {
        await retryWrite?.call();
      }
      confirmed = await _readConfiguration();
      _publishObserved(confirmed);
      if (matches(confirmed)) {
        return confirmed;
      }
    }
    return confirmed ?? await _readConfiguration();
  }

  Future<BikeConfiguration> _readConfiguration() async {
    switch (_protocolVersion) {
      case BikeProtocolVersion.v1:
        final decoded = BikeProtocol.decodeV1State(
          await _readHistoryRecord(BikeGatt.v1StateSelector),
        );
        _lastV1WireRegion = decoded.region;
        final preferredRegion = _preferredRegion;
        return preferredRegion == null
            ? decoded
            : decoded.copyWith(region: preferredRegion);
      case BikeProtocolVersion.v2:
        _lastV1WireRegion = null;
        return BikeProtocol.decodeV2State(
          d0: await _readHistoryRecord(BikeGatt.v2ControlSelector),
          d9: await _readHistoryRecord(BikeGatt.v2ModeSelector),
          region: _preferredRegion ?? _observed.peek()?.region ?? BikeRegion.us,
        );
    }
  }

  Future<List<int>?> _tryReadHistoryRecord(List<int> selector) async {
    await _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.registerSelector,
        value: selector,
      ),
      'Selecting state register',
    );
    final frame = await _timed(
      connection.readCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.stateRegister,
      ),
      'Reading bike state',
    );
    return BikeProtocol.hasPacketId(frame, selector) ? frame : null;
  }

  Future<List<int>> _readHistoryRecord(List<int> selector) async {
    final frame = await _tryReadHistoryRecord(selector);
    if (frame != null) {
      return frame;
    }
    throw UnexpectedBikePacket(
      expected: _packetId(selector),
      actual: 'a different or malformed record',
    );
  }

  Future<void> _writeConfiguration(BikeConfiguration configuration) {
    return _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.stateRegister,
        value: BikeProtocol.encodeConfiguration(
          configuration,
          version: _protocolVersion,
        ),
      ),
      'Writing bike settings',
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
    _synchronizationRetryTimer?.cancel();
    _reconnectTimer?.cancel();
    _synchronizationRetryAttempt = 0;
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
          unawaited(synchronize().catchError((Object _) {}));
        }
      });
    }
  }

  void _markDegraded(
    BikeConfiguration configuration,
    BikeSettingsNotApplied failure,
  ) {
    if (_disposed || !_hasObservedConnection) {
      return;
    }
    _pollTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    _state.value = SessionDegraded(
      configuration: configuration,
      failure: failure,
    );
  }

  void _clearPendingIf(BikeConfiguration target) {
    if (_pending.peek() == target) {
      _pending.value = null;
    }
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
    _synchronizationRetryTimer?.cancel();
    _pending.value = null;
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
    if (_expectedDisconnect ||
        _manualReconnectPaused ||
        _foregroundPaused ||
        _state.peek() is SessionIdle) {
      return;
    }
    _reconnectTimer?.cancel();
    _generation++;
    _pollTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    _pending.value = null;
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
    _synchronizationRetryTimer?.cancel();
    _pending.value = null;
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

  void _scheduleSynchronizationRetry(BikeSettingsNotApplied failure) {
    if (_disposed ||
        _manualReconnectPaused ||
        _foregroundPaused ||
        !_hasObservedConnection) {
      return;
    }
    if (_synchronizationRetryTimer?.isActive ?? false) {
      return;
    }
    if (_synchronizationRetryDelays.isEmpty) {
      final configuration = _observed.peek();
      if (configuration != null) {
        _markDegraded(configuration, failure);
      }
      return;
    }
    if (_synchronizationRetryAttempt >= _synchronizationRetryDelays.length) {
      final configuration = _observed.peek();
      if (configuration != null) {
        _markDegraded(configuration, failure);
      }
      return;
    }
    final delay = _synchronizationRetryDelays[_synchronizationRetryAttempt];
    _synchronizationRetryAttempt++;
    _state.value = SessionSynchronizing(attempt: _synchronizationRetryAttempt);
    _synchronizationRetryTimer = Timer(delay, () {
      if (!_disposed &&
          !_manualReconnectPaused &&
          !_foregroundPaused &&
          _hasObservedConnection) {
        unawaited(synchronize().catchError((Object _) {}));
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
    return _protocolVersion != BikeProtocolVersion.v1 ||
        _lastV1WireRegion == target.region;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const BikeSessionDisposedFailure();
    }
  }

  static String _packetId(List<int> bytes) {
    return bytes
        .take(2)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
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
