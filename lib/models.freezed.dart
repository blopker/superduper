// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
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

 String get id; int get mode; bool get modeLocked; bool get light; bool get lightLocked; int get assist; bool get assistLocked; String get name; BikeRegion? get region; bool get modeLock; int get color;
/// Create a copy of BikeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BikeStateCopyWith<BikeState> get copyWith => _$BikeStateCopyWithImpl<BikeState>(this as BikeState, _$identity);

  /// Serializes this BikeState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BikeState&&(identical(other.id, id) || other.id == id)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.modeLocked, modeLocked) || other.modeLocked == modeLocked)&&(identical(other.light, light) || other.light == light)&&(identical(other.lightLocked, lightLocked) || other.lightLocked == lightLocked)&&(identical(other.assist, assist) || other.assist == assist)&&(identical(other.assistLocked, assistLocked) || other.assistLocked == assistLocked)&&(identical(other.name, name) || other.name == name)&&(identical(other.region, region) || other.region == region)&&(identical(other.modeLock, modeLock) || other.modeLock == modeLock)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mode,modeLocked,light,lightLocked,assist,assistLocked,name,region,modeLock,color);

@override
String toString() {
  return 'BikeState(id: $id, mode: $mode, modeLocked: $modeLocked, light: $light, lightLocked: $lightLocked, assist: $assist, assistLocked: $assistLocked, name: $name, region: $region, modeLock: $modeLock, color: $color)';
}


}

/// @nodoc
abstract mixin class $BikeStateCopyWith<$Res>  {
  factory $BikeStateCopyWith(BikeState value, $Res Function(BikeState) _then) = _$BikeStateCopyWithImpl;
@useResult
$Res call({
 String id, int mode, bool modeLocked, bool light, bool lightLocked, int assist, bool assistLocked, String name, BikeRegion? region, bool modeLock, int color
});




}
/// @nodoc
class _$BikeStateCopyWithImpl<$Res>
    implements $BikeStateCopyWith<$Res> {
  _$BikeStateCopyWithImpl(this._self, this._then);

  final BikeState _self;
  final $Res Function(BikeState) _then;

/// Create a copy of BikeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mode = null,Object? modeLocked = null,Object? light = null,Object? lightLocked = null,Object? assist = null,Object? assistLocked = null,Object? name = null,Object? region = freezed,Object? modeLock = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as int,modeLocked: null == modeLocked ? _self.modeLocked : modeLocked // ignore: cast_nullable_to_non_nullable
as bool,light: null == light ? _self.light : light // ignore: cast_nullable_to_non_nullable
as bool,lightLocked: null == lightLocked ? _self.lightLocked : lightLocked // ignore: cast_nullable_to_non_nullable
as bool,assist: null == assist ? _self.assist : assist // ignore: cast_nullable_to_non_nullable
as int,assistLocked: null == assistLocked ? _self.assistLocked : assistLocked // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as BikeRegion?,modeLock: null == modeLock ? _self.modeLock : modeLock // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BikeState].
extension BikeStatePatterns on BikeState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BikeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BikeState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BikeState value)  $default,){
final _that = this;
switch (_that) {
case _BikeState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BikeState value)?  $default,){
final _that = this;
switch (_that) {
case _BikeState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int mode,  bool modeLocked,  bool light,  bool lightLocked,  int assist,  bool assistLocked,  String name,  BikeRegion? region,  bool modeLock,  int color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BikeState() when $default != null:
return $default(_that.id,_that.mode,_that.modeLocked,_that.light,_that.lightLocked,_that.assist,_that.assistLocked,_that.name,_that.region,_that.modeLock,_that.color);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int mode,  bool modeLocked,  bool light,  bool lightLocked,  int assist,  bool assistLocked,  String name,  BikeRegion? region,  bool modeLock,  int color)  $default,) {final _that = this;
switch (_that) {
case _BikeState():
return $default(_that.id,_that.mode,_that.modeLocked,_that.light,_that.lightLocked,_that.assist,_that.assistLocked,_that.name,_that.region,_that.modeLock,_that.color);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int mode,  bool modeLocked,  bool light,  bool lightLocked,  int assist,  bool assistLocked,  String name,  BikeRegion? region,  bool modeLock,  int color)?  $default,) {final _that = this;
switch (_that) {
case _BikeState() when $default != null:
return $default(_that.id,_that.mode,_that.modeLocked,_that.light,_that.lightLocked,_that.assist,_that.assistLocked,_that.name,_that.region,_that.modeLock,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BikeState extends BikeState {
  const _BikeState({required this.id, required this.mode, this.modeLocked = false, required this.light, this.lightLocked = false, required this.assist, this.assistLocked = false, required this.name, this.region, this.modeLock = false, this.color = 0}): assert(mode <= 3),assert(mode >= 0),assert(assist >= 0),assert(assist <= 4),assert(color >= 0),super._();
  factory _BikeState.fromJson(Map<String, dynamic> json) => _$BikeStateFromJson(json);

@override final  String id;
@override final  int mode;
@override@JsonKey() final  bool modeLocked;
@override final  bool light;
@override@JsonKey() final  bool lightLocked;
@override final  int assist;
@override@JsonKey() final  bool assistLocked;
@override final  String name;
@override final  BikeRegion? region;
@override@JsonKey() final  bool modeLock;
@override@JsonKey() final  int color;

/// Create a copy of BikeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BikeStateCopyWith<_BikeState> get copyWith => __$BikeStateCopyWithImpl<_BikeState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BikeStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BikeState&&(identical(other.id, id) || other.id == id)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.modeLocked, modeLocked) || other.modeLocked == modeLocked)&&(identical(other.light, light) || other.light == light)&&(identical(other.lightLocked, lightLocked) || other.lightLocked == lightLocked)&&(identical(other.assist, assist) || other.assist == assist)&&(identical(other.assistLocked, assistLocked) || other.assistLocked == assistLocked)&&(identical(other.name, name) || other.name == name)&&(identical(other.region, region) || other.region == region)&&(identical(other.modeLock, modeLock) || other.modeLock == modeLock)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mode,modeLocked,light,lightLocked,assist,assistLocked,name,region,modeLock,color);

@override
String toString() {
  return 'BikeState(id: $id, mode: $mode, modeLocked: $modeLocked, light: $light, lightLocked: $lightLocked, assist: $assist, assistLocked: $assistLocked, name: $name, region: $region, modeLock: $modeLock, color: $color)';
}


}

/// @nodoc
abstract mixin class _$BikeStateCopyWith<$Res> implements $BikeStateCopyWith<$Res> {
  factory _$BikeStateCopyWith(_BikeState value, $Res Function(_BikeState) _then) = __$BikeStateCopyWithImpl;
@override @useResult
$Res call({
 String id, int mode, bool modeLocked, bool light, bool lightLocked, int assist, bool assistLocked, String name, BikeRegion? region, bool modeLock, int color
});




}
/// @nodoc
class __$BikeStateCopyWithImpl<$Res>
    implements _$BikeStateCopyWith<$Res> {
  __$BikeStateCopyWithImpl(this._self, this._then);

  final _BikeState _self;
  final $Res Function(_BikeState) _then;

/// Create a copy of BikeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mode = null,Object? modeLocked = null,Object? light = null,Object? lightLocked = null,Object? assist = null,Object? assistLocked = null,Object? name = null,Object? region = freezed,Object? modeLock = null,Object? color = null,}) {
  return _then(_BikeState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as int,modeLocked: null == modeLocked ? _self.modeLocked : modeLocked // ignore: cast_nullable_to_non_nullable
as bool,light: null == light ? _self.light : light // ignore: cast_nullable_to_non_nullable
as bool,lightLocked: null == lightLocked ? _self.lightLocked : lightLocked // ignore: cast_nullable_to_non_nullable
as bool,assist: null == assist ? _self.assist : assist // ignore: cast_nullable_to_non_nullable
as int,assistLocked: null == assistLocked ? _self.assistLocked : assistLocked // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as BikeRegion?,modeLock: null == modeLock ? _self.modeLock : modeLock // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
