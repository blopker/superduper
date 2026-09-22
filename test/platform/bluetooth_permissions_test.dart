import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android detects permanent denial from the permission request',
    () async {
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return PermissionStatus.denied.index;
          case 'requestPermissions':
            expect(call.arguments, [
              Permission.bluetoothScan.value,
              Permission.bluetoothConnect.value,
            ]);
            return {
              Permission.bluetoothScan.value:
                  PermissionStatus.permanentlyDenied.index,
              Permission.bluetoothConnect.value: PermissionStatus.granted.index,
            };
          default:
            throw StateError('Unexpected permission method: ${call.method}');
        }
      });
      final gateway = SystemBluetoothPermissionGateway(
        platform: BluetoothPermissionPlatform.android,
        androidSdkInt: () async => 31,
      );

      expect(
        await gateway.ensureAccess(request: false),
        BluetoothPermissionState.denied,
      );
      expect(
        await gateway.ensureAccess(request: true),
        BluetoothPermissionState.permanentlyDenied,
      );
    },
  );

  test('macOS delegates authorization and opens Bluetooth settings', () async {
    var settingsOpened = false;
    final gateway = SystemBluetoothPermissionGateway(
      platform: BluetoothPermissionPlatform.macos,
      settingsOpener: () async {
        settingsOpened = true;
        return true;
      },
    );

    expect(
      await gateway.ensureAccess(request: true),
      BluetoothPermissionState.granted,
    );
    expect(await gateway.openSettings(), isTrue);
    expect(settingsOpened, isTrue);
  });

  test('Android 10 requires Location Services for scanning', () async {
    final gateway = SystemBluetoothPermissionGateway(
      platform: BluetoothPermissionPlatform.android,
      androidSdkInt: () async => 29,
      locationServiceStatus: () async => ServiceStatus.disabled,
    );

    expect(
      await gateway.checkScanPrerequisite(),
      BluetoothScanPrerequisite.locationServicesDisabled,
    );
  });

  test('Android 12 does not require Location Services for scanning', () async {
    final gateway = SystemBluetoothPermissionGateway(
      platform: BluetoothPermissionPlatform.android,
      androidSdkInt: () async => 31,
      locationServiceStatus: () async => ServiceStatus.disabled,
    );

    expect(
      await gateway.checkScanPrerequisite(),
      BluetoothScanPrerequisite.ready,
    );
  });
}
