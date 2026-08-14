// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breeds_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BreedsSnapshot {

 List<CatBreedEntity> get breeds;
/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedsSnapshotCopyWith<BreedsSnapshot> get copyWith => _$BreedsSnapshotCopyWithImpl<BreedsSnapshot>(this as BreedsSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedsSnapshot&&const DeepCollectionEquality().equals(other.breeds, breeds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(breeds));

@override
String toString() {
  return 'BreedsSnapshot(breeds: $breeds)';
}


}

/// @nodoc
abstract mixin class $BreedsSnapshotCopyWith<$Res>  {
  factory $BreedsSnapshotCopyWith(BreedsSnapshot value, $Res Function(BreedsSnapshot) _then) = _$BreedsSnapshotCopyWithImpl;
@useResult
$Res call({
 List<CatBreedEntity> breeds
});




}
/// @nodoc
class _$BreedsSnapshotCopyWithImpl<$Res>
    implements $BreedsSnapshotCopyWith<$Res> {
  _$BreedsSnapshotCopyWithImpl(this._self, this._then);

  final BreedsSnapshot _self;
  final $Res Function(BreedsSnapshot) _then;

/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? breeds = null,}) {
  return _then(_self.copyWith(
breeds: null == breeds ? _self.breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<CatBreedEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [BreedsSnapshot].
extension BreedsSnapshotPatterns on BreedsSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FreshBreeds value)?  fresh,TResult Function( StaleBreeds value)?  stale,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FreshBreeds() when fresh != null:
return fresh(_that);case StaleBreeds() when stale != null:
return stale(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FreshBreeds value)  fresh,required TResult Function( StaleBreeds value)  stale,}){
final _that = this;
switch (_that) {
case FreshBreeds():
return fresh(_that);case StaleBreeds():
return stale(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FreshBreeds value)?  fresh,TResult? Function( StaleBreeds value)?  stale,}){
final _that = this;
switch (_that) {
case FreshBreeds() when fresh != null:
return fresh(_that);case StaleBreeds() when stale != null:
return stale(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<CatBreedEntity> breeds)?  fresh,TResult Function( List<CatBreedEntity> breeds,  CatsFailure failure)?  stale,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FreshBreeds() when fresh != null:
return fresh(_that.breeds);case StaleBreeds() when stale != null:
return stale(_that.breeds,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<CatBreedEntity> breeds)  fresh,required TResult Function( List<CatBreedEntity> breeds,  CatsFailure failure)  stale,}) {final _that = this;
switch (_that) {
case FreshBreeds():
return fresh(_that.breeds);case StaleBreeds():
return stale(_that.breeds,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<CatBreedEntity> breeds)?  fresh,TResult? Function( List<CatBreedEntity> breeds,  CatsFailure failure)?  stale,}) {final _that = this;
switch (_that) {
case FreshBreeds() when fresh != null:
return fresh(_that.breeds);case StaleBreeds() when stale != null:
return stale(_that.breeds,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class FreshBreeds implements BreedsSnapshot {
  const FreshBreeds({required final  List<CatBreedEntity> breeds}): _breeds = breeds;
  

 final  List<CatBreedEntity> _breeds;
@override List<CatBreedEntity> get breeds {
  if (_breeds is EqualUnmodifiableListView) return _breeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breeds);
}


/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreshBreedsCopyWith<FreshBreeds> get copyWith => _$FreshBreedsCopyWithImpl<FreshBreeds>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreshBreeds&&const DeepCollectionEquality().equals(other._breeds, _breeds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_breeds));

@override
String toString() {
  return 'BreedsSnapshot.fresh(breeds: $breeds)';
}


}

/// @nodoc
abstract mixin class $FreshBreedsCopyWith<$Res> implements $BreedsSnapshotCopyWith<$Res> {
  factory $FreshBreedsCopyWith(FreshBreeds value, $Res Function(FreshBreeds) _then) = _$FreshBreedsCopyWithImpl;
@override @useResult
$Res call({
 List<CatBreedEntity> breeds
});




}
/// @nodoc
class _$FreshBreedsCopyWithImpl<$Res>
    implements $FreshBreedsCopyWith<$Res> {
  _$FreshBreedsCopyWithImpl(this._self, this._then);

  final FreshBreeds _self;
  final $Res Function(FreshBreeds) _then;

/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breeds = null,}) {
  return _then(FreshBreeds(
breeds: null == breeds ? _self._breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<CatBreedEntity>,
  ));
}


}

/// @nodoc


class StaleBreeds implements BreedsSnapshot {
  const StaleBreeds({required final  List<CatBreedEntity> breeds, required this.failure}): _breeds = breeds;
  

 final  List<CatBreedEntity> _breeds;
@override List<CatBreedEntity> get breeds {
  if (_breeds is EqualUnmodifiableListView) return _breeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breeds);
}

 final  CatsFailure failure;

/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaleBreedsCopyWith<StaleBreeds> get copyWith => _$StaleBreedsCopyWithImpl<StaleBreeds>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaleBreeds&&const DeepCollectionEquality().equals(other._breeds, _breeds)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_breeds),failure);

@override
String toString() {
  return 'BreedsSnapshot.stale(breeds: $breeds, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StaleBreedsCopyWith<$Res> implements $BreedsSnapshotCopyWith<$Res> {
  factory $StaleBreedsCopyWith(StaleBreeds value, $Res Function(StaleBreeds) _then) = _$StaleBreedsCopyWithImpl;
@override @useResult
$Res call({
 List<CatBreedEntity> breeds, CatsFailure failure
});


$CatsFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StaleBreedsCopyWithImpl<$Res>
    implements $StaleBreedsCopyWith<$Res> {
  _$StaleBreedsCopyWithImpl(this._self, this._then);

  final StaleBreeds _self;
  final $Res Function(StaleBreeds) _then;

/// Create a copy of BreedsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breeds = null,Object? failure = null,}) {
  return _then(StaleBreeds(
breeds: null == breeds ? _self._breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<CatBreedEntity>,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CatsFailure,
  ));
}

/// Create a copy of BreedsSnapshot
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
