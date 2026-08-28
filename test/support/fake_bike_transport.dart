import 'dart:async';

import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

List<int> v1StateFrame({
  bool light = false,
  int mode = 0,
  int assist = 0,
}) => [0, 0, assist, 0, if (light) 1 else 0, mode];

final class FakeBluetoothPermissionGateway
    implements BluetoothPermissionGateway {
  BluetoothPermissionState state = BluetoothPermissionState.granted;
  BluetoothScanPrerequisite scanPrerequisite = BluetoothScanPrerequisite.ready;
  Object? ensureError;
  Duration ensureDelay = Duration.zero;
  Completer<void>? ensureGate;
  int requests = 0;
  int checks = 0;
  int concurrentChecks = 0;
  int maxConcurrentChecks = 0;
  int settingsOpens = 0;

  @override
  Future<BluetoothPermissionState> ensureAccess({required bool request}) async {
    checks++;
    concurrentChecks++;
    if (concurrentChecks > maxConcurrentChecks) {
      maxConcurrentChecks = concurrentChecks;
    }
    if (request) {
      requests++;
    }
    try {
      if (ensureDelay > Duration.zero) {
        await Future<void>.delayed(ensureDelay);
      }
      await ensureGate?.future;
      if (ensureError case final error?) {
        _throw(error);
      }
      return state;
    } finally {
      concurrentChecks--;
    }
  }

  @override
  Future<BluetoothScanPrerequisite> checkScanPrerequisite() async {
    return scanPrerequisite;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpens++;
    return true;
  }
}

final class FakeBikeTransport implements BikeTransport {
  final StreamController<BikeAdapterState> _adapter =
      StreamController.broadcast();
  final StreamController<List<DiscoveredBike>> _results =
      StreamController.broadcast();
  final StreamController<bool> _scanning = StreamController.broadcast();
  final Map<String, FakeBikeConnection> connections = {};
  final Map<String, List<List<int>>> readFramesOnOpen = {};

  BikeAdapterState currentAdapterState = BikeAdapterState.on;
  List<DiscoveredBike> replayedScanResults = const [];
  int scanStarts = 0;
  int scanStops = 0;
  Object? stopScanError;
  bool isDisposed = false;

  @override
  Stream<BikeAdapterState> get adapterStates async* {
    yield currentAdapterState;
    yield* _adapter.stream;
  }

  @override
  Stream<List<DiscoveredBike>> get scanResults async* {
    if (replayedScanResults.isNotEmpty) {
      yield replayedScanResults;
    }
    yield* _results.stream;
  }

  @override
  Stream<bool> get scanning async* {
    yield false;
    yield* _scanning.stream;
  }

  void emitAdapter(BikeAdapterState state) {
    currentAdapterState = state;
    _adapter.add(state);
  }

  void emitResults(List<DiscoveredBike> results) {
    _results.add(results);
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    scanStarts++;
    _scanning.add(true);
  }

  @override
  Future<void> stopScan() async {
    scanStops++;
    if (stopScanError case final error?) {
      _throw(error);
    }
    _scanning.add(false);
  }

  @override
  BikeConnection openConnection(String deviceId) {
    final existing = connections[deviceId];
    if (existing != null && !existing.isDisposed) {
      return existing;
    }
    final connection = FakeBikeConnection(deviceId: deviceId);
    connection.readFrames.addAll(
      readFramesOnOpen[deviceId]?.map(List<int>.from) ?? const [],
    );
    connections[deviceId] = connection;
    return connection;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _adapter.close();
    await _results.close();
    await _scanning.close();
    for (final connection in connections.values) {
      await connection.dispose();
    }
  }
}

final class CharacteristicWrite {
  const CharacteristicWrite({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.value,
  });

  final String serviceUuid;
  final String characteristicUuid;
  final List<int> value;
}

final class CharacteristicRead {
  const CharacteristicRead({
    required this.serviceUuid,
    required this.characteristicUuid,
  });

  final String serviceUuid;
  final String characteristicUuid;
}

final class FakeBikeConnection implements BikeConnection {
  FakeBikeConnection({required this.deviceId});

  @override
  final String deviceId;
  final StreamController<BikeConnectionState> _states =
      StreamController.broadcast();
  final StreamController<List<int>> _notifications =
      StreamController.broadcast();
  final List<List<int>> readFrames = [];
  final List<CharacteristicWrite> writes = [];
  final List<CharacteristicRead> reads = [];
  final Set<String> missingCharacteristics = {};
  List<int> authenticationChallenge = List<int>.generate(20, (index) => index);
  List<int> authenticationKey = List<int>.from(
    BikeProtocol.defaultAuthenticationKey,
  );
  String? hardwareRevision = 'v3.2.0';
  String? firmwareRevision = '221122';
  String? softwareRevision = '221122';
  List<int> displayVersionFrame = [
    0xfc,
    0xfc,
    0x01,
    0x02,
    0x03,
    0x96,
    0x01,
    0x08,
    0x00,
    0x01,
  ];
  List<int> componentVersionsFrame = [
    0xfa,
    0xfa,
    0x12,
    0x34,
    0x56,
    0x78,
    0xab,
    0xcd,
    0xef,
    0x01,
  ];
  int odometerMeters = 123456;
  Object? connectError;
  Object? discoveryError;
  Object? readError;
  final Map<String, Object> readErrors = {};
  Object? writeError;
  bool emitInitialDisconnectedState = false;
  Duration operationDelay = Duration.zero;
  Completer<void>? operationGate;
  Completer<void>? configurationWriteGate;
  Completer<void>? connectGate;
  Completer<void>? disconnectGate;
  Completer<void>? _connectCancellation;
  int connectCalls = 0;
  int discoveryCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool isDisposed = false;
  int concurrentOperations = 0;
  int maxConcurrentOperations = 0;
  int notificationChanges = 0;
  int configurationWriteStarts = 0;
  bool notificationsEnabled = false;
  bool authenticated = false;
  List<int>? selectedHistoryId;
  bool delayHistorySelectionUntilRead = false;
  List<int>? _pendingHistoryId;
  List<int>? _retainedHistoryFrame;

  @override
  Stream<BikeConnectionState> get states => _states.stream;

  void emitState(BikeConnectionState state) => _states.add(state);

  @override
  Future<void> connect() async {
    connectCalls++;
    final gate = connectGate;
    final cancellation = Completer<void>();
    _connectCancellation = cancellation;
    try {
      if (gate != null) {
        await Future.any([gate.future, cancellation.future]);
      }
      if (cancellation.isCompleted) {
        throw const BikeConnectionFailure(
          'Connection',
          'The connection was cancelled.',
        );
      }
      await _operate(() async {
        authenticated = false;
        notificationsEnabled = false;
        if (emitInitialDisconnectedState) {
          _states.add(BikeConnectionState.disconnected);
        }
        if (connectError case final error?) {
          _throw(error);
        }
        _states.add(BikeConnectionState.connected);
      });
    } finally {
      if (identical(_connectCancellation, cancellation)) {
        _connectCancellation = null;
      }
    }
  }

  @override
  Future<void> discoverRequiredGatt() async {
    discoveryCalls++;
    await _operate(() async {
      if (discoveryError case final error?) {
        _throw(error);
      }
    });
  }

  @override
  bool hasCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    if (missingCharacteristics.contains(characteristicUuid)) {
      return false;
    }
    return switch (characteristicUuid) {
      BikeGatt.hardwareRevision => hardwareRevision != null,
      BikeGatt.firmwareRevision => firmwareRevision != null,
      BikeGatt.softwareRevision => softwareRevision != null,
      _ => true,
    };
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _operate(() async {
      reads.add(
        CharacteristicRead(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
        ),
      );
      if (readError case final error?) {
        _throw(error);
      }
      if (readErrors[characteristicUuid] case final error?) {
        _throw(error);
      }
      if (!hasCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      )) {
        throw const BikeGattNotSupported('Fake characteristic is missing.');
      }
      switch (characteristicUuid) {
        case BikeGatt.hardwareRevision:
          return List<int>.unmodifiable(hardwareRevision!.codeUnits);
        case BikeGatt.firmwareRevision:
          return List<int>.unmodifiable(firmwareRevision!.codeUnits);
        case BikeGatt.softwareRevision:
          return List<int>.unmodifiable(softwareRevision!.codeUnits);
        case BikeGatt.authenticationChallenge:
          return List<int>.unmodifiable(authenticationChallenge);
        case BikeGatt.authenticationState:
          return [if (authenticated) 1 else 0];
      }
      if (!authenticated) {
        throw StateError('The fake bike is not authenticated.');
      }
      try {
        if (_sameBytes(selectedHistoryId, BikeGatt.displayVersionSelector)) {
          return List<int>.unmodifiable(displayVersionFrame);
        }
        if (_sameBytes(selectedHistoryId, BikeGatt.componentVersionsSelector)) {
          return List<int>.unmodifiable(componentVersionsFrame);
        }
        if (_sameBytes(selectedHistoryId, BikeGatt.v1OdometerSelector)) {
          return List<int>.unmodifiable([
            ...BikeGatt.v1OdometerSelector,
            0,
            0,
            0,
            0,
            odometerMeters & 0xff,
            (odometerMeters >> 8) & 0xff,
            (odometerMeters >> 16) & 0xff,
            (odometerMeters >> 24) & 0xff,
          ]);
        }
        if (readFrames.isEmpty) {
          if (_retainedHistoryFrame case final retained?) {
            return List<int>.unmodifiable(retained);
          }
          throw StateError('No fake read frame is queued.');
        }
        final frame = readFrames.removeAt(0);
        if (frame.length == 6 &&
            _sameBytes(selectedHistoryId, BikeGatt.v1StateSelector)) {
          final expanded = [
            3,
            0,
            frame[2],
            frame[3],
            frame[4],
            frame[5],
            0,
            0,
            0,
            0,
          ];
          _retainedHistoryFrame = expanded;
          return List<int>.unmodifiable(expanded);
        }
        _retainedHistoryFrame = List<int>.from(frame);
        return List<int>.unmodifiable(frame);
      } finally {
        if (_pendingHistoryId case final pending?) {
          selectedHistoryId = pending;
          _pendingHistoryId = null;
        }
      }
    });
  }

  @override
  Future<void> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  }) {
    return _operate(() async {
      if (characteristicUuid == BikeGatt.stateRegister) {
        configurationWriteStarts++;
        await configurationWriteGate?.future;
      }
      if (writeError case final error?) {
        _throw(error);
      }
      writes.add(
        CharacteristicWrite(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: List.unmodifiable(value),
        ),
      );
      if (characteristicUuid == BikeGatt.authenticationResponse) {
        final expected = BikeProtocol.authenticationResponse(
          challenge: authenticationChallenge,
          key: authenticationKey,
        );
        authenticated = _sameBytes(value, expected);
        return;
      }
      if (!authenticated) {
        throw StateError('The fake bike is not authenticated.');
      }
      if (characteristicUuid == BikeGatt.registerSelector) {
        if (delayHistorySelectionUntilRead) {
          _pendingHistoryId = List<int>.from(value);
        } else {
          selectedHistoryId = List<int>.from(value);
        }
      }
    });
  }

  @override
  Stream<List<int>> characteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _notifications.stream;
  }

  @override
  Future<void> setCharacteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    await _operate(() async {
      if (!authenticated) {
        throw StateError('The fake bike is not authenticated.');
      }
      notificationsEnabled = enabled;
      notificationChanges++;
    });
  }

  void emitNotification(List<int> value) {
    if (notificationsEnabled) {
      _notifications.add(List<int>.unmodifiable(value));
    }
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    final cancellation = _connectCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
    await disconnectGate?.future;
    authenticated = false;
    notificationsEnabled = false;
    _states.add(BikeConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    isDisposed = true;
    if (!_states.isClosed) {
      await _states.close();
    }
    if (!_notifications.isClosed) {
      await _notifications.close();
    }
  }

  Future<T> _operate<T>(Future<T> Function() operation) async {
    concurrentOperations++;
    if (concurrentOperations > maxConcurrentOperations) {
      maxConcurrentOperations = concurrentOperations;
    }
    try {
      await operationGate?.future;
      if (operationDelay > Duration.zero) {
        await Future<void>.delayed(operationDelay);
      }
      return await operation();
    } finally {
      concurrentOperations--;
    }
  }

  bool _sameBytes(List<int>? left, List<int> right) {
    if (left == null || left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}

Never _throw(Object error) {
  if (error is Error) {
    throw error;
  }
  if (error is Exception) {
    throw error;
  }
  throw StateError('Fake failure: $error');
}
