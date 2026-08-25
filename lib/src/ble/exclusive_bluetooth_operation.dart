import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

typedef ExclusiveBluetoothAccess = ({
  BluetoothPermissionState permission,
  BikeAdapterState adapter,
  BluetoothScanPrerequisite scanPrerequisite,
});

final class ExclusiveBluetoothOperation {
  ExclusiveBluetoothOperation({
    required this.transport,
    required this.permissions,
    required this.activeBikeCoordinator,
  });

  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final ActiveBikeCoordinator activeBikeCoordinator;
  var _acquired = false;

  bool get isAcquired => _acquired;

  Future<ExclusiveBluetoothAccess> acquire({
    required bool requestPermission,
    required Duration adapterTimeout,
  }) async {
    if (!_acquired) {
      _acquired = true;
      await activeBikeCoordinator.pauseForDiscovery();
    }
    final permission = await permissions.ensureAccess(
      request: requestPermission,
    );
    if (permission != BluetoothPermissionState.granted) {
      return (
        permission: permission,
        adapter: BikeAdapterState.unknown,
        scanPrerequisite: BluetoothScanPrerequisite.ready,
      );
    }
    final scanPrerequisite = await permissions.checkScanPrerequisite();
    if (scanPrerequisite != BluetoothScanPrerequisite.ready) {
      return (
        permission: permission,
        adapter: BikeAdapterState.unknown,
        scanPrerequisite: scanPrerequisite,
      );
    }
    final adapter = await transport.adapterStates
        .where((state) => state != BikeAdapterState.unknown)
        .first
        .timeout(
          adapterTimeout,
          onTimeout: () => BikeAdapterState.unknown,
        );
    return (
      permission: permission,
      adapter: adapter,
      scanPrerequisite: scanPrerequisite,
    );
  }

  Future<void> release({
    SavedBike? temporarilySelect,
    bool stopScan = true,
  }) async {
    if (!_acquired) {
      if (temporarilySelect != null) {
        await activeBikeCoordinator.selectTemporarily(
          temporarilySelect.bike.deviceId,
        );
      }
      return;
    }
    _acquired = false;
    if (stopScan) {
      try {
        await transport.stopScan();
      } on Object {
        // A scan may have already ended or never started.
      }
    }
    await activeBikeCoordinator.resumeAfterDiscovery(
      temporarilySelect: temporarilySelect,
    );
  }
}
