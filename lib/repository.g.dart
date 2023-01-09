// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: avoid_private_typedef_functions, non_constant_identifier_names, subtype_of_sealed_class, invalid_use_of_internal_member, unused_element, constant_identifier_names, unnecessary_raw_strings, library_private_types_in_public_api

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

String _$bluetoothRepositoryHash() =>
    r'ef4c44b7f0bdee3fcc1854e81cdf7462ec44bb50';

/// See also [bluetoothRepository].
final bluetoothRepositoryProvider = AutoDisposeProvider<BluetoothRepository>(
  bluetoothRepository,
  name: r'bluetoothRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothRepositoryHash,
);
typedef BluetoothRepositoryRef = AutoDisposeProviderRef<BluetoothRepository>;
String _$bluetoothStatusStreamHash() =>
    r'9613fd068561041e4fbf7151092c022fe05334f1';

/// See also [bluetoothStatusStream].
final bluetoothStatusStreamProvider = AutoDisposeProvider<Stream<BleStatus>>(
  bluetoothStatusStream,
  name: r'bluetoothStatusStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothStatusStreamHash,
);
typedef BluetoothStatusStreamRef = AutoDisposeProviderRef<Stream<BleStatus>>;
