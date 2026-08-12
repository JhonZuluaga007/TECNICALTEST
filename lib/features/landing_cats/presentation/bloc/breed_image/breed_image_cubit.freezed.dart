// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breed_image_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BreedImageState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreedImageState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BreedImageState()';
}


}

/// @nodoc
class $BreedImageStateCopyWith<$Res>  {
$BreedImageStateCopyWith(BreedImageState _, $Res Function(BreedImageState) __);
}


/// Adds pattern-matching-related methods to [BreedImageState].
extension BreedImageStatePatterns on BreedImageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ImageLoading value)?  loading,TResult Function( ImageReady value)?  ready,TResult Function( ImageUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ImageLoading() when loading != null:
return loading(_that);case ImageReady() when ready != null:
return ready(_that);case ImageUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ImageLoading value)  loading,required TResult Function( ImageReady value)  ready,required TResult Function( ImageUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case ImageLoading():
return loading(_that);case ImageReady():
return ready(_that);case ImageUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ImageLoading value)?  loading,TResult? Function( ImageReady value)?  ready,TResult? Function( ImageUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case ImageLoading() when loading != null:
return loading(_that);case ImageReady() when ready != null:
return ready(_that);case ImageUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( String url)?  ready,TResult Function()?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ImageLoading() when loading != null:
return loading();case ImageReady() when ready != null:
return ready(_that.url);case ImageUnavailable() when unavailable != null:
return unavailable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( String url)  ready,required TResult Function()  unavailable,}) {final _that = this;
switch (_that) {
case ImageLoading():
return loading();case ImageReady():
return ready(_that.url);case ImageUnavailable():
return unavailable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( String url)?  ready,TResult? Function()?  unavailable,}) {final _that = this;
switch (_that) {
case ImageLoading() when loading != null:
return loading();case ImageReady() when ready != null:
return ready(_that.url);case ImageUnavailable() when unavailable != null:
return unavailable();case _:
  return null;

}
}

}

/// @nodoc


class ImageLoading implements BreedImageState {
  const ImageLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BreedImageState.loading()';
}


}




/// @nodoc


class ImageReady implements BreedImageState {
  const ImageReady({required this.url});
  

 final  String url;

/// Create a copy of BreedImageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageReadyCopyWith<ImageReady> get copyWith => _$ImageReadyCopyWithImpl<ImageReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageReady&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString() {
  return 'BreedImageState.ready(url: $url)';
}


}

/// @nodoc
abstract mixin class $ImageReadyCopyWith<$Res> implements $BreedImageStateCopyWith<$Res> {
  factory $ImageReadyCopyWith(ImageReady value, $Res Function(ImageReady) _then) = _$ImageReadyCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class _$ImageReadyCopyWithImpl<$Res>
    implements $ImageReadyCopyWith<$Res> {
  _$ImageReadyCopyWithImpl(this._self, this._then);

  final ImageReady _self;
  final $Res Function(ImageReady) _then;

/// Create a copy of BreedImageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(ImageReady(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ImageUnavailable implements BreedImageState {
  const ImageUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BreedImageState.unavailable()';
}


}




// dart format on
