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

BikeState _$BikeStateFromJson(Map<String, dynamic> json) {
  return _BikeState.fromJson(json);
}

/// @nodoc
mixin _$BikeState {
  String get id => throw _privateConstructorUsedError;
  int get mode => throw _privateConstructorUsedError;
  bool get light => throw _privateConstructorUsedError;
  int get assist => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get modeLock => throw _privateConstructorUsedError;
  bool get selected => throw _privateConstructorUsedError;

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
      bool light,
      int assist,
      String name,
      bool modeLock,
      bool selected});
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
    Object? light = null,
    Object? assist = null,
    Object? name = null,
    Object? modeLock = null,
    Object? selected = null,
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
      light: null == light
          ? _value.light
          : light // ignore: cast_nullable_to_non_nullable
              as bool,
      assist: null == assist
          ? _value.assist
          : assist // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      modeLock: null == modeLock
          ? _value.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
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
      int mode,
      bool light,
      int assist,
      String name,
      bool modeLock,
      bool selected});
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
    Object? mode = null,
    Object? light = null,
    Object? assist = null,
    Object? name = null,
    Object? modeLock = null,
    Object? selected = null,
  }) {
    return _then(_$_BikeState(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      modeLock: null == modeLock
          ? _value.modeLock
          : modeLock // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BikeState extends _BikeState {
  const _$_BikeState(
      {required this.id,
      required this.mode,
      required this.light,
      required this.assist,
      required this.name,
      this.modeLock = false,
      this.selected = false})
      : assert(mode <= 3),
        assert(mode >= 0),
        assert(assist >= 0),
        assert(assist <= 4),
        super._();

  factory _$_BikeState.fromJson(Map<String, dynamic> json) =>
      _$$_BikeStateFromJson(json);

  @override
  final String id;
  @override
  final int mode;
  @override
  final bool light;
  @override
  final int assist;
  @override
  final String name;
  @override
  @JsonKey()
  final bool modeLock;
  @override
  @JsonKey()
  final bool selected;

  @override
  String toString() {
    return 'BikeState(id: $id, mode: $mode, light: $light, assist: $assist, name: $name, modeLock: $modeLock, selected: $selected)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BikeState &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.light, light) || other.light == light) &&
            (identical(other.assist, assist) || other.assist == assist) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.modeLock, modeLock) ||
                other.modeLock == modeLock) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, mode, light, assist, name, modeLock, selected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BikeStateCopyWith<_$_BikeState> get copyWith =>
      __$$_BikeStateCopyWithImpl<_$_BikeState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BikeStateToJson(
      this,
    );
  }
}

abstract class _BikeState extends BikeState {
  const factory _BikeState(
      {required final String id,
      required final int mode,
      required final bool light,
      required final int assist,
      required final String name,
      final bool modeLock,
      final bool selected}) = _$_BikeState;
  const _BikeState._() : super._();

  factory _BikeState.fromJson(Map<String, dynamic> json) =
      _$_BikeState.fromJson;

  @override
  String get id;
  @override
  int get mode;
  @override
  bool get light;
  @override
  int get assist;
  @override
  String get name;
  @override
  bool get modeLock;
  @override
  bool get selected;
  @override
  @JsonKey(ignore: true)
  _$$_BikeStateCopyWith<_$_BikeState> get copyWith =>
      throw _privateConstructorUsedError;
}
