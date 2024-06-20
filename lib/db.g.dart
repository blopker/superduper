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

String _$bikesDBHash() => r'8b043ff7676ab87545bf02676e8500f730f4acd6';

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
String _$settingsDBHash() => r'9d9f31c16ae24aad4da3a06e4815bbecfa11d966';

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
