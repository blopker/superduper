// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BikeState {
  String get id;
  int get mode;
  bool get light;
  int get assist;

  /// Create a copy of BikeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BikeStateCopyWith<BikeState> get copyWith =>
      _$BikeStateCopyWithImpl<BikeState>(this as BikeState, _$identity);

  /// Serializes this BikeState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BikeState &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.assist, assist) || other.assist == assist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mode, light, assist);

  @override
  String toString() {
    return 'BikeState(id: $id, mode: $mode, light: $light, assist: $assist)';
  }
}

/// @nodoc
abstract mixin class $BikeStateCopyWith<$Res> {
  factory $BikeStateCopyWith(BikeState value, $Res Function(BikeState) _then) =
      _$BikeStateCopyWithImpl;
  @useResult
  $Res call({String id, int mode, bool light, int assist});
}

/// @nodoc
class _$BikeStateCopyWithImpl<$Res> implements $BikeStateCopyWith<$Res> {
  _$BikeStateCopyWithImpl(this._self, this._then);

  final BikeState _self;
  final $Res Function(BikeState) _then;

  /// Create a copy of BikeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mode = null,
    Object? light = null,
    Object? assist = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      light: null == light
          ? _self.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _self.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BikeState extends BikeState {
  const _BikeState(
      {required this.id,
      required this.mode,
      required this.light,
      required this.assist})
      : assert(mode <= 7),
        assert(mode >= 0),
        assert(assist >= 0),
        assert(assist <= 4),
        super._();
  factory _BikeState.fromJson(Map<String, dynamic> json) =>
      _$BikeStateFromJson(json);

  @override
  final String id;
  @override
  final int mode;
  @override
  final bool light;
  @override
  final int assist;

  /// Create a copy of BikeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BikeStateCopyWith<_BikeState> get copyWith =>
      __$BikeStateCopyWithImpl<_BikeState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BikeStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BikeState &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.assist, assist) || other.assist == assist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mode, light, assist);

  @override
  String toString() {
    return 'BikeState(id: $id, mode: $mode, light: $light, assist: $assist)';
  }
}

/// @nodoc
abstract mixin class _$BikeStateCopyWith<$Res>
    implements $BikeStateCopyWith<$Res> {
  factory _$BikeStateCopyWith(
          _BikeState value, $Res Function(_BikeState) _then) =
      __$BikeStateCopyWithImpl;
  @override
  @useResult
  $Res call({String id, int mode, bool light, int assist});
}

/// @nodoc
class __$BikeStateCopyWithImpl<$Res> implements _$BikeStateCopyWith<$Res> {
  __$BikeStateCopyWithImpl(this._self, this._then);

  final _BikeState _self;
  final $Res Function(_BikeState) _then;

  /// Create a copy of BikeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? mode = null,
    Object? light = null,
    Object? assist = null,
  }) {
    return _then(_BikeState(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as int,
      light: null == light
          ? _self.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _self.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$BikeSettings {
  String get id;
  int? get lockedMode;
  bool? get lockedLight;
  int? get lockedAssist;
  bool? get active;
  bool get modeLock;
  String get name;
  BikeRegion? get region;
  int get color;

  /// Create a copy of BikeSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BikeSettingsCopyWith<BikeSettings> get copyWith =>
      _$BikeSettingsCopyWithImpl<BikeSettings>(
          this as BikeSettings, _$identity);

  /// Serializes this BikeSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BikeSettings &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lockedMode, lockedMode) ||
                other.lockedMode == lockedMode) &&
            (identical(other.lockedLight, lockedLight) ||
                other.lockedLight == lockedLight) &&
            (identical(other.lockedAssist, lockedAssist) ||
                other.lockedAssist == lockedAssist) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.modeLock, modeLock) ||
                other.modeLock == modeLock) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, lockedMode, lockedLight,
      lockedAssist, active, modeLock, name, region, color);

  @override
  String toString() {
    return 'BikeSettings(id: $id, lockedMode: $lockedMode, lockedLight: $lockedLight, lockedAssist: $lockedAssist, active: $active, modeLock: $modeLock, name: $name, region: $region, color: $color)';
  }
}

/// @nodoc
abstract mixin class $BikeSettingsCopyWith<$Res> {
  factory $BikeSettingsCopyWith(
          BikeSettings value, $Res Function(BikeSettings) _then) =
      _$BikeSettingsCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      int? lockedMode,
      bool? lockedLight,
      int? lockedAssist,
      bool? active,
      bool modeLock,
      String name,
      BikeRegion? region,
      int color});
}

/// @nodoc
class _$BikeSettingsCopyWithImpl<$Res> implements $BikeSettingsCopyWith<$Res> {
  _$BikeSettingsCopyWithImpl(this._self, this._then);

  final BikeSettings _self;
  final $Res Function(BikeSettings) _then;

  /// Create a copy of BikeSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lockedMode = freezed,
    Object? lockedLight = freezed,
    Object? lockedAssist = freezed,
    Object? active = freezed,
    Object? modeLock = null,
    Object? name = null,
    Object? region = freezed,
    Object? color = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lockedMode: freezed == lockedMode
          ? _self.lockedMode
          : lockedMode // ignore: cast_nullable_to_non_nullable
              as int?,
      lockedLight: freezed == lockedLight
          ? _self.lockedLight
          : lockedLight // ignore: cast_nullable_to_non_nullable
              as bool?,
      lockedAssist: freezed == lockedAssist
          ? _self.lockedAssist
          : lockedAssist // ignore: cast_nullable_to_non_nullable
              as int?,
      active: freezed == active
          ? _self.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      modeLock: null == modeLock
          ? _self.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: freezed == region
          ? _self.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BikeSettings extends BikeSettings {
  const _BikeSettings(
      {required this.id,
      required this.lockedMode,
      required this.lockedLight,
      required this.lockedAssist,
      required this.active,
      required this.modeLock,
      required this.name,
      required this.region,
      this.color = 0})
      : assert(color >= 0),
        super._();
  factory _BikeSettings.fromJson(Map<String, dynamic> json) =>
      _$BikeSettingsFromJson(json);

  @override
  final String id;
  @override
  final int? lockedMode;
  @override
  final bool? lockedLight;
  @override
  final int? lockedAssist;
  @override
  final bool? active;
  @override
  final bool modeLock;
  @override
  final String name;
  @override
  final BikeRegion? region;
  @override
  @JsonKey()
  final int color;

  /// Create a copy of BikeSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BikeSettingsCopyWith<_BikeSettings> get copyWith =>
      __$BikeSettingsCopyWithImpl<_BikeSettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BikeSettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BikeSettings &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lockedMode, lockedMode) ||
                other.lockedMode == lockedMode) &&
            (identical(other.lockedLight, lockedLight) ||
                other.lockedLight == lockedLight) &&
            (identical(other.lockedAssist, lockedAssist) ||
                other.lockedAssist == lockedAssist) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.modeLock, modeLock) ||
                other.modeLock == modeLock) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, lockedMode, lockedLight,
      lockedAssist, active, modeLock, name, region, color);

  @override
  String toString() {
    return 'BikeSettings(id: $id, lockedMode: $lockedMode, lockedLight: $lockedLight, lockedAssist: $lockedAssist, active: $active, modeLock: $modeLock, name: $name, region: $region, color: $color)';
  }
}

/// @nodoc
abstract mixin class _$BikeSettingsCopyWith<$Res>
    implements $BikeSettingsCopyWith<$Res> {
  factory _$BikeSettingsCopyWith(
          _BikeSettings value, $Res Function(_BikeSettings) _then) =
      __$BikeSettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      int? lockedMode,
      bool? lockedLight,
      int? lockedAssist,
      bool? active,
      bool modeLock,
      String name,
      BikeRegion? region,
      int color});
}

/// @nodoc
class __$BikeSettingsCopyWithImpl<$Res>
    implements _$BikeSettingsCopyWith<$Res> {
  __$BikeSettingsCopyWithImpl(this._self, this._then);

  final _BikeSettings _self;
  final $Res Function(_BikeSettings) _then;

  /// Create a copy of BikeSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? lockedMode = freezed,
    Object? lockedLight = freezed,
    Object? lockedAssist = freezed,
    Object? active = freezed,
    Object? modeLock = null,
    Object? name = null,
    Object? region = freezed,
    Object? color = null,
  }) {
    return _then(_BikeSettings(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lockedMode: freezed == lockedMode
          ? _self.lockedMode
          : lockedMode // ignore: cast_nullable_to_non_nullable
              as int?,
      lockedLight: freezed == lockedLight
          ? _self.lockedLight
          : lockedLight // ignore: cast_nullable_to_non_nullable
              as bool?,
      lockedAssist: freezed == lockedAssist
          ? _self.lockedAssist
          : lockedAssist // ignore: cast_nullable_to_non_nullable
              as int?,
      active: freezed == active
          ? _self.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      modeLock: null == modeLock
          ? _self.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      region: freezed == region
          ? _self.region
          : region // ignore: cast_nullable_to_non_nullable
              as BikeRegion?,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
