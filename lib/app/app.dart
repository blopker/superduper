import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/permissions_service.dart';
import '../providers/bluetooth_provider.dart';
import '../pages/bike_select_page.dart';
import '../core/utils/logger.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/permission_widget.dart';

class SuperDuperApp extends ConsumerStatefulWidget {
  const SuperDuperApp({super.key});

  @override
  ConsumerState<SuperDuperApp> createState() => _SuperDuperAppState();
}

class _SuperDuperAppState extends ConsumerState<SuperDuperApp> {
  late Future<Map<Permission, PermissionStatus>> permFuture;

  @override
  void initState() {
    permFuture = PermissionsService.getRequiredPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark));

    ref.watch(bluetoothRepositoryProvider);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperDuper',
      theme: _buildTheme(),
      home: Scaffold(
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
              return const BikeSelectWidget();
            },
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
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
    );
  }
}