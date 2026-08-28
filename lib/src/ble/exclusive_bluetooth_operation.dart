import 'package:superduper/src/ble/active_bike_coordinator.dart';
import 'package:superduper/src/ble/bike_transport.dart';
import 'package:superduper/src/domain/bike.dart';
import 'package:superduper/src/platform/bluetooth_permissions.dart';

typedef ExclusiveBluetoothAccess = ({
  BluetoothPermissionState permission,
  BikeAdapterState adapter,
  BluetoothScanPrerequisite scanPrerequisite,
});

final class ExclusiveBluetoothOperationBusy implements Exception {
  const ExclusiveBluetoothOperationBusy();
}

final class ExclusiveBluetoothOperation {
  ExclusiveBluetoothOperation({
    required this.transport,
    required this.permissions,
    required this.activeBikeCoordinator,
  });

  final BikeTransport transport;
  final BluetoothPermissionGateway permissions;
  final ActiveBikeCoordinator activeBikeCoordinator;
  ActiveBikeDiscoveryPause? _pause;

  bool get isAcquired => _pause != null;

  Future<ExclusiveBluetoothAccess> acquire({
    required bool requestPermission,
    required Duration adapterTimeout,
  }) async {
    if (_pause == null) {
      final pause = await activeBikeCoordinator.acquireDiscoveryPause();
      if (pause == null) {
        throw const ExclusiveBluetoothOperationBusy();
      }
      _pause = pause;
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
    final pause = _pause;
    if (pause == null) {
      if (temporarilySelect != null) {
        await activeBikeCoordinator.selectTemporarily(
          temporarilySelect.bike.deviceId,
        );
      }
      return;
    }
    _pause = null;
    if (stopScan) {
      try {
        await transport.stopScan();
      } on Object {
        // A scan may have already ended or never started.
      }
    }
    await pause.release(
      temporarilySelect: temporarilySelect,
    );
  }
}
