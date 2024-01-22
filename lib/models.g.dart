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
      speedKM: (json['speedKM'] as num).toDouble(),
      speedMI: (json['speedMI'] as num).toDouble(),
      range: json['range'] as int,
      battery: (json['battery'] as num).toDouble(),
      voltage: (json['voltage'] as num).toDouble(),
      color: json['color'] as int? ?? 0,
      speedMetric: json['speedMetric'] as String? ?? 'metric',
      batteryMetric: json['batteryMetric'] as String? ?? 'percent',
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
      'speedKM': instance.speedKM,
      'speedMI': instance.speedMI,
      'range': instance.range,
      'battery': instance.battery,
      'voltage': instance.voltage,
      'color': instance.color,
      'speedMetric': instance.speedMetric,
      'batteryMetric': instance.batteryMetric,
    };

const _$BikeRegionEnumMap = {
  BikeRegion.us: 200,
  BikeRegion.eu: 201,
};
