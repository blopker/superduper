import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/saved_bike.dart';
import 'package:superduper/select_page.dart';
import 'package:superduper/debug.dart';
import 'package:superduper/db.dart' as perf;
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark));
    return MaterialApp(
      title: 'SuperDuper',
      theme: ThemeData(
        colorSchemeSeed: Colors.black,
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontSize: 30.0, color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              fontSize: 26.0, color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(
              fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(
              color: Color.fromARGB(255, 155, 162, 190),
              fontWeight: FontWeight.w500,
              fontSize: 14),
        ),
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
    Widget page = const NoBikePage();
    if (bike != null) {
      ref.watch(bikeProvider(bike.id));
      page = BikePage(bikeID: bike.id);
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
        style: Theme.of(context).textTheme.bodyMedium,
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
    return Center(
        child: Text(
      'Please enable bluetooth and location permissions.',
      style: Theme.of(context).textTheme.bodyMedium,
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
            child: Column(
              children: [
                Image(
                  image: const AssetImage('assets/superduper-nobg.png'),
                  height: MediaQuery.of(context).size.shortestSide / 2,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Select Bike',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.unfold_more,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const DebugPage(),
                            ),
                          );
                        },
                        child: const Text('DEBUG')),
                  )
              ],
            )),
      ],
    ));
  }
}
