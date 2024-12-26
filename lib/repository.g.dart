// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionHandlerHash() => r'867ee0b3a5b75054ff74d291107089953d4b7544';

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
String _$adapterStateHash() => r'03e8c6f0a273f7ee878dc5bffc87f633b88cfb69';

/// See also [adapterState].
@ProviderFor(adapterState)
final adapterStateProvider = StreamProvider<BluetoothAdapterState>.internal(
  adapterState,
  name: r'adapterStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adapterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdapterStateRef = StreamProviderRef<BluetoothAdapterState>;
String _$isScanningStatusHash() => r'dfe37cf6ae13ad7180be16e508b6b6ae1eca4283';

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
String _$connectedDevicesHash() => r'bad504c4de82eb01a975bc4812de5b49623a4720';

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
    r'f232e7f108085d98f2d484a8aa17addf2a62b39f';

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
String _$connectionStatusHash() => r'22deef3a0c9d3f85c96b4af687a4fc9ac62c5614';

/// See also [ConnectionStatus].
@ProviderFor(ConnectionStatus)
final connectionStatusProvider =
    NotifierProvider<ConnectionStatus, SDBluetoothConnectionState>.internal(
  ConnectionStatus.new,
  name: r'connectionStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectionStatus = Notifier<SDBluetoothConnectionState>;
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
