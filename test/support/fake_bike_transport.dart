import 'dart:async';

import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

final class FakeBluetoothPermissionGateway
    implements BluetoothPermissionGateway {
  BluetoothPermissionState state = BluetoothPermissionState.granted;
  Object? ensureError;
  var requests = 0;
  var settingsOpens = 0;

  @override
  Future<BluetoothPermissionState> ensureAccess({required bool request}) async {
    if (ensureError case final error?) {
      throw error;
    }
    if (request) {
      requests++;
    }
    return state;
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
  var scanStarts = 0;
  var scanStops = 0;
  var isDisposed = false;

  @override
  Stream<BikeAdapterState> get adapterStates async* {
    yield currentAdapterState;
    yield* _adapter.stream;
  }

  @override
  Stream<List<DiscoveredBike>> get scanResults => _results.stream;

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

final class FakeBikeConnection implements BikeConnection {
  FakeBikeConnection({required this.deviceId});

  @override
  final String deviceId;
  final StreamController<BikeConnectionState> _states =
      StreamController.broadcast();
  final List<List<int>> readFrames = [];
  final List<CharacteristicWrite> writes = [];
  Object? connectError;
  Object? discoveryError;
  Object? readError;
  Object? writeError;
  var emitInitialDisconnectedState = false;
  Duration operationDelay = Duration.zero;
  var connectCalls = 0;
  var discoveryCalls = 0;
  var disconnectCalls = 0;
  var disposeCalls = 0;
  var isDisposed = false;
  var concurrentOperations = 0;
  var maxConcurrentOperations = 0;

  @override
  Stream<BikeConnectionState> get states => _states.stream;

  void emitState(BikeConnectionState state) => _states.add(state);

  @override
  Future<void> connect() async {
    connectCalls++;
    await _operate(() async {
      if (emitInitialDisconnectedState) {
        _states.add(BikeConnectionState.disconnected);
      }
      if (connectError case final error?) {
        throw error;
      }
      _states.add(BikeConnectionState.connected);
    });
  }

  @override
  Future<void> discoverRequiredGatt() async {
    discoveryCalls++;
    await _operate(() async {
      if (discoveryError case final error?) {
        throw error;
      }
    });
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _operate(() async {
      if (readError case final error?) {
        throw error;
      }
      if (readFrames.isEmpty) {
        throw StateError('No fake read frame is queued.');
      }
      return List.unmodifiable(readFrames.removeAt(0));
    });
  }

  @override
  Future<void> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  }) {
    return _operate(() async {
      if (writeError case final error?) {
        throw error;
      }
      writes.add(
        CharacteristicWrite(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: List.unmodifiable(value),
        ),
      );
    });
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _states.add(BikeConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    isDisposed = true;
    if (!_states.isClosed) {
      await _states.close();
    }
  }

  Future<T> _operate<T>(Future<T> Function() operation) async {
    concurrentOperations++;
    if (concurrentOperations > maxConcurrentOperations) {
      maxConcurrentOperations = concurrentOperations;
    }
    try {
      if (operationDelay > Duration.zero) {
        await Future<void>.delayed(operationDelay);
      }
      return await operation();
    } finally {
      concurrentOperations--;
    }
  }
}
