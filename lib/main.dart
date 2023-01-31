import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/styles.dart';
import 'package:superduper/repository.dart';
import 'package:superduper/debug.dart';
import 'package:superduper/preferences.dart' as perf;
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await perf.init();
  runApp(
    const ProviderScope(
      child: SuperDuper(),
    ),
  );
}

Future<Map<Permission, PermissionStatus>> getPermissions() async {
  var perms = <Permission>[];
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
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
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
                ),
              ],
            )),
        if (kDebugMode)
          ElevatedButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const DebugPage(),
                  ),
                );
              },
              child: const Text('DEBUG'))
      ],
    ));
  }
}
