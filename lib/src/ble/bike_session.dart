import 'dart:async';

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

final class SessionSynchronizing extends BikeSessionState {
  const SessionSynchronizing({required this.attempt});

  final int attempt;
}

final class SessionReady extends BikeSessionState {
  const SessionReady({required this.configuration});

  final BikeConfiguration configuration;
}

final class SessionReconnecting extends BikeSessionState {
  const SessionReconnecting({required this.attempt, required this.retryAfter});

  final int attempt;
  final Duration retryAfter;
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

final class BikeSession {
  BikeSession({
    required this.connection,
    required BikeRegion? preferredRegion,
    required RidePreferences preferences,
    ConfigurationConfirmed? onConfigurationConfirmed,
    Duration commandTimeout = const Duration(seconds: 15),
    Duration? pollInterval = const Duration(seconds: 5),
    List<Duration> reconnectDelays = const [
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
    // ignore: prefer_initializing_formals
  }) : _preferredRegion = preferredRegion,
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // ignore: prefer_initializing_formals
       _onConfigurationConfirmed = onConfigurationConfirmed,
       // ignore: prefer_initializing_formals
       _commandTimeout = commandTimeout,
       // ignore: prefer_initializing_formals
       _pollInterval = pollInterval,
       _reconnectDelays = List.unmodifiable(reconnectDelays),
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
    _connectionSubscription = connection.states.listen(_onConnectionState);
  }

  final BikeConnection connection;
  final ConfigurationConfirmed? _onConfigurationConfirmed;
  final Duration _commandTimeout;
  final Duration? _pollInterval;
  final List<Duration> _reconnectDelays;
  final List<Duration> _confirmationRetryDelays;
  final int _correctiveAttempts;
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

  late final StreamSubscription<BikeConnectionState> _connectionSubscription;
  BikeRegion? _preferredRegion;
  RidePreferences _preferences;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _disposed = false;
  var _manualReconnectPaused = false;
  var _foregroundPaused = false;
  var _expectedDisconnect = false;
  var _hasObservedConnection = false;

  String get deviceId => connection.deviceId;
  ReadonlySignal<BikeSessionState> get state => _state.readonly();
  ReadonlySignal<BikeConfiguration?> get observed => _observed.readonly();
  ReadonlySignal<BikeConfiguration?> get pending => _pending.readonly();
  bool get manualReconnectPaused => _manualReconnectPaused;

  Future<void> connect() {
    _ensureNotDisposed();
    _manualReconnectPaused = false;
    _foregroundPaused = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    return _enqueueConnect();
  }

  Future<void> retry() => connect();

  Future<void> synchronize() {
    _ensureNotDisposed();
    return _commands.add(() async {
      try {
        await _synchronizeNow();
      } on Object catch (error) {
        final failure = _asFailure(error);
        _state.value = SessionFailed(failure: failure, canRetry: true);
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
    final requiresSynchronization = !_sameEnforcement(
      _preferences,
      preferences,
    );
    _preferences = preferences;
    if (requiresSynchronization && _state.peek() is SessionReady) {
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
    await _enqueueDisconnect(manuallyPaused: true);
  }

  Future<void> pauseForBackground() async {
    if (_disposed || _manualReconnectPaused || _foregroundPaused) {
      return;
    }
    _foregroundPaused = true;
    await _enqueueDisconnect(manuallyPaused: false);
  }

  Future<void> resumeFromBackground() async {
    if (_disposed || _manualReconnectPaused || !_foregroundPaused) {
      return;
    }
    _foregroundPaused = false;
    await _enqueueConnect();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation++;
    _expectedDisconnect = true;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _commands.dispose();
    await _commands.done;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    await _connectionSubscription.cancel();
    await connection.dispose();
    _state.value = const SessionDisposed();
    _state.dispose();
    _observed.dispose();
    _pending.dispose();
  }

  Future<void> _enqueueConnect() {
    final generation = _generation;
    return _commands.add(() async {
      if (!_isCurrent(generation)) {
        return;
      }
      _expectedDisconnect = false;
      _pollTimer?.cancel();
      _state.value = const SessionConnecting();
      try {
        await _timed(connection.connect(), 'Connecting');
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionDiscovering();
        await _timed(connection.discoverRequiredGatt(), 'Service discovery');
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionConnected();
        await _synchronizeNow();
        _reconnectAttempt = 0;
      } on Object catch (error) {
        if (!_isCurrent(generation)) {
          return;
        }
        final failure = _asFailure(error);
        if (failure is BikeSettingsNotApplied ||
            failure is _ProtocolSessionFailure) {
          _state.value = SessionFailed(failure: failure, canRetry: true);
        } else {
          _scheduleReconnect(failure);
        }
      }
    });
  }

  Future<void> _synchronizeNow() async {
    _pollTimer?.cancel();
    var confirmed = await _readConfiguration();
    _observed.value = confirmed;

    for (var attempt = 1; attempt <= _correctiveAttempts; attempt++) {
      final target = _effectiveConfiguration(confirmed);
      if (_lockedValuesMatch(confirmed, target)) {
        _markReady(confirmed);
        return;
      }
      _state.value = SessionSynchronizing(attempt: attempt);
      _pending.value = target;
      await _writeConfiguration(target);
      confirmed = await _readConfigurationUntil(
        (candidate) => _lockedValuesMatch(candidate, target),
      );
      _observed.value = confirmed;
      if (_lockedValuesMatch(confirmed, target)) {
        _pending.value = null;
        _markReady(confirmed);
        return;
      }
    }

    _pending.value = null;
    throw const BikeSettingsNotApplied();
  }

  Future<BikeConfiguration> _changeConfiguration(
    BikeConfiguration Function(BikeConfiguration current) update,
  ) {
    _ensureNotDisposed();
    if (_observed.peek() == null || _state.peek() is! SessionReady) {
      throw const BikeSessionNotReady();
    }
    final generation = _generation;
    return _commands.add(() async {
      if (!_isCurrent(generation)) {
        throw const BikeSessionDisposedFailure();
      }
      final current = _observed.peek();
      if (current == null) {
        throw const BikeSessionNotReady();
      }
      final target = update(current)
          .copyWith(region: _preferredRegion ?? current.region);
      _pollTimer?.cancel();
      _pending.value = target;
      _state.value = const SessionSynchronizing(attempt: 1);
      late BikeConfiguration confirmed;
      try {
        await _writeConfiguration(target);
        confirmed = await _readConfigurationUntil(
          (candidate) => candidate == target,
        );
        _observed.value = confirmed;
        if (confirmed != target) {
          throw const BikeSettingsNotApplied();
        }
      } on Object catch (error) {
        _pending.value = null;
        final failure = _asFailure(error);
        final observed = _observed.peek();
        if (failure is BikeSettingsNotApplied &&
            _hasObservedConnection &&
            observed != null) {
          _markReady(observed);
        } else if (failure is BikeSessionTransportFailure) {
          _scheduleReconnect(failure);
        } else {
          _state.value = SessionFailed(failure: failure, canRetry: true);
        }
        throw failure;
      }
      try {
        await _onConfigurationConfirmed?.call(confirmed);
      } on Object {
        _pending.value = null;
        _markReady(confirmed);
        throw const BikeSettingsPersistenceFailure();
      }
      _pending.value = null;
      _markReady(confirmed);
      return confirmed;
    });
  }

  Future<BikeConfiguration> _readConfigurationUntil(
    bool Function(BikeConfiguration configuration) matches,
  ) async {
    var confirmed = await _readConfiguration();
    for (final delay in _confirmationRetryDelays) {
      if (matches(confirmed)) {
        return confirmed;
      }
      await Future<void>.delayed(delay);
      confirmed = await _readConfiguration();
    }
    return confirmed;
  }

  Future<BikeConfiguration> _readConfiguration() async {
    await _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.registerSelector,
        value: BikeGatt.selectCurrentState,
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
    final decoded = BikeProtocol.decodeState(frame);
    return _preferredRegion == null
        ? decoded
        : decoded.copyWith(region: _preferredRegion);
  }

  Future<void> _writeConfiguration(BikeConfiguration configuration) {
    return _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.stateRegister,
        value: BikeProtocol.encodeConfiguration(configuration),
      ),
      'Writing bike settings',
    );
  }

  BikeConfiguration _effectiveConfiguration(BikeConfiguration observed) {
    return BikeConfiguration(
      light: _preferences.keepLight
          ? _preferences.desiredLight
          : observed.light,
      mode: _preferences.keepMode ? _preferences.desiredMode : observed.mode,
      assist: _preferences.keepAssist
          ? _preferences.desiredAssist
          : observed.assist,
      region: _preferredRegion ?? observed.region,
    );
  }

  bool _lockedValuesMatch(
    BikeConfiguration observed,
    BikeConfiguration target,
  ) {
    return (!_preferences.keepLight || observed.light == target.light) &&
        (!_preferences.keepMode || observed.mode == target.mode) &&
        (!_preferences.keepAssist || observed.assist == target.assist);
  }

  bool _sameEnforcement(RidePreferences previous, RidePreferences next) {
    return previous.keepLight == next.keepLight &&
        (!next.keepLight || previous.desiredLight == next.desiredLight) &&
        previous.keepMode == next.keepMode &&
        (!next.keepMode || previous.desiredMode == next.desiredMode) &&
        previous.keepAssist == next.keepAssist &&
        (!next.keepAssist || previous.desiredAssist == next.desiredAssist);
  }

  void _markReady(BikeConfiguration configuration) {
    _pending.value = null;
    _state.value = SessionReady(configuration: configuration);
    if (_pollInterval case final interval?) {
      _pollTimer = Timer.periodic(interval, (_) {
        if (!_commands.isBusy && _state.peek() is SessionReady) {
          unawaited(synchronize().catchError((Object _) {}));
        }
      });
    }
  }

  Future<void> _enqueueDisconnect({required bool manuallyPaused}) {
    _generation++;
    _expectedDisconnect = true;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    return _commands.add(() => _disconnectNow(manuallyPaused: manuallyPaused));
  }

  Future<void> _disconnectNow({required bool manuallyPaused}) async {
    _hasObservedConnection = false;
    try {
      await _timed(connection.disconnect(), 'Disconnecting');
    } on Object {
      // The local session is still paused even if the platform already lost
      // the link before it could acknowledge the disconnect.
    }
    _state.value = SessionDisconnected(manuallyPaused: manuallyPaused);
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
    _generation++;
    _pollTimer?.cancel();
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
    if (_reconnectAttempt >= _reconnectDelays.length) {
      _state.value = SessionFailed(failure: failure, canRetry: true);
      return;
    }
    final delay = _reconnectDelays[_reconnectAttempt];
    _reconnectAttempt++;
    _state.value = SessionReconnecting(
      attempt: _reconnectAttempt,
      retryAfter: delay,
    );
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && !_manualReconnectPaused && !_foregroundPaused) {
        unawaited(_enqueueConnect());
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
      final BikeProtocolFailure failure => _ProtocolSessionFailure(failure),
      _ => BikeSessionTransportFailure(error),
    };
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

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
