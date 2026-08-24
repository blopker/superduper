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
typedef VersionsRead = Future<void> Function(BikeVersionInfo versions);

final class BikeSession {
  BikeSession({
    required this.connection,
    required BikeRegion? preferredRegion,
    required RidePreferences preferences,
    BikeProtocolVersion? protocolHint,
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
    // ignore: prefer_initializing_formals
  }) : _preferredRegion = preferredRegion,
       // ignore: prefer_initializing_formals
       _protocolHint = protocolHint,
       _authenticationKey = List<int>.unmodifiable(authenticationKey),
       // ignore: prefer_initializing_formals
       _preferences = preferences,
       // ignore: prefer_initializing_formals
       _onConfigurationConfirmed = onConfigurationConfirmed,
       // ignore: prefer_initializing_formals
       _onVersionsRead = onVersionsRead,
       // ignore: prefer_initializing_formals
       _commandTimeout = commandTimeout,
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
  final BikeProtocolVersion? _protocolHint;
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
  BikeProtocolVersion? _protocolVersion;
  String? _firmwareRevision;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _synchronizationRetryTimer;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _synchronizationRetryAttempt = 0;
  var _disposed = false;
  var _manualReconnectPaused = false;
  var _foregroundPaused = false;
  var _expectedDisconnect = false;
  var _hasObservedConnection = false;

  String get deviceId => connection.deviceId;
  ReadonlySignal<BikeSessionState> get state => _state.readonly();
  ReadonlySignal<BikeConfiguration?> get observed => _observed.readonly();
  ReadonlySignal<BikeConfiguration?> get pending => _pending.readonly();
  ReadonlySignal<BikeVersionInfo?> get versions => _versions.readonly();
  bool get manualReconnectPaused => _manualReconnectPaused;
  BikeProtocolVersion? get protocolVersion => _protocolVersion;

  Future<void> connect() {
    _ensureNotDisposed();
    _manualReconnectPaused = false;
    _foregroundPaused = false;
    _reconnectAttempt = 0;
    _synchronizationRetryAttempt = 0;
    _reconnectTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
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
        if (failure is BikeSettingsNotApplied && _hasObservedConnection) {
          _scheduleSynchronizationRetry(failure);
        } else if (_isConnectionFailure(failure)) {
          _scheduleReconnect(failure);
        } else {
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
    _synchronizationRetryTimer?.cancel();
    _commands.dispose();
    await _commands.done;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    await _disableNotifications(updatePeripheral: true);
    await _connectionSubscription.cancel();
    await connection.dispose();
    _state.value = const SessionDisposed();
    _state.dispose();
    _observed.dispose();
    _pending.dispose();
    _versions.dispose();
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
      await _disableNotifications(updatePeripheral: false);
      _protocolVersion = null;
      _firmwareRevision = null;
      _versions.value = null;
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
        var protocol = await _identifyProtocolBeforeAuthentication();
        _state.value = const SessionAuthenticating();
        await _authenticate();
        if (!_isCurrent(generation)) {
          return;
        }
        protocol ??= await _identifyProtocolFromHistory();
        if (protocol == null) {
          throw const BikeProtocolNotSupported(
            'No documented identity or history record was found.',
          );
        }
        _protocolVersion = protocol;
        await _refreshVersions();
        await _enableNotifications();
        if (!_isCurrent(generation)) {
          return;
        }
        _state.value = const SessionConnected();
        await _synchronizeNow(forceLockedWrite: true);
        _reconnectAttempt = 0;
      } on Object catch (error) {
        if (!_isCurrent(generation)) {
          return;
        }
        final failure = _asFailure(error);
        if (failure is BikeSettingsNotApplied && _hasObservedConnection) {
          _scheduleSynchronizationRetry(failure);
        } else if (failure is _ProtocolSessionFailure ||
            failure is BikeAuthenticationFailed ||
            failure is BikeProtocolNotSupported) {
          _state.value = SessionFailed(failure: failure, canRetry: true);
        } else {
          _scheduleReconnect(failure);
        }
      }
    });
  }

  Future<BikeProtocolVersion?> _identifyProtocolBeforeAuthentication() async {
    final hint = _protocolHint;
    if (!connection.hasCharacteristic(
      serviceUuid: BikeGatt.deviceInformationService,
      characteristicUuid: BikeGatt.firmwareRevision,
    )) {
      return hint;
    }

    final value = await _timed(
      connection.readCharacteristic(
        serviceUuid: BikeGatt.deviceInformationService,
        characteristicUuid: BikeGatt.firmwareRevision,
      ),
      'Reading firmware revision',
    );
    late final String revision;
    try {
      revision = _decodeRevision(value);
    } on FormatException {
      throw const BikeProtocolNotSupported(
        'The firmware revision was not valid text.',
      );
    }
    final discovered = BikeProtocolVersion.fromFirmwareRevision(revision);
    if (discovered == null) {
      throw BikeProtocolNotSupported(
        'Firmware revision "$revision" is unknown.',
      );
    }
    if (hint != null && hint != discovered) {
      throw BikeProtocolNotSupported(
        'The advertised name and firmware revision disagree.',
      );
    }
    _firmwareRevision = revision;
    return discovered;
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
      final firmware =
          _firmwareRevision ??
          _decodeRevision(
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
    try {
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
    } on BikeAuthenticationFailed {
      rethrow;
    } on Object catch (error) {
      throw BikeAuthenticationFailed(error.toString());
    }
  }

  Future<BikeProtocolVersion?> _identifyProtocolFromHistory() async {
    final v2 = await _tryReadHistoryRecord(BikeGatt.v2ModeSelector);
    if (v2 != null) {
      return BikeProtocolVersion.v2;
    }
    final v1 = await _tryReadHistoryRecord(BikeGatt.v1StateSelector);
    if (v1 != null) {
      return BikeProtocolVersion.v1;
    }
    return null;
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
    final protocol = _protocolVersion;
    if (_disposed || protocol == null) {
      return;
    }
    try {
      var updated = BikeProtocol.applyTelemetry(
        version: protocol,
        packet: packet,
        current: _observed.peek(),
      );
      if (updated == null) {
        return;
      }
      if (_preferredRegion case final region?) {
        updated = updated.copyWith(region: region);
      }
      _publishObserved(updated);
      if (_state.peek() is SessionReady &&
          !_lockedValuesMatch(updated, _effectiveConfiguration(updated)) &&
          !_commands.isBusy) {
        unawaited(synchronize().catchError((Object _) {}));
      }
    } on BikeProtocolFailure catch (failure) {
      _pollTimer?.cancel();
      _state.value = SessionFailed(
        failure: _ProtocolSessionFailure(failure),
        canRetry: true,
      );
    }
  }

  void _onTelemetryError(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      _scheduleReconnect(BikeSessionTransportFailure(error));
    }
  }

  void _publishObserved(BikeConfiguration configuration) {
    _observed.value = configuration;
  }

  Future<void> _synchronizeNow({bool forceLockedWrite = false}) async {
    _pollTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
    var confirmed = await _readConfiguration();
    _publishObserved(confirmed);
    var mustWrite = forceLockedWrite && _hasLockedSettings;

    for (var attempt = 1; attempt <= _correctiveAttempts; attempt++) {
      final target = _effectiveConfiguration(confirmed);
      if (!mustWrite && _lockedValuesMatch(confirmed, target)) {
        _markReady(confirmed);
        return;
      }
      _state.value = SessionSynchronizing(attempt: attempt);
      _pending.value = target;
      await _writeConfiguration(target);
      mustWrite = false;
      confirmed = await _readConfigurationUntil(
        (candidate) => _lockedValuesMatch(candidate, target),
      );
      _publishObserved(confirmed);
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
      _synchronizationRetryTimer?.cancel();
      _pending.value = target;
      _state.value = const SessionSynchronizing(attempt: 1);
      late BikeConfiguration confirmed;
      try {
        await _writeConfiguration(target);
        confirmed = await _readConfigurationUntil(
          (candidate) => candidate == target,
        );
        _publishObserved(confirmed);
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
        } else if (_isConnectionFailure(failure)) {
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
    if (_confirmationRetryDelays.isEmpty) {
      final confirmed = await _readConfiguration();
      _publishObserved(confirmed);
      return confirmed;
    }

    BikeConfiguration? confirmed;
    for (final delay in _confirmationRetryDelays) {
      await Future<void>.delayed(delay);
      confirmed = await _readConfiguration();
      _publishObserved(confirmed);
      if (matches(confirmed)) {
        return confirmed;
      }
    }
    return confirmed ?? await _readConfiguration();
  }

  Future<BikeConfiguration> _readConfiguration() async {
    final version = _protocolVersion;
    if (version == null) {
      throw const BikeProtocolNotSupported(
        'The protocol version was not identified.',
      );
    }
    switch (version) {
      case BikeProtocolVersion.v1:
        final decoded = BikeProtocol.decodeV1State(
          await _readHistoryRecord(BikeGatt.v1StateSelector),
        );
        final preferredRegion = _preferredRegion;
        return preferredRegion == null
            ? decoded
            : decoded.copyWith(region: preferredRegion);
      case BikeProtocolVersion.v2:
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
    final version = _protocolVersion;
    if (version == null) {
      throw const BikeProtocolNotSupported(
        'The protocol version was not identified.',
      );
    }
    return _timed(
      connection.writeCharacteristic(
        serviceUuid: BikeGatt.metricsService,
        characteristicUuid: BikeGatt.stateRegister,
        value: BikeProtocol.encodeConfiguration(
          configuration,
          version: version,
        ),
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

  bool get _hasLockedSettings =>
      _preferences.keepLight ||
      _preferences.keepMode ||
      _preferences.keepAssist;

  void _markReady(BikeConfiguration configuration) {
    _synchronizationRetryTimer?.cancel();
    _synchronizationRetryAttempt = 0;
    _reconnectAttempt = 0;
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
    _synchronizationRetryTimer?.cancel();
    return _commands.add(() => _disconnectNow(manuallyPaused: manuallyPaused));
  }

  Future<void> _disconnectNow({required bool manuallyPaused}) async {
    _hasObservedConnection = false;
    await _disableNotifications(updatePeripheral: true);
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
    if (_state.peek() is SessionAuthenticating) {
      return;
    }
    _generation++;
    _pollTimer?.cancel();
    _synchronizationRetryTimer?.cancel();
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
    );
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && !_manualReconnectPaused && !_foregroundPaused) {
        unawaited(_enqueueConnect());
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
      _state.value = SessionFailed(failure: failure, canRetry: true);
      return;
    }
    final delayIndex =
        _synchronizationRetryAttempt < _synchronizationRetryDelays.length
        ? _synchronizationRetryAttempt
        : _synchronizationRetryDelays.length - 1;
    final delay = _synchronizationRetryDelays[delayIndex];
    _synchronizationRetryAttempt++;
    _pending.value = null;
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
      final BikeProtocolFailure failure => _ProtocolSessionFailure(failure),
      _ => BikeSessionTransportFailure(error),
    };
  }

  bool _isConnectionFailure(BikeSessionFailure failure) {
    return failure is BikeSessionTransportFailure ||
        failure is BikeCommandTimedOut;
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
