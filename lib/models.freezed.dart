// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BikeState _$BikeStateFromJson(Map<String, dynamic> json) {
  return _BikeState.fromJson(json);
}

/// @nodoc
mixin _$BikeState {
  String get id => throw _privateConstructorUsedError;
  int get mode => throw _privateConstructorUsedError;
  bool get modeLocked => throw _privateConstructorUsedError;
  bool get light => throw _privateConstructorUsedError;
  bool get lightLocked => throw _privateConstructorUsedError;
  int get assist => throw _privateConstructorUsedError;
  bool get assistLocked => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  BikeRegion? get region => throw _privateConstructorUsedError;
  bool get modeLock => throw _privateConstructorUsedError;
  bool get selected => throw _privateConstructorUsedError;
  double get speedKM => throw _privateConstructorUsedError;
  double get speedMI => throw _privateConstructorUsedError;
  int get range => throw _privateConstructorUsedError;
  double get battery => throw _privateConstructorUsedError;
  double get voltage => throw _privateConstructorUsedError;
  int get color => throw _privateConstructorUsedError;
  String get speedMetric => throw _privateConstructorUsedError;
  String get batteryMetric => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BikeStateCopyWith<BikeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BikeStateCopyWith<$Res> {
  factory $BikeStateCopyWith(BikeState value, $Res Function(BikeState) then) =
      _$BikeStateCopyWithImpl<$Res, BikeState>;
  @useResult
  $Res call(
      {String id,
      int mode,
      bool modeLocked,
      bool light,
      bool lightLocked,
      int assist,
      bool assistLocked,
      String name,
      BikeRegion? region,
      bool modeLock,
      bool selected,
      double speedKM,
      double speedMI,
      int range,
      double battery,
      double voltage,
      int color,
      String speedMetric,
      String batteryMetric});
}

/// @nodoc
class _$BikeStateCopyWithImpl<$Res, $Val extends BikeState>
    implements $BikeStateCopyWith<$Res> {
  _$BikeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mode = null,
    Object? modeLocked = null,
    Object? light = null,
    Object? lightLocked = null,
    Object? assist = null,
    Object? assistLocked = null,
    Object? name = null,
    Object? region = freezed,
    Object? modeLock = null,
    Object? selected = null,
    Object? speedKM = null,
    Object? speedMI = null,
    Object? range = null,
    Object? battery = null,
    Object? voltage = null,
    Object? color = null,
    Object? speedMetric = null,
    Object? batteryMetric = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      modeLocked: null == modeLocked
          ? _value.modeLocked
          : modeLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      light: null == light
          ? _value.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      lightLocked: null == lightLocked
          ? _value.lightLocked
          : lightLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _value.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      assistLocked: null == assistLocked
          ? _value.assistLocked
          : assistLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      modeLock: null == modeLock
          ? _value.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      speedKM: null == speedKM
          ? _value.speedKM
          : speedKM // ignore: cast_nullable_to_non_nullable
              as double,
      speedMI: null == speedMI
          ? _value.speedMI
          : speedMI // ignore: cast_nullable_to_non_nullable
              as double,
      range: null == range
          ? _value.range
          : range // ignore: cast_nullable_to_non_nullable
              as int,
      battery: null == battery
          ? _value.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as double,
      voltage: null == voltage
          ? _value.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
      speedMetric: null == speedMetric
          ? _value.speedMetric
          : speedMetric // ignore: cast_nullable_to_non_nullable
              as String,
      batteryMetric: null == batteryMetric
          ? _value.batteryMetric
          : batteryMetric // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BikeStateImplCopyWith<$Res>
    implements $BikeStateCopyWith<$Res> {
  factory _$$BikeStateImplCopyWith(
          _$BikeStateImpl value, $Res Function(_$BikeStateImpl) then) =
      __$$BikeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int mode,
      bool modeLocked,
      bool light,
      bool lightLocked,
      int assist,
      bool assistLocked,
      String name,
      BikeRegion? region,
      bool modeLock,
      bool selected,
      double speedKM,
      double speedMI,
      int range,
      double battery,
      double voltage,
      int color,
      String speedMetric,
      String batteryMetric});
}

/// @nodoc
class __$$BikeStateImplCopyWithImpl<$Res>
    extends _$BikeStateCopyWithImpl<$Res, _$BikeStateImpl>
    implements _$$BikeStateImplCopyWith<$Res> {
  __$$BikeStateImplCopyWithImpl(
      _$BikeStateImpl _value, $Res Function(_$BikeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mode = null,
    Object? modeLocked = null,
    Object? light = null,
    Object? lightLocked = null,
    Object? assist = null,
    Object? assistLocked = null,
    Object? name = null,
    Object? region = freezed,
    Object? modeLock = null,
    Object? selected = null,
    Object? speedKM = null,
    Object? speedMI = null,
    Object? range = null,
    Object? battery = null,
    Object? voltage = null,
    Object? color = null,
    Object? speedMetric = null,
    Object? batteryMetric = null,
  }) {
    return _then(_$BikeStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      modeLocked: null == modeLocked
          ? _value.modeLocked
          : modeLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      light: null == light
          ? _value.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      lightLocked: null == lightLocked
          ? _value.lightLocked
          : lightLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _value.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      assistLocked: null == assistLocked
          ? _value.assistLocked
          : assistLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      modeLock: null == modeLock
          ? _value.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      speedKM: null == speedKM
          ? _value.speedKM
          : speedKM // ignore: cast_nullable_to_non_nullable
              as double,
      speedMI: null == speedMI
          ? _value.speedMI
          : speedMI // ignore: cast_nullable_to_non_nullable
              as double,
      range: null == range
          ? _value.range
          : range // ignore: cast_nullable_to_non_nullable
              as int,
      battery: null == battery
          ? _value.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as double,
      voltage: null == voltage
          ? _value.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
      speedMetric: null == speedMetric
          ? _value.speedMetric
          : speedMetric // ignore: cast_nullable_to_non_nullable
              as String,
      batteryMetric: null == batteryMetric
          ? _value.batteryMetric
          : batteryMetric // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BikeStateImpl extends _BikeState {
  const _$BikeStateImpl(
      {required this.id,
      required this.mode,
      this.modeLocked = false,
      required this.light,
      this.lightLocked = false,
      required this.assist,
      this.assistLocked = false,
      required this.name,
      this.region,
      this.modeLock = false,
      this.selected = false,
      this.speedKM = 0,
      this.speedMI = 0,
      this.range = 0,
      this.battery = 0,
      this.voltage = 0,
      this.color = 0,
      this.speedMetric = 'metric',
      this.batteryMetric = 'percent'})
      : assert(mode <= 3),
        assert(mode >= 0),
        assert(assist >= 0),
        assert(assist <= 4),
        assert(color >= 0),
        assert(speedKM >= 0),
        assert(speedKM <= 100),
        assert(speedMI >= 0),
        assert(speedMI <= 100),
        assert(range >= 0),
        assert(range <= 65),
        assert(battery >= 0),
        assert(battery <= 100),
        assert(voltage >= 0),
        assert(voltage <= 55),
        assert(speedMetric == "metric" || speedMetric == "imperial"),
        assert(batteryMetric == "percent" || batteryMetric == "voltage"),
        super._();

  factory _$BikeStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$BikeStateImplFromJson(json);

  @override
  final String id;
  @override
  final int mode;
  @override
  @JsonKey()
  final bool modeLocked;
  @override
  final bool light;
  @override
  @JsonKey()
  final bool lightLocked;
  @override
  final int assist;
  @override
  @JsonKey()
  final bool assistLocked;
  @override
  final String name;
  @override
  final BikeRegion? region;
  @override
  @JsonKey()
  final bool modeLock;
  @override
  @JsonKey()
  final bool selected;
  @override
  @JsonKey()
  final double speedKM;
  @override
  @JsonKey()
  final double speedMI;
  @override
  @JsonKey()
  final int range;
  @override
  @JsonKey()
  final double battery;
  @override
  @JsonKey()
  final double voltage;
  @override
  @JsonKey()
  final int color;
  @override
  @JsonKey()
  final String speedMetric;
  @override
  @JsonKey()
  final String batteryMetric;

  @override
  String toString() {
    return 'BikeState(id: $id, mode: $mode, modeLocked: $modeLocked, light: $light, lightLocked: $lightLocked, assist: $assist, assistLocked: $assistLocked, name: $name, region: $region, modeLock: $modeLock, selected: $selected, speedKM: $speedKM, speedMI: $speedMI, range: $range, battery: $battery, voltage: $voltage, color: $color, speedMetric: $speedMetric, batteryMetric: $batteryMetric)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BikeStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.modeLocked, modeLocked) ||
                other.modeLocked == modeLocked) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.lightLocked, lightLocked) ||
                other.lightLocked == lightLocked) &&
            (identical(other.assist, assist) || other.assist == assist) &&
            (identical(other.assistLocked, assistLocked) ||
                other.assistLocked == assistLocked) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.modeLock, modeLock) ||
                other.modeLock == modeLock) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.speedKM, speedKM) || other.speedKM == speedKM) &&
            (identical(other.speedMI, speedMI) || other.speedMI == speedMI) &&
            (identical(other.range, range) || other.range == range) &&
            (identical(other.battery, battery) || other.battery == battery) &&
            (identical(other.voltage, voltage) || other.voltage == voltage) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.speedMetric, speedMetric) ||
                other.speedMetric == speedMetric) &&
            (identical(other.batteryMetric, batteryMetric) ||
                other.batteryMetric == batteryMetric));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        mode,
        modeLocked,
        light,
        lightLocked,
        assist,
        assistLocked,
        name,
        region,
        modeLock,
        selected,
        speedKM,
        speedMI,
        range,
        battery,
        voltage,
        color,
        speedMetric,
        batteryMetric
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BikeStateImplCopyWith<_$BikeStateImpl> get copyWith =>
      __$$BikeStateImplCopyWithImpl<_$BikeStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BikeStateImplToJson(
      this,
    );
  }
}

abstract class _BikeState extends BikeState {
  const factory _BikeState(
      {required final String id,
      required final int mode,
      final bool modeLocked,
      required final bool light,
      final bool lightLocked,
      required final int assist,
      final bool assistLocked,
      required final String name,
      final BikeRegion? region,
      final bool modeLock,
      final bool selected,
      final double speedKM,
      final double speedMI,
      final int range,
      final double battery,
      final double voltage,
      final int color,
      final String speedMetric,
      final String batteryMetric}) = _$BikeStateImpl;
  const _BikeState._() : super._();

  factory _BikeState.fromJson(Map<String, dynamic> json) =
      _$BikeStateImpl.fromJson;

  @override
  String get id;
  @override
  int get mode;
  @override
  bool get modeLocked;
  @override
  bool get light;
  @override
  bool get lightLocked;
  @override
  int get assist;
  @override
  bool get assistLocked;
  @override
  String get name;
  @override
  BikeRegion? get region;
  @override
  bool get modeLock;
  @override
  bool get selected;
  @override
  double get speedKM;
  @override
  double get speedMI;
  @override
  int get range;
  @override
  double get battery;
  @override
  double get voltage;
  @override
  int get color;
  @override
  String get speedMetric;
  @override
  String get batteryMetric;
  @override
  @JsonKey(ignore: true)
  _$$BikeStateImplCopyWith<_$BikeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
