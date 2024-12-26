import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';

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
      debugPrint('Connection state: $dstate');
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
    debugPrint("DISPOSE ConnectionHandler");
    _device.disconnect();
    _deviceSub?.cancel();
    _reconnectTimer?.cancel();
  }

  connect() async {
    if (_device.isConnected) {
      state = SDBluetoothConnectionState.connected;
      return;
    }

    state = SDBluetoothConnectionState.connecting;

    try {
      await _device.connect(autoConnect: true, mtu: null);
      await _device.connectionState
          .where((val) => val == BluetoothConnectionState.connected)
          .first;
      if (Platform.isAndroid) {
        await _device.requestMtu(512);
      }
      debugPrint('Connected to ${_device.remoteId.str}');
      state = SDBluetoothConnectionState.connected;
      await _device.discoverServices();
    } catch (e) {
      debugPrint('Error connecting: $e');
      state = SDBluetoothConnectionState.disconnected;
    }
  }

  write(List<int> data) async {
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
    debugPrint('scan(): Scanning');
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('Error turning on bluetooth: $e');
      }
    }
    try {
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 100),
          withKeywords: ['SUPER${70 + 3}']);
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  disconnect() async {
    try {
      for (var device in FlutterBluePlus.connectedDevices) {
        await device.disconnect();
      }
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<void> write(BluetoothDevice device,
      {required List<int> data,
      Guid? serviceId,
      Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    try {
      var service = device.servicesList
          .firstWhere((element) => element.uuid == serviceId);
      var char = service.characteristics
          .firstWhere((element) => element.uuid == characteristicId);
      await char.write(data);
    } catch (e) {
      debugPrint('Error writing to ${device.remoteId}: $e');
    }
  }

  Future<List<int>?> read(BluetoothDevice device,
      {Guid? serviceId, Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    debugPrint('Reading from ${device.remoteId}');
    try {
      var service = device.servicesList
          .firstWhere((element) => element.uuid == serviceId);
      var char = service.characteristics
          .firstWhere((element) => element.uuid == characteristicId);
      return await char.read();
    } catch (e) {
      debugPrint('Error reading from ${device.remoteId}: $e');
    }
    return null;
  }
}
