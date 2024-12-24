// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionHandlerHash() => r'c272f176fda3e930bc1affc061c8d0536daf314d';

/// See also [connectionHandler].
@ProviderFor(connectionHandler)
final connectionHandlerProvider =
    AutoDisposeProvider<ConnectionHandler>.internal(
  connectionHandler,
  name: r'connectionHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionHandlerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectionHandlerRef = AutoDisposeProviderRef<ConnectionHandler>;
String _$adapterStateHash() => r'7e80522f330f7586989aeadfb5a31f82eee98100';

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
String _$isScanningStatusHash() => r'327f6620483bdd9d44ee6149c0cb9c58820ba3d0';

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
String _$connectedDevicesHash() => r'103d3abe23c69bb59bc577f19c755c8d61305977';

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
String _$bluetoothRepositoryHash() =>
    r'e97e207fdd1a0ae74a78b657fa387267d192b334';

/// See also [bluetoothRepository].
@ProviderFor(bluetoothRepository)
final bluetoothRepositoryProvider =
    AutoDisposeProvider<BluetoothRepository>.internal(
  bluetoothRepository,
  name: r'bluetoothRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BluetoothRepositoryRef = AutoDisposeProviderRef<BluetoothRepository>;
String _$scanResultsHash() => r'd52e9fc5f1fcb70bb39d62957d30c02f5b8a8e20';

/// See also [ScanResults].
@ProviderFor(ScanResults)
final scanResultsProvider =
    AutoDisposeNotifierProvider<ScanResults, List<ScanResult>>.internal(
  ScanResults.new,
  name: r'scanResultsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScanResults = AutoDisposeNotifier<List<ScanResult>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
