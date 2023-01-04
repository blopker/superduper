import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/background.dart' as bg;
import 'package:superduper/bluetooth.dart' as bt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  bg.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperDuper',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const MyHomePage(title: 'SuperDuper alpha'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool listening = false;
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? scanSub;
  List<String> devices = [];
  String? selectedDevice;
  StreamSubscription<ConnectionStateUpdate>? deviceSub;
  DiscoveredDevice? connectedDevice;
  bool serviceRunning = false;

  @override
  void initState() {
    super.initState();
    bg.initForegroundTask();
    getDevices().then((value) {
      setState(() {
        devices = value;
      });
    });
    getSelectedDevice().then((value) {
      setState(() {
        selectedDevice = value;
      });
    });
  }

  void _startBG() {
    setState(() {
      serviceRunning = !serviceRunning;
    });
    bg.start();
  }

  void _toggleListen() async {
    print(await FlutterForegroundTask.getAllData());
    setState(() {
      listening = !listening;
    });
    // You can request multiple permissions at once.
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    if (listening) {
      var stream = flutterReactiveBle
          .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
      scanSub = stream.listen((device) async {
        // print(device.name);
        if (device.name == 'SUPER73') {
          if (!devices.contains(device.id)) {
            setState(() {
              devices.add(device.id);
              print('save data');
            });
            await setDevices(devices);
          }
        }
        //code for handling results
      }, onError: (error) {
        //code for handling error
      });
    } else {
      scanSub!.cancel();
    }
  }

  Future<void> setDevices(List<String> devices) async {
    await FlutterForegroundTask.saveData(
        key: 'devices', value: devices.join('|'));
  }

  Future<List<String>> getDevices() async {
    String? devices = await FlutterForegroundTask.getData(key: 'devices');
    return devices?.split('|') ?? [];
  }

  Future<void> setSelectedDevice(String? device) async {
    setState(() {
      selectedDevice = device;
    });
    if (device == null) {
      await FlutterForegroundTask.removeData(key: 'selectedDevice');
    } else {
      await FlutterForegroundTask.saveData(
          key: 'selectedDevice', value: device);
    }
  }

  Future<String?> getSelectedDevice() async {
    String? device = await FlutterForegroundTask.getData(key: 'selectedDevice');
    setState(() {
      selectedDevice = device;
    });
    return device;
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              height: 30,
            ),
            const Text(
              'Select bike:',
            ),
            if (devices.isEmpty) Text('No bikes found, start scan!'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                var device = devices[index];
                var isSelected = device == selectedDevice;
                return ListTile(
                  title: Text(device),
                  trailing: isSelected
                      ? Icon(Icons.check)
                      : Container(
                          width: 10,
                        ),
                  onTap: () {
                    if (isSelected) {
                      setSelectedDevice(null);
                    } else {
                      setSelectedDevice(device);
                    }
                  },
                );
              },
            ),
            // ElevatedButton(
            // onPressed: _toggleLight, child: Text('let there be light')),
            ElevatedButton(
                onPressed: _toggleListen,
                child: listening ? Text('Stop scan') : Text('Start scan')),
            ElevatedButton(
                onPressed: selectedDevice == null
                    ? null
                    : () {
                        bt.doIT(selectedDevice!);
                      },
                child: Text('Run once')),
            ElevatedButton(
                onPressed: selectedDevice == null ? null : _startBG,
                child: serviceRunning
                    ? const Text('Stop watch')
                    : const Text('Start watch')),
            Expanded(child: Container()),
            if (selectedDevice != null)
              DataDumper(
                deviceID: selectedDevice!,
              )
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class DataDumper extends StatefulWidget {
  DataDumper({super.key, required this.deviceID});
  String deviceID;
  @override
  State<DataDumper> createState() => _DataDumperState();
}

class _DataDumperState extends State<DataDumper> {
  StreamSubscription<ConnectionStateUpdate>? deviceSub;
  Future<bool> _connect(String device) async {
    print('connecting to $device');
    if (deviceSub != null) {
      return true;
    }
    var connected = false;
    deviceSub = FlutterReactiveBle()
        .connectToAdvertisingDevice(
      id: device,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
    )
        .listen((connectionState) async {
      print(connectionState);
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        connected = true;
      }
      // Handle connection state updates
    }, onError: (dynamic error) {
      // Handle a possible error
    });
    await Future.delayed(Duration(seconds: 10));
    return connected;
  }

  void onPressed() async {
    var device = widget.deviceID;
    var connected = await _connect(widget.deviceID);
    if (!connected) {
      return;
    }
    FlutterReactiveBle().characteristicValueStream.listen((event) {
      print(event);
    });
    var services = await FlutterReactiveBle().discoverServices(widget.deviceID);
    print(services);
    var qc = QualifiedCharacteristic(
        characteristicId: Uuid.parse('2a26'),
        serviceId: Uuid.parse('180a'),
        deviceId: device);
    var res = await FlutterReactiveBle().readCharacteristic(qc);
    print(res);
    qc = QualifiedCharacteristic(
        characteristicId: Uuid.parse('2a27'),
        serviceId: Uuid.parse('180a'),
        deviceId: device);
    res = await FlutterReactiveBle().readCharacteristic(qc);
    print(res);
    qc = QualifiedCharacteristic(
        characteristicId: Uuid.parse('2a28'),
        serviceId: Uuid.parse('180a'),
        deviceId: device);
    res = await FlutterReactiveBle().readCharacteristic(qc);
    print(res);
    qc = QualifiedCharacteristic(
        characteristicId: Uuid.parse('2a29'),
        serviceId: Uuid.parse('180a'),
        deviceId: device);
    res = await FlutterReactiveBle().readCharacteristic(qc);
    print(res);
    qc = QualifiedCharacteristic(
        characteristicId: Uuid.parse('2a29'),
        serviceId: Uuid.parse('180a'),
        deviceId: device);
    res = await FlutterReactiveBle().readCharacteristic(qc);
    print(res);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text('Dump Data'));
  }
}
