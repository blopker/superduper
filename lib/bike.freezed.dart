// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bike.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$BikeState {
  String get id => throw _privateConstructorUsedError;
  double get rssi => throw _privateConstructorUsedError;
  int get mode => throw _privateConstructorUsedError;
  bool get light => throw _privateConstructorUsedError;
  int get assist => throw _privateConstructorUsedError;
  DeviceConnectionState get conectionStatus =>
      throw _privateConstructorUsedError;
  double get voltage => throw _privateConstructorUsedError;

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
      double rssi,
      int mode,
      bool light,
      int assist,
      DeviceConnectionState conectionStatus,
      double voltage});
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
    Object? rssi = null,
    Object? mode = null,
    Object? light = null,
    Object? assist = null,
    Object? conectionStatus = null,
    Object? voltage = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rssi: null == rssi
          ? _value.rssi
          : rssi // ignore: cast_nullable_to_non_nullable
              as double,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      light: null == light
          ? _value.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _value.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      conectionStatus: null == conectionStatus
          ? _value.conectionStatus
          : conectionStatus // ignore: cast_nullable_to_non_nullable
              as DeviceConnectionState,
      voltage: null == voltage
          ? _value.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_BikeStateCopyWith<$Res> implements $BikeStateCopyWith<$Res> {
  factory _$$_BikeStateCopyWith(
          _$_BikeState value, $Res Function(_$_BikeState) then) =
      __$$_BikeStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      double rssi,
      int mode,
      bool light,
      int assist,
      DeviceConnectionState conectionStatus,
      double voltage});
}

/// @nodoc
class __$$_BikeStateCopyWithImpl<$Res>
    extends _$BikeStateCopyWithImpl<$Res, _$_BikeState>
    implements _$$_BikeStateCopyWith<$Res> {
  __$$_BikeStateCopyWithImpl(
      _$_BikeState _value, $Res Function(_$_BikeState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? rssi = null,
    Object? mode = null,
    Object? light = null,
    Object? assist = null,
    Object? conectionStatus = null,
    Object? voltage = null,
  }) {
    return _then(_$_BikeState(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rssi: null == rssi
          ? _value.rssi
          : rssi // ignore: cast_nullable_to_non_nullable
              as double,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      light: null == light
          ? _value.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _value.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      conectionStatus: null == conectionStatus
          ? _value.conectionStatus
          : conectionStatus // ignore: cast_nullable_to_non_nullable
              as DeviceConnectionState,
      voltage: null == voltage
          ? _value.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$_BikeState extends _BikeState {
  const _$_BikeState(
      {required this.id,
      required this.rssi,
      required this.mode,
      required this.light,
      required this.assist,
      required this.conectionStatus,
      this.voltage = 0.0})
      : assert(mode <= 3),
        assert(mode >= 0),
        assert(assist >= 0),
        assert(assist <= 4),
        super._();

  @override
  final String id;
  @override
  final double rssi;
  @override
  final int mode;
  @override
  final bool light;
  @override
  final int assist;
  @override
  final DeviceConnectionState conectionStatus;
  @override
  @JsonKey()
  final double voltage;

  @override
  String toString() {
    return 'BikeState(id: $id, rssi: $rssi, mode: $mode, light: $light, assist: $assist, conectionStatus: $conectionStatus, voltage: $voltage)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BikeState &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rssi, rssi) || other.rssi == rssi) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.assist, assist) || other.assist == assist) &&
            (identical(other.conectionStatus, conectionStatus) ||
                other.conectionStatus == conectionStatus) &&
            (identical(other.voltage, voltage) || other.voltage == voltage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, rssi, mode, light, assist, conectionStatus, voltage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BikeStateCopyWith<_$_BikeState> get copyWith =>
      __$$_BikeStateCopyWithImpl<_$_BikeState>(this, _$identity);
}

abstract class _BikeState extends BikeState {
  const factory _BikeState(
      {required final String id,
      required final double rssi,
      required final int mode,
      required final bool light,
      required final int assist,
      required final DeviceConnectionState conectionStatus,
      final double voltage}) = _$_BikeState;
  const _BikeState._() : super._();

  @override
  String get id;
  @override
  double get rssi;
  @override
  int get mode;
  @override
  bool get light;
  @override
  int get assist;
  @override
  DeviceConnectionState get conectionStatus;
  @override
  double get voltage;
  @override
  @JsonKey(ignore: true)
  _$$_BikeStateCopyWith<_$_BikeState> get copyWith =>
      throw _privateConstructorUsedError;
}
