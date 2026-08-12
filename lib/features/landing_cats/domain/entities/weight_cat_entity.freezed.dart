// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weight_cat_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeightEntity {

 String get imperial; String get metric;
/// Create a copy of WeightEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightEntityCopyWith<WeightEntity> get copyWith => _$WeightEntityCopyWithImpl<WeightEntity>(this as WeightEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightEntity&&(identical(other.imperial, imperial) || other.imperial == imperial)&&(identical(other.metric, metric) || other.metric == metric));
}


@override
int get hashCode => Object.hash(runtimeType,imperial,metric);

@override
String toString() {
  return 'WeightEntity(imperial: $imperial, metric: $metric)';
}


}

/// @nodoc
abstract mixin class $WeightEntityCopyWith<$Res>  {
  factory $WeightEntityCopyWith(WeightEntity value, $Res Function(WeightEntity) _then) = _$WeightEntityCopyWithImpl;
@useResult
$Res call({
 String imperial, String metric
});




}
/// @nodoc
class _$WeightEntityCopyWithImpl<$Res>
    implements $WeightEntityCopyWith<$Res> {
  _$WeightEntityCopyWithImpl(this._self, this._then);

  final WeightEntity _self;
  final $Res Function(WeightEntity) _then;

/// Create a copy of WeightEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? imperial = null,Object? metric = null,}) {
  return _then(_self.copyWith(
imperial: null == imperial ? _self.imperial : imperial // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WeightEntity].
extension WeightEntityPatterns on WeightEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeightEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeightEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeightEntity value)  $default,){
final _that = this;
switch (_that) {
case _WeightEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeightEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WeightEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String imperial,  String metric)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeightEntity() when $default != null:
return $default(_that.imperial,_that.metric);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String imperial,  String metric)  $default,) {final _that = this;
switch (_that) {
case _WeightEntity():
return $default(_that.imperial,_that.metric);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String imperial,  String metric)?  $default,) {final _that = this;
switch (_that) {
case _WeightEntity() when $default != null:
return $default(_that.imperial,_that.metric);case _:
  return null;

}
}

}

/// @nodoc


class _WeightEntity implements WeightEntity {
  const _WeightEntity({required this.imperial, required this.metric});
  

@override final  String imperial;
@override final  String metric;

/// Create a copy of WeightEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeightEntityCopyWith<_WeightEntity> get copyWith => __$WeightEntityCopyWithImpl<_WeightEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeightEntity&&(identical(other.imperial, imperial) || other.imperial == imperial)&&(identical(other.metric, metric) || other.metric == metric));
}


@override
int get hashCode => Object.hash(runtimeType,imperial,metric);

@override
String toString() {
  return 'WeightEntity(imperial: $imperial, metric: $metric)';
}


}

/// @nodoc
abstract mixin class _$WeightEntityCopyWith<$Res> implements $WeightEntityCopyWith<$Res> {
  factory _$WeightEntityCopyWith(_WeightEntity value, $Res Function(_WeightEntity) _then) = __$WeightEntityCopyWithImpl;
@override @useResult
$Res call({
 String imperial, String metric
});




}
/// @nodoc
class __$WeightEntityCopyWithImpl<$Res>
    implements _$WeightEntityCopyWith<$Res> {
  __$WeightEntityCopyWithImpl(this._self, this._then);

  final _WeightEntity _self;
  final $Res Function(_WeightEntity) _then;

/// Create a copy of WeightEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? imperial = null,Object? metric = null,}) {
  return _then(_WeightEntity(
imperial: null == imperial ? _self.imperial : imperial // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
