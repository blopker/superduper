// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_bike.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SavedBike _$SavedBikeFromJson(Map<String, dynamic> json) {
  return _SavedBike.fromJson(json);
}

/// @nodoc
mixin _$SavedBike {
  String get id => throw _privateConstructorUsedError;
  bool get selected => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SavedBikeCopyWith<SavedBike> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedBikeCopyWith<$Res> {
  factory $SavedBikeCopyWith(SavedBike value, $Res Function(SavedBike) then) =
      _$SavedBikeCopyWithImpl<$Res, SavedBike>;
  @useResult
  $Res call({String id, bool selected, String? name});
}

/// @nodoc
class _$SavedBikeCopyWithImpl<$Res, $Val extends SavedBike>
    implements $SavedBikeCopyWith<$Res> {
  _$SavedBikeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? selected = null,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SavedBikeCopyWith<$Res> implements $SavedBikeCopyWith<$Res> {
  factory _$$_SavedBikeCopyWith(
          _$_SavedBike value, $Res Function(_$_SavedBike) then) =
      __$$_SavedBikeCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, bool selected, String? name});
}

/// @nodoc
class __$$_SavedBikeCopyWithImpl<$Res>
    extends _$SavedBikeCopyWithImpl<$Res, _$_SavedBike>
    implements _$$_SavedBikeCopyWith<$Res> {
  __$$_SavedBikeCopyWithImpl(
      _$_SavedBike _value, $Res Function(_$_SavedBike) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? selected = null,
    Object? name = freezed,
  }) {
    return _then(_$_SavedBike(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_SavedBike extends _SavedBike with DiagnosticableTreeMixin {
  const _$_SavedBike({required this.id, this.selected = false, this.name})
      : super._();

  factory _$_SavedBike.fromJson(Map<String, dynamic> json) =>
      _$$_SavedBikeFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final bool selected;
  @override
  final String? name;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SavedBike(id: $id, selected: $selected, name: $name)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SavedBike'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('selected', selected))
      ..add(DiagnosticsProperty('name', name));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SavedBike &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, selected, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SavedBikeCopyWith<_$_SavedBike> get copyWith =>
      __$$_SavedBikeCopyWithImpl<_$_SavedBike>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SavedBikeToJson(
      this,
    );
  }
}

abstract class _SavedBike extends SavedBike {
  const factory _SavedBike(
      {required final String id,
      final bool selected,
      final String? name}) = _$_SavedBike;
  const _SavedBike._() : super._();

  factory _SavedBike.fromJson(Map<String, dynamic> json) =
      _$_SavedBike.fromJson;

  @override
  String get id;
  @override
  bool get selected;
  @override
  String? get name;
  @override
  @JsonKey(ignore: true)
  _$$_SavedBikeCopyWith<_$_SavedBike> get copyWith =>
      throw _privateConstructorUsedError;
}
