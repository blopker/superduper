import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/styles.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/native.dart' as native;
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  native.init();
  runApp(
    const ProviderScope(
      child: SuperDuper(),
    ),
  );
}

Future<Map<Permission, PermissionStatus>> getPermissions() async {
  var perms = <Permission>[Permission.notification];
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    if ((await deviceInfo.androidInfo).version.sdkInt < 31) {
      perms.addAll([Permission.bluetooth, Permission.location]);
    } else {
      perms.addAll([
        Permission.location,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ]);
    }
  } else {
    perms.addAll([
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ]);
  }
  return perms.request();
}

class SuperDuper extends StatelessWidget {
  const SuperDuper({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperDuper',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Future<Map<Permission, PermissionStatus>> permFuture;

  @override
  void initState() {
    permFuture = getPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bike = ref.watch(currentBikeProvider);
    ref.watch(connectionHandlerProvider);
    Widget page = const NoBikePage();
    if (bike != null) {
      ref.watch(bikeProvider(bike.id));
      page = BikePage(bike: bike);
    }
    return Scaffold(
        backgroundColor: const Color(0xff121421),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 8),
                child: FutureBuilder(
                  future: permFuture,
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<Permission, PermissionStatus>>
                          snapshot) {
                    if (snapshot.hasError) {
                      return ErrorPage(error: snapshot.error.toString());
                    }
                    if (!snapshot.hasData) {
                      return const LoadingPage();
                    }
                    var denied = snapshot.data!.values
                        .any((element) => element.isDenied);
                    if (denied) {
                      debugPrint(snapshot.data?.toString());
                      return const PermissionPage();
                    }
                    return page;
                  },
                ))));
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        error,
        style: Styles.body,
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Text(
      'Please enable bluetooth and location permissions.',
      style: Styles.body,
    ));
  }
}

class NoBikePage extends ConsumerWidget {
  const NoBikePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
        child: InkWell(
            onTap: () {
              showModalBottomSheet<void>(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return const BikeSelectWidget();
                  });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Select Bike', style: Styles.header),
                SizedBox(
                  width: 10,
                ),
                Icon(
                  Icons.unfold_more,
                  color: Colors.white,
                  size: 30,
                )
              ],
            )));
  }
}

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(child: Text('hi'));
  }
}

// class BikePage extends StatefulWidget {
//   const BikePage({super.key, required this.title});

//   final String title;

//   @override
//   State<BikePage> createState() => _BikePageState();
// }

// class _BikePageState extends State<BikePage> {
//   bool listening = false;
//   final flutterReactiveBle = FlutterReactiveBle();
//   StreamSubscription<DiscoveredDevice>? scanSub;
//   List<String> devices = [];
//   String? selectedDevice;
//   StreamSubscription<ConnectionStateUpdate>? deviceSub;
//   DiscoveredDevice? connectedDevice;
//   bool serviceRunning = false;

//   @override
//   void initState() {
//     super.initState();
//     bg.initForegroundTask();
//     getDevices().then((value) {
//       setState(() {
//         devices = value;
//       });
//     });
//     getSelectedDevice().then((value) {
//       setState(() {
//         selectedDevice = value;
//       });
//     });
//   }

//   void _startBG() {
//     setState(() {
//       serviceRunning = !serviceRunning;
//     });
//     bg.start();
//   }

//   void _toggleListen() async {
//     debugPrint(await FlutterForegroundTask.getAllData());
//     setState(() {
//       listening = !listening;
//     });
//     // You can request multiple permissions at once.
//     await [
//       Permission.location,
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//     ].request();

//     if (listening) {
//       var stream = flutterReactiveBle
//           .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
//       scanSub = stream.listen((device) async {
//         // debugPrint(device.name);
//         if (device.name == 'SUPER73') {
//           if (!devices.contains(device.id)) {
//             setState(() {
//               devices.add(device.id);
//               debugPrint('save data');
//             });
//             await setDevices(devices);
//           }
//         }
//         //code for handling results
//       }, onError: (error) {
//         //code for handling error
//       });
//     } else {
//       scanSub!.cancel();
//     }
//   }

//   Future<void> setDevices(List<String> devices) async {
//     await FlutterForegroundTask.saveData(
//         key: 'devices', value: devices.join('|'));
//   }

//   Future<List<String>> getDevices() async {
//     String? devices = await FlutterForegroundTask.getData(key: 'devices');
//     return devices?.split('|') ?? [];
//   }

//   Future<void> setSelectedDevice(String? device) async {
//     setState(() {
//       selectedDevice = device;
//     });
//     if (device == null) {
//       await FlutterForegroundTask.removeData(key: 'selectedDevice');
//     } else {
//       await FlutterForegroundTask.saveData(
//           key: 'selectedDevice', value: device);
//     }
//   }

//   Future<String?> getSelectedDevice() async {
//     String? device = await FlutterForegroundTask.getData(key: 'selectedDevice');
//     setState(() {
//       selectedDevice = device;
//     });
//     return device;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WithForegroundTask(
//       child: Scaffold(
//         appBar: AppBar(
//           // Here we take the value from the BikePage object that was created by
//           // the App.build method, and use it to set our appbar title.
//           title: Text(widget.title),
//         ),
//         body: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             const SizedBox(
//               height: 30,
//             ),
//             const Text(
//               'Select bike:',
//             ),
//             if (devices.isEmpty) Text('No bikes found, start scan!'),
//             ListView.builder(
//               shrinkWrap: true,
//               itemCount: devices.length,
//               itemBuilder: (context, index) {
//                 var device = devices[index];
//                 var isSelected = device == selectedDevice;
//                 return ListTile(
//                   title: Text(device),
//                   trailing: isSelected
//                       ? Icon(Icons.check)
//                       : Container(
//                           width: 10,
//                         ),
//                   onTap: () {
//                     if (isSelected) {
//                       setSelectedDevice(null);
//                     } else {
//                       setSelectedDevice(device);
//                     }
//                   },
//                 );
//               },
//             ),
//             // ElevatedButton(
//             // onPressed: _toggleLight, child: Text('let there be light')),
//             ElevatedButton(
//                 onPressed: _toggleListen,
//                 child: listening ? Text('Stop scan') : Text('Start scan')),
//             ElevatedButton(
//                 onPressed: selectedDevice == null
//                     ? null
//                     : () {
//                         bt.doIT(selectedDevice!);
//                       },
//                 child: Text('Run once')),
//             ElevatedButton(
//                 onPressed: selectedDevice == null ? null : _startBG,
//                 child: serviceRunning
//                     ? const Text('Stop watch')
//                     : const Text('Start watch')),
//             Expanded(child: Container()),
//             if (selectedDevice != null)
//               DataDumper(
//                 deviceID: selectedDevice!,
//               )
//           ],
//         ), // This trailing comma makes auto-formatting nicer for build methods.
//       ),
//     );
//   }
// }

// class DataDumper extends StatefulWidget {
//   DataDumper({super.key, required this.deviceID});
//   String deviceID;
//   @override
//   State<DataDumper> createState() => _DataDumperState();
// }

// class _DataDumperState extends State<DataDumper> {
//   StreamSubscription<ConnectionStateUpdate>? deviceSub;
//   Future<bool> _connect(String device) async {
//     debugPrint('connecting to $device');
//     if (deviceSub != null) {
//       return true;
//     }
//     var connected = false;
//     deviceSub = FlutterReactiveBle()
//         .connectToAdvertisingDevice(
//       id: device,
//       withServices: [],
//       prescanDuration: const Duration(seconds: 5),
//     )
//         .listen((connectionState) async {
//       debugPrint(connectionState);
//       if (connectionState.connectionState == DeviceConnectionState.connected) {
//         connected = true;
//       }
//       // Handle connection state updates
//     }, onError: (dynamic error) {
//       // Handle a possible error
//     });
//     await Future.delayed(Duration(seconds: 10));
//     return connected;
//   }

//   void onPressed() async {
//     var device = widget.deviceID;
//     var connected = await _connect(widget.deviceID);
//     if (!connected) {
//       return;
//     }
//     FlutterReactiveBle().characteristicValueStream.listen((event) {
//       debugPrint(event);
//     });
//     var services = await FlutterReactiveBle().discoverServices(widget.deviceID);
//     debugPrint(services);
//     var qc = QualifiedCharacteristic(
//         characteristicId: Uuid.parse('2a26'),
//         serviceId: Uuid.parse('180a'),
//         deviceId: device);
//     var res = await FlutterReactiveBle().readCharacteristic(qc);
//     debugPrint(res);
//     qc = QualifiedCharacteristic(
//         characteristicId: Uuid.parse('2a27'),
//         serviceId: Uuid.parse('180a'),
//         deviceId: device);
//     res = await FlutterReactiveBle().readCharacteristic(qc);
//     debugPrint(res);
//     qc = QualifiedCharacteristic(
//         characteristicId: Uuid.parse('2a28'),
//         serviceId: Uuid.parse('180a'),
//         deviceId: device);
//     res = await FlutterReactiveBle().readCharacteristic(qc);
//     debugPrint(res);
//     qc = QualifiedCharacteristic(
//         characteristicId: Uuid.parse('2a29'),
//         serviceId: Uuid.parse('180a'),
//         deviceId: device);
//     res = await FlutterReactiveBle().readCharacteristic(qc);
//     debugPrint(res);
//     qc = QualifiedCharacteristic(
//         characteristicId: Uuid.parse('2a29'),
//         serviceId: Uuid.parse('180a'),
//         deviceId: device);
//     res = await FlutterReactiveBle().readCharacteristic(qc);
//     debugPrint(res);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(onPressed: onPressed, child: Text('Dump Data'));
//   }
// }
