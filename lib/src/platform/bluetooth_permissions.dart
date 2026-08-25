import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

enum BluetoothPermissionState { granted, denied, permanentlyDenied, restricted }

enum BluetoothPermissionPlatform { android, ios, macos, other }

enum BluetoothScanPrerequisite { ready, locationServicesDisabled }

abstract interface class BluetoothPermissionGateway {
  Future<BluetoothPermissionState> ensureAccess({required bool request});
  Future<BluetoothScanPrerequisite> checkScanPrerequisite();
  Future<bool> openSettings();
}

final class SystemBluetoothPermissionGateway
    implements BluetoothPermissionGateway {
  SystemBluetoothPermissionGateway({
    DeviceInfoPlugin? deviceInfo,
    BluetoothPermissionPlatform? platform,
    Future<int> Function()? androidSdkInt,
    Future<ServiceStatus> Function()? locationServiceStatus,
    Future<bool> Function()? settingsOpener,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _platform = platform ?? _currentPlatform(),
       _androidSdkIntOverride = androidSdkInt,
       _locationServiceStatusOverride = locationServiceStatus,
       _settingsOpenerOverride = settingsOpener;

  final DeviceInfoPlugin _deviceInfo;
  final BluetoothPermissionPlatform _platform;
  final Future<int> Function()? _androidSdkIntOverride;
  final Future<ServiceStatus> Function()? _locationServiceStatusOverride;
  final Future<bool> Function()? _settingsOpenerOverride;

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
  Future<BluetoothScanPrerequisite> checkScanPrerequisite() async {
    if (_platform != BluetoothPermissionPlatform.android ||
        await _androidSdkInt() >= 31) {
      return BluetoothScanPrerequisite.ready;
    }
    final status =
        await (_locationServiceStatusOverride?.call() ??
            Permission.locationWhenInUse.serviceStatus);
    return status == ServiceStatus.enabled
        ? BluetoothScanPrerequisite.ready
        : BluetoothScanPrerequisite.locationServicesDisabled;
  }

  @override
  Future<bool> openSettings() async {
    if (_settingsOpenerOverride case final opener?) {
      return opener();
    }
    if (_platform == BluetoothPermissionPlatform.macos) {
      return launchUrl(
        Uri.parse(
          'x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
    if (_platform == BluetoothPermissionPlatform.other) {
      return Future.value(false);
    }
    return openAppSettings();
  }

  Future<List<Permission>> _requiredPermissions() async {
    if (_platform == BluetoothPermissionPlatform.android) {
      if (await _androidSdkInt() >= 31) {
        return const [Permission.bluetoothScan, Permission.bluetoothConnect];
      }
      return const [Permission.locationWhenInUse];
    }
    if (_platform == BluetoothPermissionPlatform.ios) {
      return const [Permission.bluetooth];
    }
    return const [];
  }

  Future<int> _androidSdkInt() async {
    if (_androidSdkIntOverride case final read?) {
      return read();
    }
    return (await _deviceInfo.androidInfo).version.sdkInt;
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
