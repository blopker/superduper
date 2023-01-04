import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:superduper/utils.dart';

StreamSubscription<ConnectionStateUpdate>? deviceSub;
String? currentDevice;
DeviceConnectionState? currentStatus;

QualifiedCharacteristic getChar(String deviceID) {
  return QualifiedCharacteristic(
      serviceId: Uuid.parse('00001554-1212-EFDE-1523-785FEABCD123'),
      characteristicId: Uuid.parse('0000155F-1212-EFDE-1523-785FEABCD123'),
      deviceId: deviceID);
}

Future<void> doIT(String deviceID) async {
  print('doing it with $deviceID');
  // await runScan();
  try {
    await connect(deviceID);
    // await flashLight(deviceID);
    await maxSpeed(deviceID);
  } catch (e) {
    reset();
  }
  print('done doing it');
  return;
}

void reset() {
  deviceSub!.cancel();
  currentDevice = null;
  currentStatus = null;
}

// Future<void> runScan() async {
//   final flutterReactiveBle = FlutterReactiveBle();
//   var stream = flutterReactiveBle
//       .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
//   var scanSub = stream.listen((device) async {
//     if (device.name == 'SUPER73') {
//       print(device);
//       devices.add(device.id);
//     }
//     //code for handling results
//   }, onError: (error) {
//     //code for handling error
//   });

//   await Future.delayed(const Duration(seconds: 4));
//   scanSub.cancel();
// }

Future<void> flashLight(String deviceId) async {
  var onValue = strToLis('00D1 0104 0100 0000 0000');
  var offValue = strToLis('00D1 0004 0100 0000 0000');
  final characteristic = getChar(deviceId);
  await FlutterReactiveBle()
      .writeCharacteristicWithResponse(characteristic, value: onValue);
  await Future.delayed(const Duration(seconds: 1));
  await FlutterReactiveBle()
      .writeCharacteristicWithResponse(characteristic, value: offValue);
}

Future<DeviceConnectionState> connect(
  deviceId,
) async {
  Completer<DeviceConnectionState> complete = Completer();
  print(currentDevice);
  print(currentStatus);
  if (currentDevice == deviceId &&
      currentStatus == DeviceConnectionState.connected) {
    print('already connected to $deviceId');
    complete.complete(DeviceConnectionState.connected);
    return complete.future;
  }
  print('connecting to $deviceId');
  if (deviceSub != null) {
    // reset everything
    reset();
  }
  currentDevice = deviceId;
  deviceSub = FlutterReactiveBle()
      .connectToAdvertisingDevice(
    id: deviceId,
    withServices: [],
    prescanDuration: const Duration(seconds: 5),
  )
      .listen((connectionState) async {
    print(connectionState);
    currentStatus = connectionState.connectionState;
    if (connectionState.connectionState == DeviceConnectionState.connected) {
      if (!complete.isCompleted) {
        complete.complete(connectionState.connectionState);
      }
    }
    if (connectionState.connectionState == DeviceConnectionState.disconnected) {
      if (!complete.isCompleted) {
        complete.complete(connectionState.connectionState);
      }
    }
    // Handle connection state updates
  }, onError: (dynamic error) {
    complete.complete(DeviceConnectionState.disconnected);
  });
  return complete.future;
}

Future<void> maxSpeed(deviceID) async {
  print('sending max speed');
  var value = strToLis('00D1 0004 0300 0000 0000');
  final characteristic = getChar(deviceID);
  await FlutterReactiveBle()
      .writeCharacteristicWithResponse(characteristic, value: value);
}

  // void _toggleLight() async {
  //   if (connectedDevice == null) {
  //     return;
  //   }
  //   print('sending light signal');
  //   var value = strToLis('00D1 0104 0100 0000 0000');
  //   print(connectedDevice!);
  //   print(value);

  //   final authChar = QualifiedCharacteristic(
  //       serviceId: Uuid.parse('00002554-1212-EFDE-1523-785FEABCD123'),
  //       characteristicId: Uuid.parse('00002558-1212-EFDE-1523-785FEABCD123'),
  //       deviceId: connectedDevice!.id);
  //   var resp = await flutterReactiveBle.readCharacteristic(authChar);
  //   print(resp);
  //   final characteristic = QualifiedCharacteristic(
  //       serviceId: Uuid.parse('00001554-1212-EFDE-1523-785FEABCD123'),
  //       characteristicId: Uuid.parse('0000155F-1212-EFDE-1523-785FEABCD123'),
  //       deviceId: connectedDevice!.id);
  //   resp = await flutterReactiveBle.readCharacteristic(characteristic);
  //   print(resp);
  //   await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
  //       value: value);
  //   resp = await flutterReactiveBle.readCharacteristic(characteristic);
  //   print(resp);
  //   // print(resp);
  // }