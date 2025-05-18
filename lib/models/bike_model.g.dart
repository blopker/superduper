// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BikeModel _$BikeModelFromJson(Map<String, dynamic> json) => _BikeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      bluetoothAddress: json['bluetoothAddress'] as String,
      isActive: json['isActive'] as bool? ?? false,
      mode: (json['mode'] as num?)?.toInt() ?? 0,
      modeLocked: json['modeLocked'] as bool? ?? false,
      light: json['light'] as bool? ?? false,
      lightLocked: json['lightLocked'] as bool? ?? false,
      assist: (json['assist'] as num?)?.toInt() ?? 0,
      assistLocked: json['assistLocked'] as bool? ?? false,
      backgroundLock: json['backgroundLock'] as bool? ?? false,
      region: $enumDecodeNullable(_$BikeRegionEnumMap, json['region']),
      color: (json['color'] as num?)?.toInt() ?? 0,
      isConnected: json['isConnected'] as bool? ?? false,
    );

Map<String, dynamic> _$BikeModelToJson(_BikeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bluetoothAddress': instance.bluetoothAddress,
      'isActive': instance.isActive,
      'mode': instance.mode,
      'modeLocked': instance.modeLocked,
      'light': instance.light,
      'lightLocked': instance.lightLocked,
      'assist': instance.assist,
      'assistLocked': instance.assistLocked,
      'backgroundLock': instance.backgroundLock,
      if (_$BikeRegionEnumMap[instance.region] case final value?)
        'region': value,
      'color': instance.color,
      'isConnected': instance.isConnected,
    };

const _$BikeRegionEnumMap = {
  BikeRegion.us: 200,
  BikeRegion.eu: 201,
};
