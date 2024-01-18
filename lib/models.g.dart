// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BikeStateImpl _$$BikeStateImplFromJson(Map<String, dynamic> json) =>
    _$BikeStateImpl(
      id: json['id'] as String,
      mode: json['mode'] as int,
      modeLocked: json['modeLocked'] as bool? ?? false,
      light: json['light'] as bool,
      lightLocked: json['lightLocked'] as bool? ?? false,
      assist: json['assist'] as int,
      assistLocked: json['assistLocked'] as bool? ?? false,
      name: json['name'] as String,
      region: $enumDecodeNullable(_$BikeRegionEnumMap, json['region']),
      modeLock: json['modeLock'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
      speed: (json['speed'] as num).toDouble(),
      battery: (json['battery'] as num).toDouble(),
      color: json['color'] as int? ?? 0,
    );

Map<String, dynamic> _$$BikeStateImplToJson(_$BikeStateImpl instance) =>
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
      'selected': instance.selected,
      'speed': instance.speed,
      'battery': instance.battery,
      'color': instance.color,
    };

const _$BikeRegionEnumMap = {
  BikeRegion.us: 200,
  BikeRegion.eu: 201,
};
