import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BluetoothPermissionState { granted, denied, permanentlyDenied, restricted }

enum BluetoothPermissionPlatform { android, ios, macos, other }

abstract interface class BluetoothPermissionGateway {
  Future<BluetoothPermissionState> ensureAccess({required bool request});
  Future<bool> openSettings();
}

final class SystemBluetoothPermissionGateway
    implements BluetoothPermissionGateway {
  SystemBluetoothPermissionGateway({
    DeviceInfoPlugin? deviceInfo,
    BluetoothPermissionPlatform? platform,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _platform = platform ?? _currentPlatform();

  final DeviceInfoPlugin _deviceInfo;
  final BluetoothPermissionPlatform _platform;

  @override
  Future<BluetoothPermissionState> ensureAccess({required bool request}) async {
    if (_platform == BluetoothPermissionPlatform.macos ||
        _platform == BluetoothPermissionPlatform.other) {
      return BluetoothPermissionState.granted;
    }
    final permissions = await _requiredPermissions();
    final statuses = request
        ? await permissions.request()
        : {
            for (final permission in permissions)
              permission: await permission.status,
          };
    return _combine(statuses.values);
  }

  @override
  Future<bool> openSettings() {
    if (_platform == BluetoothPermissionPlatform.macos ||
        _platform == BluetoothPermissionPlatform.other) {
      return Future.value(false);
    }
    return openAppSettings();
  }

  Future<List<Permission>> _requiredPermissions() async {
    if (_platform == BluetoothPermissionPlatform.android) {
      final android = await _deviceInfo.androidInfo;
      if (android.version.sdkInt >= 31) {
        return const [Permission.bluetoothScan, Permission.bluetoothConnect];
      }
      return const [Permission.locationWhenInUse];
    }
    if (_platform == BluetoothPermissionPlatform.ios) {
      return const [Permission.bluetooth];
    }
    return const [];
  }

  static BluetoothPermissionPlatform _currentPlatform() {
    if (Platform.isAndroid) {
      return BluetoothPermissionPlatform.android;
    }
    if (Platform.isIOS) {
      return BluetoothPermissionPlatform.ios;
    }
    if (Platform.isMacOS) {
      return BluetoothPermissionPlatform.macos;
    }
    return BluetoothPermissionPlatform.other;
  }

  BluetoothPermissionState _combine(Iterable<PermissionStatus> statuses) {
    if (statuses.every((status) => status.isGranted || status.isLimited)) {
      return BluetoothPermissionState.granted;
    }
    if (statuses.any((status) => status.isPermanentlyDenied)) {
      return BluetoothPermissionState.permanentlyDenied;
    }
    if (statuses.any((status) => status.isRestricted)) {
      return BluetoothPermissionState.restricted;
    }
    return BluetoothPermissionState.denied;
  }
}
