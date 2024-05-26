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

typedef ConnectionHandlerRef = AutoDisposeProviderRef<ConnectionHandler>;
String _$bluetoothRepositoryHash() =>
    r'ef4c44b7f0bdee3fcc1854e81cdf7462ec44bb50';

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

typedef BluetoothRepositoryRef = AutoDisposeProviderRef<BluetoothRepository>;
String _$bluetoothStatusStreamHash() =>
    r'9613fd068561041e4fbf7151092c022fe05334f1';

/// See also [bluetoothStatusStream].
@ProviderFor(bluetoothStatusStream)
final bluetoothStatusStreamProvider =
    AutoDisposeStreamProvider<BleStatus>.internal(
  bluetoothStatusStream,
  name: r'bluetoothStatusStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothStatusStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BluetoothStatusStreamRef = AutoDisposeStreamProviderRef<BleStatus>;
String _$connectionStatusHash() => r'84cf0380fa442818a867c928f5a0bf132f1b9c28';

/// See also [ConnectionStatus].
@ProviderFor(ConnectionStatus)
final connectionStatusProvider = AutoDisposeNotifierProvider<ConnectionStatus,
    DeviceConnectionState>.internal(
  ConnectionStatus.new,
  name: r'connectionStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectionStatus = AutoDisposeNotifier<DeviceConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
