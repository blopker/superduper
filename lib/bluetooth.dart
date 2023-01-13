// import 'dart:async';

// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:superduper/utils.dart';
// import 'package:superduper/services.dart';

// // part 'bluetooth.g.dart';

// // @riverpod
// // FlutterReactiveBle getBle() {
// //   return FlutterReactiveBle();
// // }

// StreamSubscription<ConnectionStateUpdate>? deviceSub;
// String? currentDevice;
// StateData currentState = StateData.defaultState();
// DeviceConnectionState? currentStatus;

// QualifiedCharacteristic getWriteChar(String deviceID) {
//   return QualifiedCharacteristic(
//       serviceId: UUID_METRICS_SERVICE,
//       characteristicId: UUID_CHARACTERISTIC_REGISTER,
//       deviceId: deviceID);
// }

// QualifiedCharacteristic getNotifyChar(String deviceID) {
//   return QualifiedCharacteristic(
//       serviceId: UUID_METRICS_SERVICE,
//       characteristicId: UUID_CHARACTERISTIC_REGISTER_NOTIFIER,
//       deviceId: deviceID);
// }

// Future<void> doIT(String deviceID) async {
//   debugPrint('doing it with $deviceID');
//   // await runScan();
//   try {
//     await connect(deviceID);
//     // await flashLight(deviceID);
//     await maxSpeed(deviceID);
//   } catch (e) {
//     reset();
//   }
//   debugPrint('done doing it');
//   return;
// }

// void reset() {
//   deviceSub!.cancel();
//   currentState = StateData.defaultState();
//   currentDevice = null;
//   currentStatus = null;
// }

// // Future<void> runScan() async {
// //   final flutterReactiveBle = FlutterReactiveBle();
// //   var stream = flutterReactiveBle
// //       .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
// //   var scanSub = stream.listen((device) async {
// //     if (device.name == 'SUPER73') {
// //       debugPrint(device);
// //       devices.add(device.id);
// //     }
// //     //code for handling results
// //   }, onError: (error) {
// //     //code for handling error
// //   });

// //   await Future.delayed(const Duration(seconds: 4));
// //   scanSub.cancel();
// // }

// Future<void> flashLight(String deviceId) async {
//   var onValue = strToLis('00D1 0104 0100 0000 0000');
//   var offValue = strToLis('00D1 0004 0100 0000 0000');
//   final characteristic = getWriteChar(deviceId);
//   await FlutterReactiveBle()
//       .writeCharacteristicWithResponse(characteristic, value: onValue);
//   await Future.delayed(const Duration(seconds: 1));
//   await FlutterReactiveBle()
//       .writeCharacteristicWithResponse(characteristic, value: offValue);
// }

// Future<DeviceConnectionState> connect(
//   deviceId,
// ) async {
//   Completer<DeviceConnectionState> complete = Completer();
//   debugPrint(currentDevice);
//   debugPrint(currentStatus);
//   if (currentDevice == deviceId &&
//       currentStatus == DeviceConnectionState.connected) {
//     debugPrint('already connected to $deviceId');
//     complete.complete(DeviceConnectionState.connected);
//     return complete.future;
//   }
//   debugPrint('connecting to $deviceId');
//   if (deviceSub != null) {
//     // reset everything
//     reset();
//   }
//   currentDevice = deviceId;
//   deviceSub = FlutterReactiveBle()
//       .connectToAdvertisingDevice(
//     id: deviceId,
//     withServices: [],
//     prescanDuration: const Duration(seconds: 5),
//   )
//       .listen((connectionState) async {
//     debugPrint(connectionState);
//     currentStatus = connectionState.connectionState;
//     if (connectionState.connectionState == DeviceConnectionState.connected) {
//       if (!complete.isCompleted) {
//         complete.complete(connectionState.connectionState);
//       }
//       FlutterReactiveBle()
//           .subscribeToCharacteristic(getNotifyChar(deviceId))
//           .listen((event) {
//         if (StateData.isValid(event)) {
//           debugPrint('got new state $event');
//           currentState = StateData(event);
//         }
//       }, onError: (e) {
//         debugPrint(e);
//       });
//     }
//     if (connectionState.connectionState == DeviceConnectionState.disconnected) {
//       if (!complete.isCompleted) {
//         complete.complete(connectionState.connectionState);
//       }
//     }
//     // Handle connection state updates
//   }, onError: (dynamic error) {
//     complete.complete(DeviceConnectionState.disconnected);
//   });
//   return complete.future;
// }

// Future<void> maxSpeed(deviceID) async {
//   if (currentState.mode == 3) {
//     debugPrint('max speed already set');
//     return;
//   }
//   debugPrint('sending max speed');
//   var state = StateData(currentState.config);
//   state.assist = 4;
//   state.mode = 3;
//   var value = state.write();
//   debugPrint('writting $value');
//   final characteristic = getWriteChar(deviceID);
//   await FlutterReactiveBle()
//       .writeCharacteristicWithResponse(characteristic, value: value);
// }

//   // void _toggleLight() async {
//   //   if (connectedDevice == null) {
//   //     return;
//   //   }
//   //   debugPrint('sending light signal');
//   //   var value = strToLis('00D1 0104 0100 0000 0000');
//   //   debugPrint(connectedDevice!);
//   //   debugPrint(value);

//   //   final authChar = QualifiedCharacteristic(
//   //       serviceId: Uuid.parse('00002554-1212-EFDE-1523-785FEABCD123'),
//   //       characteristicId: Uuid.parse('00002558-1212-EFDE-1523-785FEABCD123'),
//   //       deviceId: connectedDevice!.id);
//   //   var resp = await flutterReactiveBle.readCharacteristic(authChar);
//   //   debugPrint(resp);
//   //   final characteristic = QualifiedCharacteristic(
//   //       serviceId: Uuid.parse('00001554-1212-EFDE-1523-785FEABCD123'),
//   //       characteristicId: Uuid.parse('0000155F-1212-EFDE-1523-785FEABCD123'),
//   //       deviceId: connectedDevice!.id);
//   //   resp = await flutterReactiveBle.readCharacteristic(characteristic);
//   //   debugPrint(resp);
//   //   await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
//   //       value: value);
//   //   resp = await flutterReactiveBle.readCharacteristic(characteristic);
//   //   debugPrint(resp);
//   //   // debugPrint(resp);
//   // }