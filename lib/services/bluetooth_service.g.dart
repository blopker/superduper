// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bluetooth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bluetoothServiceHash() => r'b7e459d9b4f8011967694bcbc41a840ab82a98f9';

/// See also [bluetoothService].
@ProviderFor(bluetoothService)
final bluetoothServiceProvider =
    AutoDisposeProvider<SDBluetoothService>.internal(
  bluetoothService,
  name: r'bluetoothServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BluetoothServiceRef = AutoDisposeProviderRef<SDBluetoothService>;
String _$adapterStateHash() => r'e558cadae25b2d629876da5a2175a9e1731b4d34';

/// See also [adapterState].
@ProviderFor(adapterState)
final adapterStateProvider =
    AutoDisposeStreamProvider<BluetoothAdapterState>.internal(
  adapterState,
  name: r'adapterStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adapterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdapterStateRef = AutoDisposeStreamProviderRef<BluetoothAdapterState>;
String _$isScanningStatusHash() => r'a6d8d77f53cb668596f68dd2d96b0abe0fbe818c';

/// See also [isScanningStatus].
@ProviderFor(isScanningStatus)
final isScanningStatusProvider = AutoDisposeStreamProvider<bool>.internal(
  isScanningStatus,
  name: r'isScanningStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isScanningStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsScanningStatusRef = AutoDisposeStreamProviderRef<bool>;
String _$scanResultsHash() => r'bf700a9c997217e3a3279308067fa0db4d0149d8';

/// See also [scanResults].
@ProviderFor(scanResults)
final scanResultsProvider =
    AutoDisposeStreamProvider<List<ScanResult>>.internal(
  scanResults,
  name: r'scanResultsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanResultsRef = AutoDisposeStreamProviderRef<List<ScanResult>>;
String _$connectedDevicesHash() => r'a1538de9e0a4a717f4da0910656a03eec9bc2467';

/// See also [connectedDevices].
@ProviderFor(connectedDevices)
final connectedDevicesProvider =
    AutoDisposeStreamProvider<List<BluetoothDevice>>.internal(
  connectedDevices,
  name: r'connectedDevicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectedDevicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectedDevicesRef
    = AutoDisposeStreamProviderRef<List<BluetoothDevice>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
