import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/permissions_service.dart';
import '../providers/bluetooth_provider.dart';
import '../pages/bike_select_page.dart';
import '../core/utils/logger.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/permission_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Future<Map<Permission, PermissionStatus>> permFuture;

  @override
  void initState() {
    permFuture = PermissionsService.getRequiredPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bluetoothRepositoryProvider);
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
            return const BikeSelectWidget();
          },
        )));
  }
}

