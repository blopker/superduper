import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';
import 'package:superduper/utils/logger.dart'; // Import the logger

part 'repository.g.dart';

enum SDBluetoothConnectionState {
  disconnected,
  connected,
  connecting,
  disconnecting
}

@riverpod
Stream<BluetoothAdapterState> adapterState(Ref ref) =>
    FlutterBluePlus.adapterState;

@riverpod
Stream<bool> isScanningStatus(Ref ref) => FlutterBluePlus.isScanning;

@riverpod
Stream<List<ScanResult>> scanResults(Ref ref) =>
    FlutterBluePlus.scanResults.map((results) {
      results.sort((a, b) =>
          a.device.remoteId.toString().compareTo(b.device.remoteId.toString()));
      return results;
    });

@riverpod
Stream<List<BluetoothDevice>> connectedDevices(Ref ref) =>
    Stream<List<BluetoothDevice>>.periodic(
        const Duration(seconds: 1), (x) => FlutterBluePlus.connectedDevices);

@riverpod
class ConnectionHandler extends _$ConnectionHandler {
  Timer? _reconnectTimer;
  late BluetoothDevice _device;
  StreamSubscription<BluetoothConnectionState>? _deviceSub;

  @override
  SDBluetoothConnectionState build(String deviceId) {
    state = SDBluetoothConnectionState.connecting;
    ref.onDispose(_dispose);
    _device = BluetoothDevice.fromId(deviceId);
    _deviceSub = _device.connectionState.listen((dstate) {
      log.d(SDLogger.bluetooth, 'Connection state: $dstate');
      if (dstate == BluetoothConnectionState.connected) {
        state = SDBluetoothConnectionState.connected;
      } else if (dstate == BluetoothConnectionState.disconnected) {
        state = SDBluetoothConnectionState.disconnected;
      }
    });
    _reconnectTimer = _reconnectTimer ??
        Timer.periodic(const Duration(seconds: 10), (t) {
          if (state == SDBluetoothConnectionState.disconnected) {
            connect();
          }
        });
    connect();
    return SDBluetoothConnectionState.connecting;
  }

  void _dispose() {
    log.d(SDLogger.bluetooth, "DISPOSE ConnectionHandler");
    _deviceSub?.cancel();
    _reconnectTimer?.cancel();
  }

  Future<void> connect() async {
    log.d(SDLogger.bluetooth, "Connecting to ${_device.remoteId}");
    if (_device.isConnected) {
      state = SDBluetoothConnectionState.connected;
      return;
    }

    state = SDBluetoothConnectionState.connecting;

    try {
      await _device.connect(mtu: null);
      await _device.connectionState
          .where((val) => val == BluetoothConnectionState.connected)
          .first;
      if (Platform.isAndroid) {
        await _device.requestMtu(512);
      }
      log.i(SDLogger.bluetooth, 'Connected to ${_device.remoteId.str}');
      state = SDBluetoothConnectionState.connected;
      await _device.discoverServices();
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error connecting', e);
      state = SDBluetoothConnectionState.disconnected;
    }
  }

  Future<void> write(List<int> data) async {
    await ref.read(bluetoothRepositoryProvider).write(_device, data: data);
  }

  Future<List<int>?> read() async {
    var bt = ref.read(bluetoothRepositoryProvider);
    await bt.write(_device,
        data: bt.currentStateId,
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER_ID);
    return await bt.read(_device,
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER);
  }
}

@riverpod
BluetoothRepository bluetoothRepository(Ref ref) => BluetoothRepository(ref);

class BluetoothRepository {
  final currentStateId = [3, 0];
  Ref ref;

  BluetoothRepository(this.ref) {
    ref.onDispose(() {
      disconnect();
    });
  }

  Future<void> scan() async {
    log.i(SDLogger.bluetooth, 'Starting Bluetooth scan');
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        log.e(SDLogger.bluetooth, 'Error turning on bluetooth', e);
      }
    }
    try {
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 100),
          withKeywords: ['SUPER${70 + 3}']);
      log.d(SDLogger.bluetooth, 'Scan initiated with timeout: 100s');
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      log.d(SDLogger.bluetooth, 'Scan completed');
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error starting scan', e);
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      log.d(SDLogger.bluetooth, 'Scan stopped manually');
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error stopping scan', e);
    }
  }

  Future<void> disconnect() async {
    try {
      for (var device in FlutterBluePlus.connectedDevices) {
        await device.disconnect();
        log.i(SDLogger.bluetooth, 'Disconnected from ${device.remoteId.str}');
      }
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error disconnecting', e);
    }
  }

  Future<void> write(BluetoothDevice device,
      {required List<int> data,
      Guid? serviceId,
      Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    try {
      var servicesList = device.servicesList;
      if (servicesList.isEmpty) {
        log.w(SDLogger.bluetooth,
            'No services discovered for ${device.remoteId}, attempting discovery');
        return;
      }

      // Find service with orElse to prevent exceptions
      var service = servicesList.firstWhere(
          (element) => element.uuid == serviceId,
          orElse: () => throw Exception('Service $serviceId not found'));

      // Find characteristic with orElse to prevent exceptions
      var char = service.characteristics.firstWhere(
          (element) => element.uuid == characteristicId,
          orElse: () =>
              throw Exception('Characteristic $characteristicId not found'));

      await char.write(data);
      log.d(SDLogger.bluetooth, 'Wrote data to ${device.remoteId.str}: $data');
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error writing to ${device.remoteId}', e);
    }
  }

  Future<List<int>?> read(BluetoothDevice device,
      {Guid? serviceId, Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    log.d(SDLogger.bluetooth, 'Reading from ${device.remoteId}');
    try {
      var servicesList = device.servicesList;
      if (servicesList.isEmpty) {
        log.w(SDLogger.bluetooth,
            'No services discovered for ${device.remoteId}, attempting discovery');
        return null;
      }
      var service =
          servicesList.firstWhere((element) => element.uuid == serviceId);
      var char = service.characteristics
          .firstWhere((element) => element.uuid == characteristicId);
      final result = await char.read();
      log.d(
          SDLogger.bluetooth, 'Read data from ${device.remoteId.str}: $result');
      return result;
    } catch (e) {
      log.e(SDLogger.bluetooth, 'Error reading from ${device.remoteId}', e);
    }
    return null;
  }
}
