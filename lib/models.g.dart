// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BikeState _$$_BikeStateFromJson(Map<String, dynamic> json) => _$_BikeState(
      id: json['id'] as String,
      mode: json['mode'] as int,
      light: json['light'] as bool,
      assist: json['assist'] as int,
      name: json['name'] as String,
      region: $enumDecodeNullable(_$BikeRegionEnumMap, json['region']),
      modeLock: json['modeLock'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
    );

Map<String, dynamic> _$$_BikeStateToJson(_$_BikeState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mode': instance.mode,
      'light': instance.light,
      'assist': instance.assist,
      'name': instance.name,
      'region': _$BikeRegionEnumMap[instance.region],
      'modeLock': instance.modeLock,
      'selected': instance.selected,
    };

const _$BikeRegionEnumMap = {
  BikeRegion.us: 200,
  BikeRegion.eu: 201,
};
