import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:superduper/src/ble/bike_protocol.dart';
import 'package:superduper/src/ble/bike_transport.dart';

const _adapterReadyTimeout = Duration(seconds: 3);
const _operationTimeoutSeconds = 10;

final class FlutterBlueBikeTransport implements BikeTransport {
  final Set<_FlutterBlueBikeConnection> _connections = {};
  var _disposed = false;

  @override
  Stream<BikeAdapterState> get adapterStates {
    return fbp.FlutterBluePlus.adapterState.map(_mapAdapterState).distinct();
  }

  @override
  Stream<List<DiscoveredBike>> get scanResults {
    return fbp.FlutterBluePlus.scanResults.map((results) {
      final bikes = results
          .map(
            (result) => DiscoveredBike(
              deviceId: result.device.remoteId.str,
              name: result.advertisementData.advName.isNotEmpty
                  ? result.advertisementData.advName
                  : result.device.platformName,
              rssi: result.rssi,
            ),
          )
          .toList();
      bikes.sort((left, right) => right.rssi.compareTo(left.rssi));
      return List.unmodifiable(bikes);
    });
  }

  @override
  Stream<bool> get scanning => fbp.FlutterBluePlus.isScanning.distinct();

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _ensureNotDisposed();
    try {
      await fbp.FlutterBluePlus.startScan(
        timeout: timeout,
        withKeywords: const ['SUPER73', 'S73 FTEX'],
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Bluetooth scan',
        'The scan could not be started.',
      );
    }
  }

  @override
  Future<void> stopScan() async {
    if (_disposed) {
      return;
    }
    try {
      await fbp.FlutterBluePlus.stopScan();
    } on Object {
      throw const BikeConnectionFailure(
        'Bluetooth scan',
        'The scan could not be stopped.',
      );
    }
  }

  @override
  BikeConnection openConnection(String deviceId) {
    _ensureNotDisposed();
    final connection = _FlutterBlueBikeConnection(
      device: fbp.BluetoothDevice.fromId(deviceId),
      onDisposed: _connections.remove,
    );
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (fbp.FlutterBluePlus.isScanningNow) {
      await fbp.FlutterBluePlus.stopScan();
    }
    final connections = _connections.toList(growable: false);
    _connections.clear();
    for (final connection in connections) {
      await connection.dispose();
    }
  }

  BikeAdapterState _mapAdapterState(fbp.BluetoothAdapterState state) {
    return switch (state) {
      fbp.BluetoothAdapterState.on => BikeAdapterState.on,
      fbp.BluetoothAdapterState.off ||
      fbp.BluetoothAdapterState.turningOff ||
      fbp.BluetoothAdapterState.turningOn => BikeAdapterState.off,
      fbp.BluetoothAdapterState.unauthorized => BikeAdapterState.unauthorized,
      fbp.BluetoothAdapterState.unavailable => BikeAdapterState.unavailable,
      fbp.BluetoothAdapterState.unknown => BikeAdapterState.unknown,
    };
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('The Bluetooth transport is disposed.');
    }
  }
}

final class _FlutterBlueBikeConnection implements BikeConnection {
  _FlutterBlueBikeConnection({
    required this._device,
    required this._onDisposed,
  });

  final fbp.BluetoothDevice _device;
  final bool Function(_FlutterBlueBikeConnection) _onDisposed;
  final Map<String, fbp.BluetoothCharacteristic> _characteristics = {};
  var _disposed = false;

  @override
  String get deviceId => _device.remoteId.str;

  @override
  Stream<BikeConnectionState> get states {
    return _device.connectionState.map((state) {
      return switch (state) {
        fbp.BluetoothConnectionState.connected => BikeConnectionState.connected,
        fbp.BluetoothConnectionState.disconnected =>
          BikeConnectionState.disconnected,
      };
    }).distinct();
  }

  @override
  Future<void> connect() async {
    _ensureNotDisposed();
    try {
      if (fbp.FlutterBluePlus.adapterStateNow != fbp.BluetoothAdapterState.on) {
        await fbp.FlutterBluePlus.adapterState
            .where((state) => state == fbp.BluetoothAdapterState.on)
            .first
            .timeout(_adapterReadyTimeout);
      }
      if (_device.isConnected) {
        return;
      }
      await _device.connect(
        license: fbp.License.nonprofit,
        timeout: const Duration(seconds: _operationTimeoutSeconds),
        mtu: null,
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Connection',
        'The bike could not be reached.',
      );
    }
  }

  @override
  Future<void> discoverRequiredGatt() async {
    _ensureNotDisposed();
    try {
      final services = await _device.discoverServices(
        timeout: _operationTimeoutSeconds,
      );
      final metricsUuid = fbp.Guid.fromString(BikeGatt.metricsService);
      final metrics = services.where((service) => service.uuid == metricsUuid);
      if (metrics.isEmpty) {
        throw const BikeGattNotSupported(
          'The required metrics service was not found.',
        );
      }

      final required = {
        BikeGatt.registerSelector: fbp.Guid.fromString(
          BikeGatt.registerSelector,
        ),
        BikeGatt.stateRegister: fbp.Guid.fromString(BikeGatt.stateRegister),
      };
      _characteristics.clear();
      for (final characteristic in metrics.single.characteristics) {
        for (final entry in required.entries) {
          if (characteristic.uuid == entry.value) {
            _characteristics[entry.key] = characteristic;
          }
        }
      }

      final selector = _characteristics[BikeGatt.registerSelector];
      final state = _characteristics[BikeGatt.stateRegister];
      if (selector == null || state == null) {
        throw const BikeGattNotSupported(
          'The required bike registers were not found.',
        );
      }
      if (!_canWrite(selector) || !state.properties.read || !_canWrite(state)) {
        throw const BikeGattNotSupported(
          'The bike registers do not support the required operations.',
        );
      }
    } on BikeGattNotSupported {
      rethrow;
    } on Object {
      throw const BikeConnectionFailure(
        'Service discovery',
        'The bike services could not be inspected.',
      );
    }
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    _ensureService(serviceUuid);
    final characteristic = _requireCharacteristic(characteristicUuid);
    try {
      return List.unmodifiable(
        await characteristic.read(timeout: _operationTimeoutSeconds),
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Read',
        'The bike did not return its settings.',
      );
    }
  }

  @override
  Future<void> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
  }) async {
    _ensureService(serviceUuid);
    final characteristic = _requireCharacteristic(characteristicUuid);
    try {
      await characteristic.write(
        value,
        withoutResponse:
            !characteristic.properties.write &&
            characteristic.properties.writeWithoutResponse,
        timeout: _operationTimeoutSeconds,
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Write',
        'The bike did not accept its settings.',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disposed || _device.isDisconnected) {
      return;
    }
    try {
      await _device.disconnect(timeout: _operationTimeoutSeconds, queue: false);
    } on Object {
      throw const BikeConnectionFailure(
        'Disconnect',
        'The bike connection could not be closed cleanly.',
      );
    } finally {
      _characteristics.clear();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    try {
      if (_device.isConnected) {
        await _device.disconnect(
          timeout: _operationTimeoutSeconds,
          queue: false,
        );
      }
    } finally {
      _disposed = true;
      _characteristics.clear();
      _onDisposed(this);
    }
  }

  bool _canWrite(fbp.BluetoothCharacteristic characteristic) {
    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }

  fbp.BluetoothCharacteristic _requireCharacteristic(String uuid) {
    _ensureNotDisposed();
    final characteristic = _characteristics[uuid];
    if (characteristic == null) {
      throw const BikeGattNotSupported(
        'The bike services must be discovered before use.',
      );
    }
    return characteristic;
  }

  void _ensureService(String uuid) {
    if (uuid.toLowerCase() != BikeGatt.metricsService) {
      throw const BikeGattNotSupported('An unsupported service was requested.');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('The bike connection is disposed.');
    }
  }
}
