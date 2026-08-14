// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'landing_cats_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LandingCatsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LandingCatsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LandingCatsEvent()';
}


}

/// @nodoc
class $LandingCatsEventCopyWith<$Res>  {
$LandingCatsEventCopyWith(LandingCatsEvent _, $Res Function(LandingCatsEvent) __);
}


/// Adds pattern-matching-related methods to [LandingCatsEvent].
extension LandingCatsEventPatterns on LandingCatsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AllCatsEvent value)?  allCats,TResult Function( AddNameAlreadySearchedEvent value)?  addNameAlreadySearched,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AllCatsEvent() when allCats != null:
return allCats(_that);case AddNameAlreadySearchedEvent() when addNameAlreadySearched != null:
return addNameAlreadySearched(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AllCatsEvent value)  allCats,required TResult Function( AddNameAlreadySearchedEvent value)  addNameAlreadySearched,}){
final _that = this;
switch (_that) {
case AllCatsEvent():
return allCats(_that);case AddNameAlreadySearchedEvent():
return addNameAlreadySearched(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AllCatsEvent value)?  allCats,TResult? Function( AddNameAlreadySearchedEvent value)?  addNameAlreadySearched,}){
final _that = this;
switch (_that) {
case AllCatsEvent() when allCats != null:
return allCats(_that);case AddNameAlreadySearchedEvent() when addNameAlreadySearched != null:
return addNameAlreadySearched(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  allCats,TResult Function( String name)?  addNameAlreadySearched,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AllCatsEvent() when allCats != null:
return allCats();case AddNameAlreadySearchedEvent() when addNameAlreadySearched != null:
return addNameAlreadySearched(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  allCats,required TResult Function( String name)  addNameAlreadySearched,}) {final _that = this;
switch (_that) {
case AllCatsEvent():
return allCats();case AddNameAlreadySearchedEvent():
return addNameAlreadySearched(_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  allCats,TResult? Function( String name)?  addNameAlreadySearched,}) {final _that = this;
switch (_that) {
case AllCatsEvent() when allCats != null:
return allCats();case AddNameAlreadySearchedEvent() when addNameAlreadySearched != null:
return addNameAlreadySearched(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class AllCatsEvent implements LandingCatsEvent {
  const AllCatsEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllCatsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LandingCatsEvent.allCats()';
}


}




/// @nodoc


class AddNameAlreadySearchedEvent implements LandingCatsEvent {
  const AddNameAlreadySearchedEvent({required this.name});
  

 final  String name;

/// Create a copy of LandingCatsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddNameAlreadySearchedEventCopyWith<AddNameAlreadySearchedEvent> get copyWith => _$AddNameAlreadySearchedEventCopyWithImpl<AddNameAlreadySearchedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddNameAlreadySearchedEvent&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'LandingCatsEvent.addNameAlreadySearched(name: $name)';
}


}

/// @nodoc
abstract mixin class $AddNameAlreadySearchedEventCopyWith<$Res> implements $LandingCatsEventCopyWith<$Res> {
  factory $AddNameAlreadySearchedEventCopyWith(AddNameAlreadySearchedEvent value, $Res Function(AddNameAlreadySearchedEvent) _then) = _$AddNameAlreadySearchedEventCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$AddNameAlreadySearchedEventCopyWithImpl<$Res>
    implements $AddNameAlreadySearchedEventCopyWith<$Res> {
  _$AddNameAlreadySearchedEventCopyWithImpl(this._self, this._then);

  final AddNameAlreadySearchedEvent _self;
  final $Res Function(AddNameAlreadySearchedEvent) _then;

/// Create a copy of LandingCatsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(AddNameAlreadySearchedEvent(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LandingCatsState {

 List<String> get searchHistory;
/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LandingCatsStateCopyWith<LandingCatsState> get copyWith => _$LandingCatsStateCopyWithImpl<LandingCatsState>(this as LandingCatsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LandingCatsState&&const DeepCollectionEquality().equals(other.searchHistory, searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(searchHistory));

@override
String toString() {
  return 'LandingCatsState(searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $LandingCatsStateCopyWith<$Res>  {
  factory $LandingCatsStateCopyWith(LandingCatsState value, $Res Function(LandingCatsState) _then) = _$LandingCatsStateCopyWithImpl;
@useResult
$Res call({
 List<String> searchHistory
});




}
/// @nodoc
class _$LandingCatsStateCopyWithImpl<$Res>
    implements $LandingCatsStateCopyWith<$Res> {
  _$LandingCatsStateCopyWithImpl(this._self, this._then);

  final LandingCatsState _self;
  final $Res Function(LandingCatsState) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchHistory = null,}) {
  return _then(_self.copyWith(
searchHistory: null == searchHistory ? _self.searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LandingCatsState].
extension LandingCatsStatePatterns on LandingCatsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CatsInitial value)?  initial,TResult Function( CatsLoading value)?  loading,TResult Function( CatsLoaded value)?  loaded,TResult Function( CatsStale value)?  stale,TResult Function( CatsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CatsInitial() when initial != null:
return initial(_that);case CatsLoading() when loading != null:
return loading(_that);case CatsLoaded() when loaded != null:
return loaded(_that);case CatsStale() when stale != null:
return stale(_that);case CatsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CatsInitial value)  initial,required TResult Function( CatsLoading value)  loading,required TResult Function( CatsLoaded value)  loaded,required TResult Function( CatsStale value)  stale,required TResult Function( CatsError value)  error,}){
final _that = this;
switch (_that) {
case CatsInitial():
return initial(_that);case CatsLoading():
return loading(_that);case CatsLoaded():
return loaded(_that);case CatsStale():
return stale(_that);case CatsError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CatsInitial value)?  initial,TResult? Function( CatsLoading value)?  loading,TResult? Function( CatsLoaded value)?  loaded,TResult? Function( CatsStale value)?  stale,TResult? Function( CatsError value)?  error,}){
final _that = this;
switch (_that) {
case CatsInitial() when initial != null:
return initial(_that);case CatsLoading() when loading != null:
return loading(_that);case CatsLoaded() when loaded != null:
return loaded(_that);case CatsStale() when stale != null:
return stale(_that);case CatsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<String> searchHistory)?  initial,TResult Function( List<String> searchHistory)?  loading,TResult Function( List<CatBreedEntity> breeds,  List<String> searchHistory)?  loaded,TResult Function( List<CatBreedEntity> breeds,  CatsFailure failure,  List<String> searchHistory)?  stale,TResult Function( CatsFailure failure,  List<String> searchHistory)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CatsInitial() when initial != null:
return initial(_that.searchHistory);case CatsLoading() when loading != null:
return loading(_that.searchHistory);case CatsLoaded() when loaded != null:
return loaded(_that.breeds,_that.searchHistory);case CatsStale() when stale != null:
return stale(_that.breeds,_that.failure,_that.searchHistory);case CatsError() when error != null:
return error(_that.failure,_that.searchHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<String> searchHistory)  initial,required TResult Function( List<String> searchHistory)  loading,required TResult Function( List<CatBreedEntity> breeds,  List<String> searchHistory)  loaded,required TResult Function( List<CatBreedEntity> breeds,  CatsFailure failure,  List<String> searchHistory)  stale,required TResult Function( CatsFailure failure,  List<String> searchHistory)  error,}) {final _that = this;
switch (_that) {
case CatsInitial():
return initial(_that.searchHistory);case CatsLoading():
return loading(_that.searchHistory);case CatsLoaded():
return loaded(_that.breeds,_that.searchHistory);case CatsStale():
return stale(_that.breeds,_that.failure,_that.searchHistory);case CatsError():
return error(_that.failure,_that.searchHistory);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<String> searchHistory)?  initial,TResult? Function( List<String> searchHistory)?  loading,TResult? Function( List<CatBreedEntity> breeds,  List<String> searchHistory)?  loaded,TResult? Function( List<CatBreedEntity> breeds,  CatsFailure failure,  List<String> searchHistory)?  stale,TResult? Function( CatsFailure failure,  List<String> searchHistory)?  error,}) {final _that = this;
switch (_that) {
case CatsInitial() when initial != null:
return initial(_that.searchHistory);case CatsLoading() when loading != null:
return loading(_that.searchHistory);case CatsLoaded() when loaded != null:
return loaded(_that.breeds,_that.searchHistory);case CatsStale() when stale != null:
return stale(_that.breeds,_that.failure,_that.searchHistory);case CatsError() when error != null:
return error(_that.failure,_that.searchHistory);case _:
  return null;

}
}

}

/// @nodoc


class CatsInitial implements LandingCatsState {
  const CatsInitial({required final  List<String> searchHistory}): _searchHistory = searchHistory;
  

 final  List<String> _searchHistory;
@override List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}


/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatsInitialCopyWith<CatsInitial> get copyWith => _$CatsInitialCopyWithImpl<CatsInitial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatsInitial&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_searchHistory));

@override
String toString() {
  return 'LandingCatsState.initial(searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $CatsInitialCopyWith<$Res> implements $LandingCatsStateCopyWith<$Res> {
  factory $CatsInitialCopyWith(CatsInitial value, $Res Function(CatsInitial) _then) = _$CatsInitialCopyWithImpl;
@override @useResult
$Res call({
 List<String> searchHistory
});




}
/// @nodoc
class _$CatsInitialCopyWithImpl<$Res>
    implements $CatsInitialCopyWith<$Res> {
  _$CatsInitialCopyWithImpl(this._self, this._then);

  final CatsInitial _self;
  final $Res Function(CatsInitial) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchHistory = null,}) {
  return _then(CatsInitial(
searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CatsLoading implements LandingCatsState {
  const CatsLoading({required final  List<String> searchHistory}): _searchHistory = searchHistory;
  

 final  List<String> _searchHistory;
@override List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}


/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatsLoadingCopyWith<CatsLoading> get copyWith => _$CatsLoadingCopyWithImpl<CatsLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatsLoading&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_searchHistory));

@override
String toString() {
  return 'LandingCatsState.loading(searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $CatsLoadingCopyWith<$Res> implements $LandingCatsStateCopyWith<$Res> {
  factory $CatsLoadingCopyWith(CatsLoading value, $Res Function(CatsLoading) _then) = _$CatsLoadingCopyWithImpl;
@override @useResult
$Res call({
 List<String> searchHistory
});




}
/// @nodoc
class _$CatsLoadingCopyWithImpl<$Res>
    implements $CatsLoadingCopyWith<$Res> {
  _$CatsLoadingCopyWithImpl(this._self, this._then);

  final CatsLoading _self;
  final $Res Function(CatsLoading) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchHistory = null,}) {
  return _then(CatsLoading(
searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CatsLoaded implements LandingCatsState {
  const CatsLoaded({required final  List<CatBreedEntity> breeds, required final  List<String> searchHistory}): _breeds = breeds,_searchHistory = searchHistory;
  

 final  List<CatBreedEntity> _breeds;
 List<CatBreedEntity> get breeds {
  if (_breeds is EqualUnmodifiableListView) return _breeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breeds);
}

 final  List<String> _searchHistory;
@override List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}


/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatsLoadedCopyWith<CatsLoaded> get copyWith => _$CatsLoadedCopyWithImpl<CatsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatsLoaded&&const DeepCollectionEquality().equals(other._breeds, _breeds)&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_breeds),const DeepCollectionEquality().hash(_searchHistory));

@override
String toString() {
  return 'LandingCatsState.loaded(breeds: $breeds, searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $CatsLoadedCopyWith<$Res> implements $LandingCatsStateCopyWith<$Res> {
  factory $CatsLoadedCopyWith(CatsLoaded value, $Res Function(CatsLoaded) _then) = _$CatsLoadedCopyWithImpl;
@override @useResult
$Res call({
 List<CatBreedEntity> breeds, List<String> searchHistory
});




}
/// @nodoc
class _$CatsLoadedCopyWithImpl<$Res>
    implements $CatsLoadedCopyWith<$Res> {
  _$CatsLoadedCopyWithImpl(this._self, this._then);

  final CatsLoaded _self;
  final $Res Function(CatsLoaded) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breeds = null,Object? searchHistory = null,}) {
  return _then(CatsLoaded(
breeds: null == breeds ? _self._breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<CatBreedEntity>,searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CatsStale implements LandingCatsState {
  const CatsStale({required final  List<CatBreedEntity> breeds, required this.failure, required final  List<String> searchHistory}): _breeds = breeds,_searchHistory = searchHistory;
  

 final  List<CatBreedEntity> _breeds;
 List<CatBreedEntity> get breeds {
  if (_breeds is EqualUnmodifiableListView) return _breeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breeds);
}

 final  CatsFailure failure;
 final  List<String> _searchHistory;
@override List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}


/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatsStaleCopyWith<CatsStale> get copyWith => _$CatsStaleCopyWithImpl<CatsStale>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatsStale&&const DeepCollectionEquality().equals(other._breeds, _breeds)&&(identical(other.failure, failure) || other.failure == failure)&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_breeds),failure,const DeepCollectionEquality().hash(_searchHistory));

@override
String toString() {
  return 'LandingCatsState.stale(breeds: $breeds, failure: $failure, searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $CatsStaleCopyWith<$Res> implements $LandingCatsStateCopyWith<$Res> {
  factory $CatsStaleCopyWith(CatsStale value, $Res Function(CatsStale) _then) = _$CatsStaleCopyWithImpl;
@override @useResult
$Res call({
 List<CatBreedEntity> breeds, CatsFailure failure, List<String> searchHistory
});


$CatsFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CatsStaleCopyWithImpl<$Res>
    implements $CatsStaleCopyWith<$Res> {
  _$CatsStaleCopyWithImpl(this._self, this._then);

  final CatsStale _self;
  final $Res Function(CatsStale) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breeds = null,Object? failure = null,Object? searchHistory = null,}) {
  return _then(CatsStale(
breeds: null == breeds ? _self._breeds : breeds // ignore: cast_nullable_to_non_nullable
as List<CatBreedEntity>,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CatsFailure,searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatsFailureCopyWith<$Res> get failure {
  
  return $CatsFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class CatsError implements LandingCatsState {
  const CatsError({required this.failure, required final  List<String> searchHistory}): _searchHistory = searchHistory;
  

 final  CatsFailure failure;
 final  List<String> _searchHistory;
@override List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}


/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatsErrorCopyWith<CatsError> get copyWith => _$CatsErrorCopyWithImpl<CatsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatsError&&(identical(other.failure, failure) || other.failure == failure)&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory));
}


@override
int get hashCode => Object.hash(runtimeType,failure,const DeepCollectionEquality().hash(_searchHistory));

@override
String toString() {
  return 'LandingCatsState.error(failure: $failure, searchHistory: $searchHistory)';
}


}

/// @nodoc
abstract mixin class $CatsErrorCopyWith<$Res> implements $LandingCatsStateCopyWith<$Res> {
  factory $CatsErrorCopyWith(CatsError value, $Res Function(CatsError) _then) = _$CatsErrorCopyWithImpl;
@override @useResult
$Res call({
 CatsFailure failure, List<String> searchHistory
});


$CatsFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CatsErrorCopyWithImpl<$Res>
    implements $CatsErrorCopyWith<$Res> {
  _$CatsErrorCopyWithImpl(this._self, this._then);

  final CatsError _self;
  final $Res Function(CatsError) _then;

/// Create a copy of LandingCatsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? searchHistory = null,}) {
  return _then(CatsError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CatsFailure,searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of LandingCatsState
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
