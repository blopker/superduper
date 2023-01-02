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

  void _connect(DiscoveredDevice device) {
    print('connecting to ${device.id}');
    if (deviceSub != null) {
      deviceSub!.cancel();
      setState(() {
        connectedDevice = null;
        deviceSub = null;
      });
      return;
    }
    deviceSub = flutterReactiveBle
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
    )
        .listen((connectionState) async {
      print(connectionState);
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        setState(() {
          connectedDevice = device;
        });
      }
      if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        setState(() {
          connectedDevice = null;
        });
      }
      // Handle connection state updates
    }, onError: (dynamic error) {
      // Handle a possible error
    });
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
    String devices = await FlutterForegroundTask.getData(key: 'devices');
    return devices.split('|');
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
              'Select Super 73:',
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
                    : const Text('Start watch'))
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
