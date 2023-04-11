// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionHandlerHash() => r'd9b4d77c225df6766fef64885d4984b77a9a07f3';

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
String _$connectionStatusHash() => r'4c578c1b7ea22eb0df078a5c06a0410b5a4f741f';

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
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
