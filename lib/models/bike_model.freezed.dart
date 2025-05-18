// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bike_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BikeModel {
  String get id;
  String get name;
  String get bluetoothAddress;
  bool get isActive;
  int get mode;
  bool get modeLocked;
  bool get light;
  bool get lightLocked;
  int get assist;
  bool get assistLocked;
  bool get backgroundLock;
  BikeRegion? get region;
  int get color;
  bool get isConnected;

  /// Create a copy of BikeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BikeModelCopyWith<BikeModel> get copyWith =>
      _$BikeModelCopyWithImpl<BikeModel>(this as BikeModel, _$identity);

  /// Serializes this BikeModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BikeModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bluetoothAddress, bluetoothAddress) ||
                other.bluetoothAddress == bluetoothAddress) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.modeLocked, modeLocked) ||
                other.modeLocked == modeLocked) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.lightLocked, lightLocked) ||
                other.lightLocked == lightLocked) &&
            (identical(other.assist, assist) || other.assist == assist) &&
            (identical(other.assistLocked, assistLocked) ||
                other.assistLocked == assistLocked) &&
            (identical(other.backgroundLock, backgroundLock) ||
                other.backgroundLock == backgroundLock) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      bluetoothAddress,
      isActive,
      mode,
      modeLocked,
      light,
      lightLocked,
      assist,
      assistLocked,
      backgroundLock,
      region,
      color,
      isConnected);

  @override
  String toString() {
    return 'BikeModel(id: $id, name: $name, bluetoothAddress: $bluetoothAddress, isActive: $isActive, mode: $mode, modeLocked: $modeLocked, light: $light, lightLocked: $lightLocked, assist: $assist, assistLocked: $assistLocked, backgroundLock: $backgroundLock, region: $region, color: $color, isConnected: $isConnected)';
  }
}

/// @nodoc
abstract mixin class $BikeModelCopyWith<$Res> {
  factory $BikeModelCopyWith(BikeModel value, $Res Function(BikeModel) _then) =
      _$BikeModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String bluetoothAddress,
      bool isActive,
      int mode,
      bool modeLocked,
      bool light,
      bool lightLocked,
      int assist,
      bool assistLocked,
      bool backgroundLock,
      BikeRegion? region,
      int color,
      bool isConnected});
}

/// @nodoc
class _$BikeModelCopyWithImpl<$Res> implements $BikeModelCopyWith<$Res> {
  _$BikeModelCopyWithImpl(this._self, this._then);

  final BikeModel _self;
  final $Res Function(BikeModel) _then;

  /// Create a copy of BikeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bluetoothAddress = null,
    Object? isActive = null,
    Object? mode = null,
    Object? modeLocked = null,
    Object? light = null,
    Object? lightLocked = null,
    Object? assist = null,
    Object? assistLocked = null,
    Object? backgroundLock = null,
    Object? region = freezed,
    Object? color = null,
    Object? isConnected = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      bluetoothAddress: null == bluetoothAddress
          ? _self.bluetoothAddress
          : bluetoothAddress // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      modeLocked: null == modeLocked
          ? _self.modeLocked
          : modeLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      light: null == light
          ? _self.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      lightLocked: null == lightLocked
          ? _self.lightLocked
          : lightLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _self.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      assistLocked: null == assistLocked
          ? _self.assistLocked
          : assistLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      backgroundLock: null == backgroundLock
          ? _self.backgroundLock
          : backgroundLock // ignore: cast_nullable_to_non_nullable
              as bool,
      region: freezed == region
          ? _self.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
      isConnected: null == isConnected
          ? _self.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BikeModel extends BikeModel {
  const _BikeModel(
      {required this.id,
      required this.name,
      required this.bluetoothAddress,
      this.isActive = false,
      this.mode = 0,
      this.modeLocked = false,
      this.light = false,
      this.lightLocked = false,
      this.assist = 0,
      this.assistLocked = false,
      this.backgroundLock = false,
      this.region,
      this.color = 0,
      this.isConnected = false})
      : assert(mode <= 3),
        assert(mode >= 0),
        assert(assist >= 0),
        assert(assist <= 4),
        super._();
  factory _BikeModel.fromJson(Map<String, dynamic> json) =>
      _$BikeModelFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String bluetoothAddress;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final int mode;
  @override
  @JsonKey()
  final bool modeLocked;
  @override
  @JsonKey()
  final bool light;
  @override
  @JsonKey()
  final bool lightLocked;
  @override
  @JsonKey()
  final int assist;
  @override
  @JsonKey()
  final bool assistLocked;
  @override
  @JsonKey()
  final bool backgroundLock;
  @override
  final BikeRegion? region;
  @override
  @JsonKey()
  final int color;
  @override
  @JsonKey()
  final bool isConnected;

  /// Create a copy of BikeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BikeModelCopyWith<_BikeModel> get copyWith =>
      __$BikeModelCopyWithImpl<_BikeModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BikeModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BikeModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bluetoothAddress, bluetoothAddress) ||
                other.bluetoothAddress == bluetoothAddress) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.modeLocked, modeLocked) ||
                other.modeLocked == modeLocked) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.lightLocked, lightLocked) ||
                other.lightLocked == lightLocked) &&
            (identical(other.assist, assist) || other.assist == assist) &&
            (identical(other.assistLocked, assistLocked) ||
                other.assistLocked == assistLocked) &&
            (identical(other.backgroundLock, backgroundLock) ||
                other.backgroundLock == backgroundLock) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      bluetoothAddress,
      isActive,
      mode,
      modeLocked,
      light,
      lightLocked,
      assist,
      assistLocked,
      backgroundLock,
      region,
      color,
      isConnected);

  @override
  String toString() {
    return 'BikeModel(id: $id, name: $name, bluetoothAddress: $bluetoothAddress, isActive: $isActive, mode: $mode, modeLocked: $modeLocked, light: $light, lightLocked: $lightLocked, assist: $assist, assistLocked: $assistLocked, backgroundLock: $backgroundLock, region: $region, color: $color, isConnected: $isConnected)';
  }
}

/// @nodoc
abstract mixin class _$BikeModelCopyWith<$Res>
    implements $BikeModelCopyWith<$Res> {
  factory _$BikeModelCopyWith(
          _BikeModel value, $Res Function(_BikeModel) _then) =
      __$BikeModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String bluetoothAddress,
      bool isActive,
      int mode,
      bool modeLocked,
      bool light,
      bool lightLocked,
      int assist,
      bool assistLocked,
      bool backgroundLock,
      BikeRegion? region,
      int color,
      bool isConnected});
}

/// @nodoc
class __$BikeModelCopyWithImpl<$Res> implements _$BikeModelCopyWith<$Res> {
  __$BikeModelCopyWithImpl(this._self, this._then);

  final _BikeModel _self;
  final $Res Function(_BikeModel) _then;

  /// Create a copy of BikeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? bluetoothAddress = null,
    Object? isActive = null,
    Object? mode = null,
    Object? modeLocked = null,
    Object? light = null,
    Object? lightLocked = null,
    Object? assist = null,
    Object? assistLocked = null,
    Object? backgroundLock = null,
    Object? region = freezed,
    Object? color = null,
    Object? isConnected = null,
  }) {
    return _then(_BikeModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      bluetoothAddress: null == bluetoothAddress
          ? _self.bluetoothAddress
          : bluetoothAddress // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _self.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      modeLocked: null == modeLocked
          ? _self.modeLocked
          : modeLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      light: null == light
          ? _self.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      lightLocked: null == lightLocked
          ? _self.lightLocked
          : lightLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _self.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      assistLocked: null == assistLocked
          ? _self.assistLocked
          : assistLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      backgroundLock: null == backgroundLock
          ? _self.backgroundLock
          : backgroundLock // ignore: cast_nullable_to_non_nullable
              as bool,
      region: freezed == region
          ? _self.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
      isConnected: null == isConnected
          ? _self.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
