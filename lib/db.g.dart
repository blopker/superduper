// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsModelImpl _$$SettingsModelImplFromJson(Map<String, dynamic> json) =>
    _$SettingsModelImpl(
      currentBike: json['currentBike'] as String?,
    );

Map<String, dynamic> _$$SettingsModelImplToJson(_$SettingsModelImpl instance) =>
    <String, dynamic>{
      'currentBike': instance.currentBike,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentBikeHash() => r'bb376531c020f9ab89be1f6d99650fe42e87388f';

/// See also [currentBike].
@ProviderFor(currentBike)
final currentBikeProvider = Provider<BikeState?>.internal(
  currentBike,
  name: r'currentBikeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentBikeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentBikeRef = ProviderRef<BikeState?>;
String _$bikesDBHash() => r'cc01f2e468778981a9e5b99c2a06934115b892ce';

/// See also [BikesDB].
@ProviderFor(BikesDB)
final bikesDBProvider = NotifierProvider<BikesDB, List<BikeState>>.internal(
  BikesDB.new,
  name: r'bikesDBProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bikesDBHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BikesDB = Notifier<List<BikeState>>;
String _$settingsDBHash() => r'0ec838671520d405c0d8acd9fb09eb186373556f';

/// See also [SettingsDB].
@ProviderFor(SettingsDB)
final settingsDBProvider = NotifierProvider<SettingsDB, SettingsModel>.internal(
  SettingsDB.new,
  name: r'settingsDBProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsDBHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsDB = Notifier<SettingsModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
