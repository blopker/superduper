import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/services.dart';

part 'repository.g.dart';

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
      return ble
          .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
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
    await ble.writeCharacteristicWithResponse(char, value: data);
  }

  Future<List<int>> read(String deviceId,
      {Uuid? serviceId, Uuid? characteristicId}) async {
    var char = QualifiedCharacteristic(
        serviceId: serviceId ?? UUID_METRICS_SERVICE,
        characteristicId: characteristicId ?? UUID_CHARACTERISTIC_REGISTER,
        deviceId: deviceId);
    return await ble.readCharacteristic(char);
  }

  Future<List<int>> readCurrentState(String deviceId) async {
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
