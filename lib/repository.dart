import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';

import 'models.dart';

part 'repository.g.dart';

@riverpod
ConnectionHandler connectionHandler(Ref ref) => ConnectionHandler(ref);

final connectionStatusProvider = StateProvider<BluetoothConnectionState>(
  (ref) => BluetoothConnectionState.disconnected,
);

@riverpod
Stream<BluetoothAdapterState> adapterState(Ref ref) =>
    FlutterBluePlus.adapterState;

@riverpod
Stream<bool> isScanningStatus(Ref ref) => FlutterBluePlus.isScanning;

@riverpod
class ScanResults extends _$ScanResults {
  @override
  List<ScanResult> build() {
    return [];
  }

  void set(List<ScanResult> newState) {
    state = newState;
  }
}

@riverpod
Stream<List<BluetoothDevice>> connectedDevices(Ref ref) =>
    Stream<List<BluetoothDevice>>.periodic(
        const Duration(seconds: 1), (x) => FlutterBluePlus.connectedDevices);

class ConnectionHandler {
  ProviderSubscription<BikeState?>? _currentSub;
  Timer? reconnectTimer;
  String? connectedId;
  Ref ref;

  ConnectionHandler(this.ref) {
    debugPrint("CREATED ConnectionHandler");
    ref.onDispose(dispose);
    reconnectTimer =
        Timer.periodic(const Duration(seconds: 10), (t) => reconnect());
  }

  void dispose() {
    debugPrint("DISPOSE ConnectionHandler");
    _currentSub?.close();
    reconnectTimer?.cancel();
  }

  void connect(String deviceId) {
    connectedId = deviceId;
    // connect
    ref.read(bluetoothRepositoryProvider).connect(connectedId!);
  }

  void reconnect() {
    // print('reconnecting...');
    ref.read(bluetoothRepositoryProvider).connect(connectedId!);
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
    stopScan();
    var scanNotifier = ref.read(scanResultsProvider.notifier);
    var scanSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        results.sort((a, b) => a.device.remoteId
            .toString()
            .compareTo(b.device.remoteId.toString()));
        final filteredResults = results.where((result) {
          return result.device.advName.contains('SUPER${70 + 3}');
        });
        scanNotifier.set(filteredResults.toList());
      },
      onError: (e) => debugPrint(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(scanSub);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 100));
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

  Future<BluetoothDevice?> _getDevice(String id) async {
    debugPrint('_getDevice(): Looking for $id');
    var scanList = FlutterBluePlus.lastScanResults;
    try {
      var device = scanList
          .firstWhere((element) => element.device.remoteId.str == id)
          .device;
      return device;
    } catch (e) {
      debugPrint('Device not found: $id, scanning');
      scan();
      var devices = await FlutterBluePlus.onScanResults.where((results) {
        return results.any((result) => result.device.remoteId.str == id);
      }).first;
      var device = devices.first.device;
      stopScan();
      return device;
    }
  }

  connect(String deviceId) async {
    debugPrint('connect(): Connecting to $deviceId');
    stopScan();
    var device = await _getDevice(deviceId);
    if (device == null) {
      return;
    }
    if (device.isConnected) {
      return;
    }
    var connNotify = ref.read(connectionStatusProvider.notifier);
    connNotify.state = BluetoothConnectionState.connecting;
    try {
      await device.connect(timeout: const Duration(seconds: 20));
      await device.discoverServices();
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
    var deviceSub =
        device.connectionState.listen((BluetoothConnectionState state) async {
      debugPrint('BluetoothConnectionState: $state');
      connNotify.state = state;
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("${device.disconnectReason}");
      }
    });
    device.cancelWhenDisconnected(deviceSub, delayed: true);
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
    var device = await _getDevice(deviceId);
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
    var device = await _getDevice(deviceId);
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
