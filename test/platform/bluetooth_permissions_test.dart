import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

void main() {
  test('macOS delegates Bluetooth authorization to Core Bluetooth', () async {
    final gateway = SystemBluetoothPermissionGateway(
      platform: BluetoothPermissionPlatform.macos,
    );

    expect(
      await gateway.ensureAccess(request: true),
      BluetoothPermissionState.granted,
    );
    expect(await gateway.openSettings(), isFalse);
  });
}
