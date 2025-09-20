// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'db.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsModel implements DiagnosticableTreeMixin {

 String? get currentBike;
/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsModelCopyWith<SettingsModel> get copyWith => _$SettingsModelCopyWithImpl<SettingsModel>(this as SettingsModel, _$identity);

  /// Serializes this SettingsModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SettingsModel'))
    ..add(DiagnosticsProperty('currentBike', currentBike));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsModel&&(identical(other.currentBike, currentBike) || other.currentBike == currentBike));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentBike);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SettingsModel(currentBike: $currentBike)';
}


}

/// @nodoc
abstract mixin class $SettingsModelCopyWith<$Res>  {
  factory $SettingsModelCopyWith(SettingsModel value, $Res Function(SettingsModel) _then) = _$SettingsModelCopyWithImpl;
@useResult
$Res call({
 String? currentBike
});




}
/// @nodoc
class _$SettingsModelCopyWithImpl<$Res>
    implements $SettingsModelCopyWith<$Res> {
  _$SettingsModelCopyWithImpl(this._self, this._then);

  final SettingsModel _self;
  final $Res Function(SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentBike = freezed,}) {
  return _then(_self.copyWith(
currentBike: freezed == currentBike ? _self.currentBike : currentBike // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsModel].
extension SettingsModelPatterns on SettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _SettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? currentBike)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.currentBike);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? currentBike)  $default,) {final _that = this;
switch (_that) {
case _SettingsModel():
return $default(_that.currentBike);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? currentBike)?  $default,) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.currentBike);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsModel with DiagnosticableTreeMixin implements SettingsModel {
  const _SettingsModel({this.currentBike});
  factory _SettingsModel.fromJson(Map<String, dynamic> json) => _$SettingsModelFromJson(json);

@override final  String? currentBike;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsModelCopyWith<_SettingsModel> get copyWith => __$SettingsModelCopyWithImpl<_SettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SettingsModel'))
    ..add(DiagnosticsProperty('currentBike', currentBike));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsModel&&(identical(other.currentBike, currentBike) || other.currentBike == currentBike));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentBike);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SettingsModel(currentBike: $currentBike)';
}


}

/// @nodoc
abstract mixin class _$SettingsModelCopyWith<$Res> implements $SettingsModelCopyWith<$Res> {
  factory _$SettingsModelCopyWith(_SettingsModel value, $Res Function(_SettingsModel) _then) = __$SettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String? currentBike
});




}
/// @nodoc
class __$SettingsModelCopyWithImpl<$Res>
    implements _$SettingsModelCopyWith<$Res> {
  __$SettingsModelCopyWithImpl(this._self, this._then);

  final _SettingsModel _self;
  final $Res Function(_SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentBike = freezed,}) {
  return _then(_SettingsModel(
currentBike: freezed == currentBike ? _self.currentBike : currentBike // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
