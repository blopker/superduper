import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/router.dart';
import 'package:superduper/screens/bike_list_screen.dart';
import 'package:superduper/services/bike_connection_manager.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';
import 'package:superduper/utils/migration.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  // Create a ProviderContainer to run migration before the app starts
  final container = ProviderContainer();
  
  try {
    // Run the migration before initializing the app
    log.i(SDLogger.DB, 'Running data migration if needed');
    await container.read(runMigrationProvider.future);
    log.i(SDLogger.DB, 'Migration completed successfully');
  } catch (e) {
    log.e(SDLogger.DB, 'Error during migration', e);
    // Continue with app startup even if migration fails
  } finally {
    // Dispose the container when done
    container.dispose();
  }
  
  // Start the app
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
  } else if (Platform.isIOS) {
    perms.addAll([
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ]);
  } else if (Platform.isMacOS) {
    return Future(() => const {});
  }
  return perms.request();
}

class SuperDuper extends ConsumerWidget {
  const SuperDuper({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the bike connection manager which will
    // automatically manage bike connections in the background
    ref.watch(ensureBikeConnectionManagerInitializedProvider);
    
    // Run migration if it hasn't been run yet (as fallback)
    ref.watch(runMigrationProvider);
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      initialRoute: AppRouter.home,
      routes: AppRouter.getRoutes(),
      onGenerateRoute: AppRouter.generateRoute,
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
    // Initialize the bike repository and bluetooth service
    ref.watch(bikeRepositoryProvider);
    ref.watch(bluetoothServiceProvider);
    
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: FutureBuilder(
          future: permFuture,
          builder: (BuildContext context,
              AsyncSnapshot<Map<Permission, PermissionStatus>> snapshot) {
            if (snapshot.hasError) {
              return ErrorPage(error: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const LoadingPage();
            }
            var denied =
                snapshot.data!.values.any((element) => element.isDenied);
            if (denied) {
              log.i(SDLogger.BIKE, 'Permission denied: ${snapshot.data}');
              return const PermissionPage();
            }
            return const BikeListScreen();
          },
        )));
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
