import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';

part 'repository.g.dart';

final connectionHandlerProvider = Provider<ConnectionHandler>((ref) {
  return ConnectionHandler(ref);
});

final connectionStatusProvider = StateProvider<DeviceConnectionState>((ref) {
  return DeviceConnectionState.disconnected;
});

class ConnectionHandler {
  StreamSubscription<ConnectionStateUpdate>? _deviceSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  Timer? connectTimer;
  String? connectedId;
  Ref ref;

  ConnectionHandler(this.ref) {
    ref.onDispose(dispose);
    _deviceSub = ref
        .read(bluetoothRepositoryProvider)
        .ble
        .connectedDeviceStream
        .listen((event) {
      if (event.deviceId == connectedId) {
        var connNotify = ref.read(connectionStatusProvider.notifier);
        connNotify.state = event.connectionState;
      }
    });
  }

  void dispose() {
    _deviceSub?.cancel();
    connectTimer?.cancel();
  }

  void connect(String id) {
    var connNotify = ref.read(connectionStatusProvider.notifier);
    connNotify.state = DeviceConnectionState.connecting;
    if (connectedId == id &&
        connNotify.state == DeviceConnectionState.connected) {
      print('already connected');
      return;
    }
    connectedId = id;
    _connectionSub?.cancel();
    _connectionSub =
        ref.read(bluetoothRepositoryProvider).connect(id).listen((event) {
      connNotify.state = event.connectionState;
      print("conectionSub: $event");
    });
  }

  void disconect() {
    connectedId = null;
    _connectionSub?.cancel();
    var connNotify = ref.read(connectionStatusProvider.notifier);
    connNotify.state = DeviceConnectionState.disconnected;
  }
}

@riverpod
BluetoothRepository bluetoothRepository(BluetoothRepositoryRef ref) =>
    BluetoothRepository();

@riverpod
Stream<BleStatus> bluetoothStatusStream(BluetoothStatusStreamRef ref) {
  return ref.watch(bluetoothRepositoryProvider).ble.statusStream;
}

class BluetoothRepository {
  final ble = FlutterReactiveBle();
  final currentStateId = [3, 0];

  Stream<ConnectionStateUpdate> connect(String deviceId) {
    return ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
    );
  }

  Stream<DiscoveredDevice>? scan() {
    if (ble.status == BleStatus.ready) {
      try {
        return ble
            .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Stream<List<int>> getNotificationStream(String deviceId) {
    var char = QualifiedCharacteristic(
        serviceId: UUID_METRICS_SERVICE,
        characteristicId: UUID_CHARACTERISTIC_REGISTER_NOTIFIER,
        deviceId: deviceId);
    return ble.subscribeToCharacteristic(char);
  }

  Future<void> write(String deviceId,
      {required List<int> data,
      Uuid? serviceId,
      Uuid? characteristicId}) async {
    var char = QualifiedCharacteristic(
        serviceId: serviceId ?? UUID_METRICS_SERVICE,
        characteristicId: characteristicId ?? UUID_CHARACTERISTIC_REGISTER,
        deviceId: deviceId);
    print('Writing $data to $deviceId');
    try {
      await ble.writeCharacteristicWithResponse(char, value: data);
    } catch (e) {
      print(e);
    }
  }

  Future<List<int>?> read(String deviceId,
      {Uuid? serviceId, Uuid? characteristicId}) async {
    var char = QualifiedCharacteristic(
        serviceId: serviceId ?? UUID_METRICS_SERVICE,
        characteristicId: characteristicId ?? UUID_CHARACTERISTIC_REGISTER,
        deviceId: deviceId);
    try {
      return await ble.readCharacteristic(char);
    } catch (e) {
      print(e);
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

  BleStatus status() {
    return ble.status;
  }
}
