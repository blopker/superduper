// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bikeHash() => r'e2bd2ec353b89f09bf5b98e937816950fabd680a';

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

abstract class _$Bike extends BuildlessAutoDisposeNotifier<BikeState> {
  late final String id;

  BikeState build(
    String id,
  );
}

/// See also [Bike].
@ProviderFor(Bike)
const bikeProvider = BikeFamily();

/// See also [Bike].
class BikeFamily extends Family<BikeState> {
  /// See also [Bike].
  const BikeFamily();

  /// See also [Bike].
  BikeProvider call(
    String id,
  ) {
    return BikeProvider(
      id,
    );
  }

  @override
  BikeProvider getProviderOverride(
    covariant BikeProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bikeProvider';
}

/// See also [Bike].
class BikeProvider extends AutoDisposeNotifierProviderImpl<Bike, BikeState> {
  /// See also [Bike].
  BikeProvider(
    this.id,
  ) : super.internal(
          () => Bike()..id = id,
          from: bikeProvider,
          name: r'bikeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$bikeHash,
          dependencies: BikeFamily._dependencies,
          allTransitiveDependencies: BikeFamily._allTransitiveDependencies,
        );

  final String id;

  @override
  bool operator ==(Object other) {
    return other is BikeProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }

  @override
  BikeState runNotifierBuild(
    covariant Bike notifier,
  ) {
    return notifier.build(
      id,
    );
  }
}
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
