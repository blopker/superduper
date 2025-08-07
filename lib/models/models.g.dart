// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BikeState _$BikeStateFromJson(Map<String, dynamic> json) => _BikeState(
      id: json['id'] as String,
      mode: (json['mode'] as num).toInt(),
      light: json['light'] as bool,
      assist: (json['assist'] as num).toInt(),
    );

Map<String, dynamic> _$BikeStateToJson(_BikeState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mode': instance.mode,
      'light': instance.light,
      'assist': instance.assist,
    };

_BikeSettings _$BikeSettingsFromJson(Map<String, dynamic> json) =>
    _BikeSettings(
      id: json['id'] as String,
      lockedMode: (json['lockedMode'] as num?)?.toInt(),
      lockedLight: json['lockedLight'] as bool?,
      lockedAssist: (json['lockedAssist'] as num?)?.toInt(),
      active: json['active'] as bool?,
      modeLock: json['modeLock'] as bool,
      name: json['name'] as String,
      region: $enumDecodeNullable(_$BikeRegionEnumMap, json['region']),
      color: (json['color'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BikeSettingsToJson(_BikeSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lockedMode': instance.lockedMode,
      'lockedLight': instance.lockedLight,
      'lockedAssist': instance.lockedAssist,
      'active': instance.active,
      'modeLock': instance.modeLock,
      'name': instance.name,
      'region': _$BikeRegionEnumMap[instance.region],
      'color': instance.color,
    };

const _$BikeRegionEnumMap = {
  BikeRegion.us: 200,
  BikeRegion.eu: 201,
};
