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
    return fbp.FlutterBluePlus.onScanResults.map((results) {
      final bikes = results
          .map(
            (result) => DiscoveredBike(
              deviceId: result.device.remoteId.str,
              name: result.advertisementData.advName.isNotEmpty
                  ? result.advertisementData.advName
                  : result.device.platformName,
              rssi: result.rssi,
              moduleSerial: BikeProtocol.decodeModuleSerial(
                result.advertisementData.manufacturerData[BikeGatt
                    .manufacturerId],
              ),
            ),
          )
          .toList();
      return List.unmodifiable(
        bikes..sort((left, right) => right.rssi.compareTo(left.rssi)),
      );
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
        continuousUpdates: true,
        continuousDivisor: 2,
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
      final adapterState = fbp.FlutterBluePlus.adapterStateNow;
      if (adapterState == fbp.BluetoothAdapterState.unauthorized) {
        throw const BikeAdapterUnavailable(
          'Bluetooth permission is not authorized on this device.',
          canRetry: false,
        );
      }
      if (adapterState == fbp.BluetoothAdapterState.unavailable) {
        throw const BikeAdapterUnavailable(
          'Bluetooth is unavailable on this device.',
          canRetry: false,
        );
      }
      if (adapterState != fbp.BluetoothAdapterState.on) {
        try {
          await fbp.FlutterBluePlus.adapterState
              .where((state) => state == fbp.BluetoothAdapterState.on)
              .first
              .timeout(_adapterReadyTimeout);
        } on TimeoutException {
          throw const BikeAdapterUnavailable(
            'Bluetooth is off. Turn it on to connect to the bike.',
          );
        }
      }
      if (_device.isConnected) {
        return;
      }
      await _device.connect(
        license: fbp.License.nonprofit,
        timeout: const Duration(seconds: _operationTimeoutSeconds),
        mtu: null,
      );
    } on BikeAdapterUnavailable {
      rethrow;
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
      _characteristics.clear();
      final supportedServices = {
        BikeGatt.metricsService,
        BikeGatt.authenticationService,
        BikeGatt.deviceInformationService,
      };
      for (final service in services) {
        final serviceUuid = service.uuid.str128.toLowerCase();
        if (!supportedServices.contains(serviceUuid)) {
          continue;
        }
        for (final characteristic in service.characteristics) {
          final characteristicUuid = characteristic.uuid.str128.toLowerCase();
          if (_knownCharacteristics.contains(characteristicUuid)) {
            _characteristics[_characteristicKey(
                  serviceUuid,
                  characteristicUuid,
                )] =
                characteristic;
          }
        }
      }

      final selector = _findCharacteristic(
        BikeGatt.metricsService,
        BikeGatt.registerSelector,
      );
      final state = _findCharacteristic(
        BikeGatt.metricsService,
        BikeGatt.stateRegister,
      );
      final telemetry = _findCharacteristic(
        BikeGatt.metricsService,
        BikeGatt.telemetry,
      );
      final challenge = _findCharacteristic(
        BikeGatt.authenticationService,
        BikeGatt.authenticationChallenge,
      );
      final response = _findCharacteristic(
        BikeGatt.authenticationService,
        BikeGatt.authenticationResponse,
      );
      final authenticationState = _findCharacteristic(
        BikeGatt.authenticationService,
        BikeGatt.authenticationState,
      );
      if (selector == null ||
          state == null ||
          telemetry == null ||
          challenge == null ||
          response == null ||
          authenticationState == null) {
        throw const BikeGattNotSupported(
          'The required bike or authentication characteristics were not found.',
        );
      }
      if (!_canWrite(selector) ||
          !state.properties.read ||
          !_canWrite(state) ||
          (!telemetry.properties.notify && !telemetry.properties.indicate) ||
          !challenge.properties.read ||
          !_canWrite(response) ||
          !authenticationState.properties.read) {
        throw const BikeGattNotSupported(
          'The bike characteristics do not support the required operations.',
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
  bool hasCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    _ensureNotDisposed();
    return _findCharacteristic(serviceUuid, characteristicUuid) != null;
  }

  @override
  Future<List<int>> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    _ensureService(serviceUuid);
    final characteristic = _requireCharacteristic(
      serviceUuid,
      characteristicUuid,
    );
    try {
      return List.unmodifiable(
        await characteristic.read(timeout: _operationTimeoutSeconds),
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Read',
        'The bike did not return the requested value.',
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
    final characteristic = _requireCharacteristic(
      serviceUuid,
      characteristicUuid,
    );
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
        'The bike did not accept the requested value.',
      );
    }
  }

  @override
  Stream<List<int>> characteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    _ensureService(serviceUuid);
    final characteristic = _requireCharacteristic(
      serviceUuid,
      characteristicUuid,
    );
    return characteristic.onValueReceived.map(
      List<int>.unmodifiable,
    );
  }

  @override
  Future<void> setCharacteristicNotifications({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    _ensureService(serviceUuid);
    final characteristic = _requireCharacteristic(
      serviceUuid,
      characteristicUuid,
    );
    if (!characteristic.properties.notify &&
        !characteristic.properties.indicate) {
      throw const BikeGattNotSupported(
        'The requested characteristic does not support notifications.',
      );
    }
    try {
      await characteristic.setNotifyValue(
        enabled,
        timeout: _operationTimeoutSeconds,
      );
    } on Object {
      throw const BikeConnectionFailure(
        'Notifications',
        'The bike notification stream could not be configured.',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disposed) {
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
      await _device.disconnect(timeout: _operationTimeoutSeconds, queue: false);
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

  fbp.BluetoothCharacteristic? _findCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    return _characteristics[_characteristicKey(
      serviceUuid,
      characteristicUuid,
    )];
  }

  fbp.BluetoothCharacteristic _requireCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    _ensureNotDisposed();
    final characteristic = _findCharacteristic(serviceUuid, characteristicUuid);
    if (characteristic == null) {
      throw const BikeGattNotSupported(
        'The bike services must be discovered before use.',
      );
    }
    return characteristic;
  }

  void _ensureService(String uuid) {
    if (!_supportedServiceUuids.contains(uuid.toLowerCase())) {
      throw const BikeGattNotSupported('An unsupported service was requested.');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('The bike connection is disposed.');
    }
  }

  String _characteristicKey(String serviceUuid, String characteristicUuid) {
    return '${serviceUuid.toLowerCase()}/${characteristicUuid.toLowerCase()}';
  }
}

const Set<String> _supportedServiceUuids = {
  BikeGatt.metricsService,
  BikeGatt.authenticationService,
  BikeGatt.deviceInformationService,
};

const Set<String> _knownCharacteristics = {
  BikeGatt.telemetry,
  BikeGatt.stateRegister,
  BikeGatt.registerSelector,
  BikeGatt.authenticationKeyUpdate,
  BikeGatt.authenticationChallenge,
  BikeGatt.authenticationResponse,
  BikeGatt.authenticationState,
  BikeGatt.firmwareRevision,
  BikeGatt.hardwareRevision,
  BikeGatt.softwareRevision,
};
