// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bikeRepositoryHash() => r'3c9ece4b2d28fadaeb36c92d8e768f0293f7334e';

/// Provider for the bike repository.
///
/// Copied from [bikeRepository].
@ProviderFor(bikeRepository)
final bikeRepositoryProvider = Provider<BikeRepository>.internal(
  bikeRepository,
  name: r'bikeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bikeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BikeRepositoryRef = ProviderRef<BikeRepository>;
String _$bikesHash() => r'27b055d4c3044e46300d4d3aada5175930901cb1';

/// Provider for all bikes.
///
/// Copied from [bikes].
@ProviderFor(bikes)
final bikesProvider = AutoDisposeStreamProvider<List<BikeModel>>.internal(
  bikes,
  name: r'bikesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bikesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BikesRef = AutoDisposeStreamProviderRef<List<BikeModel>>;
String _$activeBikesHash() => r'3ab4c25627250673fe2d0ecb210203ba7f085d37';

/// Provider for active bikes.
///
/// Copied from [activeBikes].
@ProviderFor(activeBikes)
final activeBikesProvider = AutoDisposeProvider<List<BikeModel>>.internal(
  activeBikes,
  name: r'activeBikesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeBikesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveBikesRef = AutoDisposeProviderRef<List<BikeModel>>;
String _$bikeHash() => r'967719573df6fac2d8c5e93a0986315d7b196156';

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

/// Provider for a specific bike by ID.
///
/// Copied from [bike].
@ProviderFor(bike)
const bikeProvider = BikeFamily();

/// Provider for a specific bike by ID.
///
/// Copied from [bike].
class BikeFamily extends Family<BikeModel?> {
  /// Provider for a specific bike by ID.
  ///
  /// Copied from [bike].
  const BikeFamily();

  /// Provider for a specific bike by ID.
  ///
  /// Copied from [bike].
  BikeProvider call(
    String bikeId,
  ) {
    return BikeProvider(
      bikeId,
    );
  }

  @override
  BikeProvider getProviderOverride(
    covariant BikeProvider provider,
  ) {
    return call(
      provider.bikeId,
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

/// Provider for a specific bike by ID.
///
/// Copied from [bike].
class BikeProvider extends AutoDisposeProvider<BikeModel?> {
  /// Provider for a specific bike by ID.
  ///
  /// Copied from [bike].
  BikeProvider(
    String bikeId,
  ) : this._internal(
          (ref) => bike(
            ref as BikeRef,
            bikeId,
          ),
          from: bikeProvider,
          name: r'bikeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$bikeHash,
          dependencies: BikeFamily._dependencies,
          allTransitiveDependencies: BikeFamily._allTransitiveDependencies,
          bikeId: bikeId,
        );

  BikeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bikeId,
  }) : super.internal();

  final String bikeId;

  @override
  Override overrideWith(
    BikeModel? Function(BikeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BikeProvider._internal(
        (ref) => create(ref as BikeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bikeId: bikeId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<BikeModel?> createElement() {
    return _BikeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BikeProvider && other.bikeId == bikeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bikeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BikeRef on AutoDisposeProviderRef<BikeModel?> {
  /// The parameter `bikeId` of this provider.
  String get bikeId;
}

class _BikeProviderElement extends AutoDisposeProviderElement<BikeModel?>
    with BikeRef {
  _BikeProviderElement(super.provider);

  @override
  String get bikeId => (origin as BikeProvider).bikeId;
}

String _$bikeServiceHash() => r'f3fe63141cac76d20a282b1eb07a113d6fc75b01';

/// Provider for a bike service by bike ID.
///
/// Copied from [bikeService].
@ProviderFor(bikeService)
const bikeServiceProvider = BikeServiceFamily();

/// Provider for a bike service by bike ID.
///
/// Copied from [bikeService].
class BikeServiceFamily extends Family<BikeService?> {
  /// Provider for a bike service by bike ID.
  ///
  /// Copied from [bikeService].
  const BikeServiceFamily();

  /// Provider for a bike service by bike ID.
  ///
  /// Copied from [bikeService].
  BikeServiceProvider call(
    String bikeId,
  ) {
    return BikeServiceProvider(
      bikeId,
    );
  }

  @override
  BikeServiceProvider getProviderOverride(
    covariant BikeServiceProvider provider,
  ) {
    return call(
      provider.bikeId,
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
  String? get name => r'bikeServiceProvider';
}

/// Provider for a bike service by bike ID.
///
/// Copied from [bikeService].
class BikeServiceProvider extends AutoDisposeProvider<BikeService?> {
  /// Provider for a bike service by bike ID.
  ///
  /// Copied from [bikeService].
  BikeServiceProvider(
    String bikeId,
  ) : this._internal(
          (ref) => bikeService(
            ref as BikeServiceRef,
            bikeId,
          ),
          from: bikeServiceProvider,
          name: r'bikeServiceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bikeServiceHash,
          dependencies: BikeServiceFamily._dependencies,
          allTransitiveDependencies:
              BikeServiceFamily._allTransitiveDependencies,
          bikeId: bikeId,
        );

  BikeServiceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bikeId,
  }) : super.internal();

  final String bikeId;

  @override
  Override overrideWith(
    BikeService? Function(BikeServiceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BikeServiceProvider._internal(
        (ref) => create(ref as BikeServiceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bikeId: bikeId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<BikeService?> createElement() {
    return _BikeServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BikeServiceProvider && other.bikeId == bikeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bikeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BikeServiceRef on AutoDisposeProviderRef<BikeService?> {
  /// The parameter `bikeId` of this provider.
  String get bikeId;
}

class _BikeServiceProviderElement
    extends AutoDisposeProviderElement<BikeService?> with BikeServiceRef {
  _BikeServiceProviderElement(super.provider);

  @override
  String get bikeId => (origin as BikeServiceProvider).bikeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
