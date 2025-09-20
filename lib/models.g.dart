// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BikeState _$BikeStateFromJson(Map<String, dynamic> json) => _BikeState(
  id: json['id'] as String,
  mode: (json['mode'] as num).toInt(),
  modeLocked: json['modeLocked'] as bool? ?? false,
  light: json['light'] as bool,
  lightLocked: json['lightLocked'] as bool? ?? false,
  assist: (json['assist'] as num).toInt(),
  assistLocked: json['assistLocked'] as bool? ?? false,
  name: json['name'] as String,
  region: $enumDecodeNullable(_$BikeRegionEnumMap, json['region']),
  modeLock: json['modeLock'] as bool? ?? false,
  color: (json['color'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BikeStateToJson(_BikeState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mode': instance.mode,
      'modeLocked': instance.modeLocked,
      'light': instance.light,
      'lightLocked': instance.lightLocked,
      'assist': instance.assist,
      'assistLocked': instance.assistLocked,
      'name': instance.name,
      'region': _$BikeRegionEnumMap[instance.region],
      'modeLock': instance.modeLock,
      'color': instance.color,
    };

const _$BikeRegionEnumMap = {BikeRegion.us: 200, BikeRegion.eu: 201};
