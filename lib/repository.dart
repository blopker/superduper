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
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _deviceSub;

  @override
  SDBluetoothConnectionState build(String deviceId) {
    ref.onDispose(_dispose);
    connect();
    return SDBluetoothConnectionState.connecting;
  }

  void _dispose() {
    debugPrint("DISPOSE ConnectionHandler");
    _reconnectTimer?.cancel();
  }

  connect() async {
    // print('connecting...');
    _reconnectTimer = _reconnectTimer ??
        Timer.periodic(const Duration(seconds: 10), (t) => connect());
    if (_device != null && _device!.isConnected) {
      state = SDBluetoothConnectionState.connected;
      return;
    }
    state = SDBluetoothConnectionState.connecting;
    var bt = ref.read(bluetoothRepositoryProvider);
    _device = _device ?? await bt.getDevice(deviceId);

    if (_device == null) {
      state = SDBluetoothConnectionState.disconnected;
      return;
    }

    if (_device!.isConnected) {
      state = SDBluetoothConnectionState.connected;
      return;
    }

    _deviceSub?.cancel();
    _deviceSub = _device!.connectionState.listen((dstate) {
      if (dstate == BluetoothConnectionState.connected) {
        state = SDBluetoothConnectionState.connected;
      } else if (dstate == BluetoothConnectionState.disconnected) {
        state = SDBluetoothConnectionState.disconnected;
      }
    });
    _device!.cancelWhenDisconnected(_deviceSub!, delayed: true);
    try {
      await bt.connect(_device!);
    } catch (e) {
      debugPrint('Error connecting: $e');
      state = SDBluetoothConnectionState.disconnected;
    }
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

  Future<BluetoothDevice?> getDevice(String id) async {
    debugPrint('getDevice(): Looking for $id');
    for (var device in FlutterBluePlus.connectedDevices) {
      if (device.remoteId.str == id) {
        return device;
      }
    }
    BluetoothDevice? device;
    FlutterBluePlus.scanResults.listen((results) {
      // return results.any((result) => result.device.remoteId.str == id);
      for (var result in results) {
        if (result.device.remoteId.str == id) {
          device = result.device;
          stopScan();
        }
      }
    });
    await scan();
    return device;
  }

  connect(BluetoothDevice device) async {
    debugPrint('connect(): Connecting to ${device.remoteId.str}');
    await stopScan();
    await device.connect(timeout: const Duration(seconds: 20));
    device.discoverServices();
    // var service = device.servicesList
    //     .firstWhere((element) => element.uuid == UUID_METRICS_SERVICE);
    // var char = service.characteristics
    //     .firstWhere((element) => element.uuid == UUID_CHARACTERISTIC_REGISTER);
    // char.lastValueStream.listen((value) {
    //   debugPrint('lastValueStream: $value');
    // });
  }

  // Stream<List<int>> getNotificationStream(String deviceId) {
  //   var char = QualifiedCharacteristic(
  //       serviceId: UUID_METRICS_SERVICE,
  //       characteristicId: UUID_CHARACTERISTIC_REGISTER_NOTIFIER,
  //       deviceId: deviceId);
  //   return ble.subscribeToCharacteristic(char);
  // }

  Future<void> write(String deviceId,
      {required List<int> data,
      Guid? serviceId,
      Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    debugPrint('Writing $data to $deviceId');
    var device = await getDevice(deviceId);
    if (device == null) {
      return;
    }
    try {
      var service = device.servicesList
          .firstWhere((element) => element.uuid == serviceId);
      var char = service.characteristics
          .firstWhere((element) => element.uuid == characteristicId);
      await char.write(data);
    } catch (e) {
      debugPrint('Error writing to $deviceId: $e');
    }
  }

  Future<List<int>?> read(String deviceId,
      {Guid? serviceId, Guid? characteristicId}) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;
    debugPrint('Reading from $deviceId');
    var device = await getDevice(deviceId);
    if (device == null) {
      return null;
    }
    try {
      var service = device.servicesList
          .firstWhere((element) => element.uuid == serviceId);
      var char = service.characteristics
          .firstWhere((element) => element.uuid == characteristicId);
      return await char.read();
    } catch (e) {
      debugPrint('Error reading from $deviceId: $e');
    }
    return null;
  }

  Future<List<int>?> readCurrentState(String deviceId) async {
    // Set the char register to the right mode to get the current state.
    await write(deviceId,
        data: currentStateId,
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER_ID);
    return await read(deviceId,
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER);
  }
}
