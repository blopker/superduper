import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<Map<Permission, PermissionStatus>> getRequiredPermissions() async {
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
  
  static Future<bool> arePermissionsGranted() async {
    final permissions = await getRequiredPermissions();
    return !permissions.values.any((status) => status.isDenied);
  }
}