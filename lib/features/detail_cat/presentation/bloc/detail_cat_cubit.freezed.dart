// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detail_cat_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DetailCatState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailCatState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DetailCatState()';
}


}

/// @nodoc
class $DetailCatStateCopyWith<$Res>  {
$DetailCatStateCopyWith(DetailCatState _, $Res Function(DetailCatState) __);
}


/// Adds pattern-matching-related methods to [DetailCatState].
extension DetailCatStatePatterns on DetailCatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DetailLoading value)?  loading,TResult Function( DetailReady value)?  ready,TResult Function( DetailFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading(_that);case DetailReady() when ready != null:
return ready(_that);case DetailFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DetailLoading value)  loading,required TResult Function( DetailReady value)  ready,required TResult Function( DetailFailed value)  failed,}){
final _that = this;
switch (_that) {
case DetailLoading():
return loading(_that);case DetailReady():
return ready(_that);case DetailFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DetailLoading value)?  loading,TResult? Function( DetailReady value)?  ready,TResult? Function( DetailFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading(_that);case DetailReady() when ready != null:
return ready(_that);case DetailFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( CatBreedEntity breed)?  ready,TResult Function( CatsFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading();case DetailReady() when ready != null:
return ready(_that.breed);case DetailFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( CatBreedEntity breed)  ready,required TResult Function( CatsFailure failure)  failed,}) {final _that = this;
switch (_that) {
case DetailLoading():
return loading();case DetailReady():
return ready(_that.breed);case DetailFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( CatBreedEntity breed)?  ready,TResult? Function( CatsFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading();case DetailReady() when ready != null:
return ready(_that.breed);case DetailFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DetailLoading implements DetailCatState {
  const DetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DetailCatState.loading()';
}


}




/// @nodoc


class DetailReady implements DetailCatState {
  const DetailReady({required this.breed});
  

 final  CatBreedEntity breed;

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailReadyCopyWith<DetailReady> get copyWith => _$DetailReadyCopyWithImpl<DetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailReady&&(identical(other.breed, breed) || other.breed == breed));
}


@override
int get hashCode => Object.hash(runtimeType,breed);

@override
String toString() {
  return 'DetailCatState.ready(breed: $breed)';
}


}

/// @nodoc
abstract mixin class $DetailReadyCopyWith<$Res> implements $DetailCatStateCopyWith<$Res> {
  factory $DetailReadyCopyWith(DetailReady value, $Res Function(DetailReady) _then) = _$DetailReadyCopyWithImpl;
@useResult
$Res call({
 CatBreedEntity breed
});


$CatBreedEntityCopyWith<$Res> get breed;

}
/// @nodoc
class _$DetailReadyCopyWithImpl<$Res>
    implements $DetailReadyCopyWith<$Res> {
  _$DetailReadyCopyWithImpl(this._self, this._then);

  final DetailReady _self;
  final $Res Function(DetailReady) _then;

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? breed = null,}) {
  return _then(DetailReady(
breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as CatBreedEntity,
  ));
}

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatBreedEntityCopyWith<$Res> get breed {
  
  return $CatBreedEntityCopyWith<$Res>(_self.breed, (value) {
    return _then(_self.copyWith(breed: value));
  });
}
}

/// @nodoc


class DetailFailed implements DetailCatState {
  const DetailFailed({required this.failure});
  

 final  CatsFailure failure;

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailFailedCopyWith<DetailFailed> get copyWith => _$DetailFailedCopyWithImpl<DetailFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DetailCatState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DetailFailedCopyWith<$Res> implements $DetailCatStateCopyWith<$Res> {
  factory $DetailFailedCopyWith(DetailFailed value, $Res Function(DetailFailed) _then) = _$DetailFailedCopyWithImpl;
@useResult
$Res call({
 CatsFailure failure
});


$CatsFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DetailFailedCopyWithImpl<$Res>
    implements $DetailFailedCopyWith<$Res> {
  _$DetailFailedCopyWithImpl(this._self, this._then);

  final DetailFailed _self;
  final $Res Function(DetailFailed) _then;

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DetailFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CatsFailure,
  ));
}

/// Create a copy of DetailCatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatsFailureCopyWith<$Res> get failure {
  
  return $CatsFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
