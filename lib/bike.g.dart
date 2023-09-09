// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bikeHash() => r'9267e4513a7935871ec5a1caff5a8f28b6fe7693';

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
    String id,
  ) : this._internal(
          () => Bike()..id = id,
          from: bikeProvider,
          name: r'bikeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$bikeHash,
          dependencies: BikeFamily._dependencies,
          allTransitiveDependencies: BikeFamily._allTransitiveDependencies,
          id: id,
        );

  BikeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  BikeState runNotifierBuild(
    covariant Bike notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(Bike Function() create) {
    return ProviderOverride(
      origin: this,
      override: BikeProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<Bike, BikeState> createElement() {
    return _BikeProviderElement(this);
  }

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
}

mixin BikeRef on AutoDisposeNotifierProviderRef<BikeState> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BikeProviderElement
    extends AutoDisposeNotifierProviderElement<Bike, BikeState> with BikeRef {
  _BikeProviderElement(super.provider);

  @override
  String get id => (origin as BikeProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
