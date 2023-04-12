import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';

import 'db.dart';
import 'models.dart';

part 'repository.g.dart';

@riverpod
ConnectionHandler connectionHandler(ConnectionHandlerRef ref) =>
    ConnectionHandler(ref, ref.watch(databaseProvider));

@riverpod
class ConnectionStatus extends _$ConnectionStatus {
  @override
  DeviceConnectionState build() {
    return DeviceConnectionState.disconnected;
  }

  set(DeviceConnectionState newState) {
    state = newState;
  }

  get() {
    return state;
  }
}

class ConnectionHandler {
  StreamSubscription<ConnectionStateUpdate>? _btStateSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<BikeState?>? _currentSub;
  Database db;

  Timer? connectTimer;
  Timer? reconnectTimer;
  String? connectedId;
  Ref ref;

  ConnectionHandler(this.ref, this.db) {
    debugPrint("CREATED ConnectionHandler");
    ref.onDispose(dispose);
    _btStateSub = ref
        .read(bluetoothRepositoryProvider)
        .ble
        .connectedDeviceStream
        .listen((event) {
      if (event.deviceId == connectedId) {
        debugPrint('deviceSub: $event');
        ref.read(connectionStatusProvider.notifier).set(event.connectionState);
      }
    });
    _currentSub = db.watchCurrentBike().listen((event) {
      if (connectedId == event?.id) {
        return;
      }
      disconect();
      connectedId = db.currentBike?.id;
      connect();
    });
    connectedId = db.currentBike?.id;
    Future.delayed(const Duration(seconds: 1), () => connect());
    reconnectTimer =
        Timer.periodic(const Duration(seconds: 10), (t) => reconect());
  }

  void dispose() {
    debugPrint("DISPOSE ConnectionHandler");
    _btStateSub?.cancel();
    _currentSub?.cancel();
    connectTimer?.cancel();
    reconnectTimer?.cancel();
  }

  void connect() {
    if (connectedId == null) {
      return;
    }
    final id = connectedId!;
    var connNotify = ref.read(connectionStatusProvider.notifier);
    if (connNotify.get() == DeviceConnectionState.connected) {
      debugPrint('already connected');
      return;
    }
    connNotify.set(DeviceConnectionState.connecting);
    _connectionSub?.cancel();
    _connectionSub =
        ref.read(bluetoothRepositoryProvider).connect(id).listen((event) {
      connNotify.set(event.connectionState);
      debugPrint("conectionSub: $event");
    });
  }

  void reconect() {
    // print('reconnecting...');
    var conn = ref.read(connectionStatusProvider);
    if (connectedId != null && conn == DeviceConnectionState.disconnected) {
      connect();
    }
  }

  void disconect() {
    connectedId = null;
    _connectionSub?.cancel();
    var connNotify = ref.read(connectionStatusProvider.notifier);
    connNotify.set(DeviceConnectionState.disconnected);
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
    return ble.connectToDevice(
        id: deviceId, connectionTimeout: const Duration(seconds: 5));
  }

  Stream<DiscoveredDevice>? scan() {
    if (ble.status == BleStatus.ready) {
      try {
        return ble
            .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
      } catch (e) {
        debugPrint(e.toString());
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
    debugPrint('Writing $data to $deviceId');
    try {
      await ble.writeCharacteristicWithResponse(char, value: data);
    } catch (e) {
      debugPrint(e.toString());
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
      debugPrint(e.toString());
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
