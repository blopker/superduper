enum BikeAdapterState { unknown, on, off, unavailable, unauthorized }

enum BikeConnectionState { disconnected, connecting, connected }

final class DiscoveredBike {
  const DiscoveredBike({
    required this.deviceId,
    required this.name,
    required this.rssi,
  });

  final String deviceId;
  final String name;
  final int rssi;
}

sealed class BikeTransportFailure implements Exception {
  const BikeTransportFailure(this.operation, this.message);

  final String operation;
  final String message;

  @override
  String toString() => '$operation: $message';
}

final class BikeAdapterUnavailable extends BikeTransportFailure {
  const BikeAdapterUnavailable(String message) : super('Bluetooth', message);
}

final class BikeConnectionFailure extends BikeTransportFailure {
  const BikeConnectionFailure(super.operation, super.message);
}

final class BikeGattNotSupported extends BikeTransportFailure {
  const BikeGattNotSupported(String message)
    : super('Service discovery', message);
}

abstract interface class BikeTransport {
  Stream<BikeAdapterState> get adapterStates;
  Stream<List<DiscoveredBike>> get scanResults;
  Stream<bool> get scanning;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)});
  Future<void> stopScan();
  BikeConnection openConnection(String deviceId);
  Future<void> dispose();
}

abstract interface class BikeConnection {
  String get deviceId;
  Stream<BikeConnectionState> get states;

  Future<void> connect();
  Future<void> discoverRequiredGatt();
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  });
  Future<void> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  });
  Future<void> disconnect();
  Future<void> dispose();
}
