import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:superduper/utils/logger.dart';
import 'package:superduper/utils/uuids.dart';

part 'bluetooth_service.g.dart';

/// Service for managing Bluetooth operations.
///
/// This service handles low-level Bluetooth operations and is shared
/// across all bike connections.
class SDBluetoothService {
  final Ref _ref;

  /// Create a new Bluetooth service.
  SDBluetoothService(this._ref);

  /// Start scanning for Bluetooth devices.
  ///
  /// This will scan for devices with the SUPER73 keyword.
  /// The scan will timeout after the specified duration.
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 10)}) async {
    log.i(SDLogger.BLUETOOTH, 'Starting Bluetooth scan');

    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        log.e(SDLogger.BLUETOOTH, 'Error turning on bluetooth', e);
      }
    }

    try {
      await FlutterBluePlus.adapterState
          .where((val) => val == BluetoothAdapterState.on)
          .first;
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withKeywords: ['SUPER${70 + 3}'],
      );
      log.d(SDLogger.BLUETOOTH,
          'Scan initiated with timeout: ${timeout.inSeconds}s');
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error starting scan', e);
      rethrow;
    }
  }

  /// Stop an ongoing Bluetooth scan.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      log.d(SDLogger.BLUETOOTH, 'Scan stopped manually');
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error stopping scan', e);
    }
  }

  /// Write data to a Bluetooth device.
  ///
  /// This writes the provided data to the specified characteristic of the device.
  /// If serviceId or characteristicId are not provided, defaults will be used.
  Future<void> write({
    required BluetoothDevice device,
    required List<int> data,
    Guid? serviceId,
    Guid? characteristicId,
  }) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;

    try {
      var servicesList = device.servicesList;
      if (servicesList.isEmpty) {
        log.w(SDLogger.BLUETOOTH,
            'No services discovered for ${device.remoteId}, attempting discovery');
        return;
      }

      // Find service with orElse to prevent exceptions
      var service = servicesList.firstWhere(
          (element) => element.uuid == serviceId,
          orElse: () => throw Exception('Service $serviceId not found'));

      // Find characteristic with orElse to prevent exceptions
      var char = service.characteristics.firstWhere(
          (element) => element.uuid == characteristicId,
          orElse: () =>
              throw Exception('Characteristic $characteristicId not found'));

      await char.write(data);
      log.d(SDLogger.BLUETOOTH, 'Wrote data to ${device.remoteId.str}: $data');
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error writing to ${device.remoteId}', e);
      rethrow;
    }
  }

  /// Read data from a Bluetooth device.
  ///
  /// This reads data from the specified characteristic of the device.
  /// If serviceId or characteristicId are not provided, defaults will be used.
  Future<List<int>?> read({
    required BluetoothDevice device,
    Guid? serviceId,
    Guid? characteristicId,
  }) async {
    serviceId ??= UUID_METRICS_SERVICE;
    characteristicId ??= UUID_CHARACTERISTIC_REGISTER;

    log.d(SDLogger.BLUETOOTH, 'Reading from ${device.remoteId}');

    try {
      var servicesList = device.servicesList;
      if (servicesList.isEmpty) {
        log.w(SDLogger.BLUETOOTH,
            'No services discovered for ${device.remoteId}, attempting discovery');
        return null;
      }

      var service = servicesList.firstWhere(
          (element) => element.uuid == serviceId,
          orElse: () => throw Exception('Service $serviceId not found'));

      var char = service.characteristics.firstWhere(
          (element) => element.uuid == characteristicId,
          orElse: () =>
              throw Exception('Characteristic $characteristicId not found'));

      final result = await char.read();
      log.d(
          SDLogger.BLUETOOTH, 'Read data from ${device.remoteId.str}: $result');
      return result;
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error reading from ${device.remoteId}', e);
      return null;
    }
  }

  /// Disconnect from all connected devices.
  Future<void> disconnectAll() async {
    try {
      for (var device in FlutterBluePlus.connectedDevices) {
        await device.disconnect();
        log.i(SDLogger.BLUETOOTH, 'Disconnected from ${device.remoteId.str}');
      }
    } catch (e) {
      log.e(SDLogger.BLUETOOTH, 'Error disconnecting devices', e);
    }
  }
}

// Provider for the Bluetooth service
@riverpod
SDBluetoothService bluetoothService(Ref ref) {
  final service = SDBluetoothService(ref);
  ref.onDispose(() {
    service.disconnectAll();
  });
  return service;
}

// Bluetooth adapter state provider
@riverpod
Stream<BluetoothAdapterState> adapterState(Ref ref) {
  return FlutterBluePlus.adapterState;
}

// Is scanning status provider
@riverpod
Stream<bool> isScanningStatus(Ref ref) {
  return FlutterBluePlus.isScanning;
}

// Scan results provider
@riverpod
Stream<List<ScanResult>> scanResults(Ref ref) {
  return FlutterBluePlus.scanResults.map((results) {
    results.sort((a, b) =>
        a.device.remoteId.toString().compareTo(b.device.remoteId.toString()));
    return results;
  });
}

// Connected devices provider
@riverpod
Stream<List<BluetoothDevice>> connectedDevices(Ref ref) {
  return Stream<List<BluetoothDevice>>.periodic(
      const Duration(seconds: 1), (x) => FlutterBluePlus.connectedDevices);
}
