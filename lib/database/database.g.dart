// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    _SettingsModel(
      currentBike: json['currentBike'] as String?,
      bikeSettings: (json['bikeSettings'] as List<dynamic>)
          .map((e) => BikeSettings.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SettingsModelToJson(_SettingsModel instance) =>
    <String, dynamic>{
      'currentBike': instance.currentBike,
      'bikeSettings': instance.bikeSettings,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsDBHash() => r'5e8f3d7f41e41e685bcdbac6e63f97c544e4c95c';

/// See also [SettingsDB].
@ProviderFor(SettingsDB)
final settingsDBProvider =
    AsyncNotifierProvider<SettingsDB, SettingsModel>.internal(
  SettingsDB.new,
  name: r'settingsDBProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsDBHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsDB = AsyncNotifier<SettingsModel>;
String _$bikeDBHash() => r'a2987c38fdef517447eb92469c9a7e720126970e';

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

abstract class _$BikeDB extends BuildlessAutoDisposeNotifier<BikeSettings?> {
  late final String id;

  BikeSettings? build(
    String id,
  );
}

/// See also [BikeDB].
@ProviderFor(BikeDB)
const bikeDBProvider = BikeDBFamily();

/// See also [BikeDB].
class BikeDBFamily extends Family<BikeSettings?> {
  /// See also [BikeDB].
  const BikeDBFamily();

  /// See also [BikeDB].
  BikeDBProvider call(
    String id,
  ) {
    return BikeDBProvider(
      id,
    );
  }

  @override
  BikeDBProvider getProviderOverride(
    covariant BikeDBProvider provider,
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
  String? get name => r'bikeDBProvider';
}

/// See also [BikeDB].
class BikeDBProvider
    extends AutoDisposeNotifierProviderImpl<BikeDB, BikeSettings?> {
  /// See also [BikeDB].
  BikeDBProvider(
    String id,
  ) : this._internal(
          () => BikeDB()..id = id,
          from: bikeDBProvider,
          name: r'bikeDBProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bikeDBHash,
          dependencies: BikeDBFamily._dependencies,
          allTransitiveDependencies: BikeDBFamily._allTransitiveDependencies,
          id: id,
        );

  BikeDBProvider._internal(
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
  BikeSettings? runNotifierBuild(
    covariant BikeDB notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(BikeDB Function() create) {
    return ProviderOverride(
      origin: this,
      override: BikeDBProvider._internal(
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
  AutoDisposeNotifierProviderElement<BikeDB, BikeSettings?> createElement() {
    return _BikeDBProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BikeDBProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BikeDBRef on AutoDisposeNotifierProviderRef<BikeSettings?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BikeDBProviderElement
    extends AutoDisposeNotifierProviderElement<BikeDB, BikeSettings?>
    with BikeDBRef {
  _BikeDBProviderElement(super.provider);

  @override
  String get id => (origin as BikeDBProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
