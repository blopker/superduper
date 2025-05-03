// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    _SettingsModel(
      currentBike: json['currentBike'] as String?,
    );

Map<String, dynamic> _$SettingsModelToJson(_SettingsModel instance) =>
    <String, dynamic>{
      'currentBike': instance.currentBike,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bikesDBHash() => r'6cd7ea11ee3e778fe32b8881b85fe6fc8fbbf7aa';

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
String _$settingsDBHash() => r'c1b81df023c89fc2298d471ebe01bbb4d21b411c';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
