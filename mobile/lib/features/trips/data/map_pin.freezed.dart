// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_pin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapPin {

 String get id; String get tripId; String get name; String? get description; double get latitude; double get longitude; PinCategory get category; String get createdBy; DateTime get createdAt;
/// Create a copy of MapPin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPinCopyWith<MapPin> get copyWith => _$MapPinCopyWithImpl<MapPin>(this as MapPin, _$identity);

  /// Serializes this MapPin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPin&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,description,latitude,longitude,category,createdBy,createdAt);

@override
String toString() {
  return 'MapPin(id: $id, tripId: $tripId, name: $name, description: $description, latitude: $latitude, longitude: $longitude, category: $category, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MapPinCopyWith<$Res>  {
  factory $MapPinCopyWith(MapPin value, $Res Function(MapPin) _then) = _$MapPinCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String name, String? description, double latitude, double longitude, PinCategory category, String createdBy, DateTime createdAt
});




}
/// @nodoc
class _$MapPinCopyWithImpl<$Res>
    implements $MapPinCopyWith<$Res> {
  _$MapPinCopyWithImpl(this._self, this._then);

  final MapPin _self;
  final $Res Function(MapPin) _then;

/// Create a copy of MapPin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? description = freezed,Object? latitude = null,Object? longitude = null,Object? category = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PinCategory,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MapPin].
extension MapPinPatterns on MapPin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPin value)  $default,){
final _that = this;
switch (_that) {
case _MapPin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPin value)?  $default,){
final _that = this;
switch (_that) {
case _MapPin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String? description,  double latitude,  double longitude,  PinCategory category,  String createdBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPin() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.description,_that.latitude,_that.longitude,_that.category,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String? description,  double latitude,  double longitude,  PinCategory category,  String createdBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MapPin():
return $default(_that.id,_that.tripId,_that.name,_that.description,_that.latitude,_that.longitude,_that.category,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String name,  String? description,  double latitude,  double longitude,  PinCategory category,  String createdBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MapPin() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.description,_that.latitude,_that.longitude,_that.category,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MapPin extends MapPin {
  const _MapPin({required this.id, required this.tripId, required this.name, this.description, required this.latitude, required this.longitude, required this.category, required this.createdBy, required this.createdAt}): super._();
  factory _MapPin.fromJson(Map<String, dynamic> json) => _$MapPinFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String name;
@override final  String? description;
@override final  double latitude;
@override final  double longitude;
@override final  PinCategory category;
@override final  String createdBy;
@override final  DateTime createdAt;

/// Create a copy of MapPin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPinCopyWith<_MapPin> get copyWith => __$MapPinCopyWithImpl<_MapPin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapPinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPin&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,description,latitude,longitude,category,createdBy,createdAt);

@override
String toString() {
  return 'MapPin(id: $id, tripId: $tripId, name: $name, description: $description, latitude: $latitude, longitude: $longitude, category: $category, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MapPinCopyWith<$Res> implements $MapPinCopyWith<$Res> {
  factory _$MapPinCopyWith(_MapPin value, $Res Function(_MapPin) _then) = __$MapPinCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String name, String? description, double latitude, double longitude, PinCategory category, String createdBy, DateTime createdAt
});




}
/// @nodoc
class __$MapPinCopyWithImpl<$Res>
    implements _$MapPinCopyWith<$Res> {
  __$MapPinCopyWithImpl(this._self, this._then);

  final _MapPin _self;
  final $Res Function(_MapPin) _then;

/// Create a copy of MapPin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? description = freezed,Object? latitude = null,Object? longitude = null,Object? category = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_MapPin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PinCategory,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MemberLocation {

 String get userId; double get latitude; double get longitude; double? get accuracyM; DateTime get updatedAt; DateTime get expiresAt;
/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberLocationCopyWith<MemberLocation> get copyWith => _$MemberLocationCopyWithImpl<MemberLocation>(this as MemberLocation, _$identity);

  /// Serializes this MemberLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberLocation&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,latitude,longitude,accuracyM,updatedAt,expiresAt);

@override
String toString() {
  return 'MemberLocation(userId: $userId, latitude: $latitude, longitude: $longitude, accuracyM: $accuracyM, updatedAt: $updatedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $MemberLocationCopyWith<$Res>  {
  factory $MemberLocationCopyWith(MemberLocation value, $Res Function(MemberLocation) _then) = _$MemberLocationCopyWithImpl;
@useResult
$Res call({
 String userId, double latitude, double longitude, double? accuracyM, DateTime updatedAt, DateTime expiresAt
});




}
/// @nodoc
class _$MemberLocationCopyWithImpl<$Res>
    implements $MemberLocationCopyWith<$Res> {
  _$MemberLocationCopyWithImpl(this._self, this._then);

  final MemberLocation _self;
  final $Res Function(MemberLocation) _then;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? latitude = null,Object? longitude = null,Object? accuracyM = freezed,Object? updatedAt = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberLocation].
extension MemberLocationPatterns on MemberLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberLocation value)  $default,){
final _that = this;
switch (_that) {
case _MemberLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberLocation value)?  $default,){
final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  double latitude,  double longitude,  double? accuracyM,  DateTime updatedAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
return $default(_that.userId,_that.latitude,_that.longitude,_that.accuracyM,_that.updatedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  double latitude,  double longitude,  double? accuracyM,  DateTime updatedAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _MemberLocation():
return $default(_that.userId,_that.latitude,_that.longitude,_that.accuracyM,_that.updatedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  double latitude,  double longitude,  double? accuracyM,  DateTime updatedAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _MemberLocation() when $default != null:
return $default(_that.userId,_that.latitude,_that.longitude,_that.accuracyM,_that.updatedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberLocation extends MemberLocation {
  const _MemberLocation({required this.userId, required this.latitude, required this.longitude, this.accuracyM, required this.updatedAt, required this.expiresAt}): super._();
  factory _MemberLocation.fromJson(Map<String, dynamic> json) => _$MemberLocationFromJson(json);

@override final  String userId;
@override final  double latitude;
@override final  double longitude;
@override final  double? accuracyM;
@override final  DateTime updatedAt;
@override final  DateTime expiresAt;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberLocationCopyWith<_MemberLocation> get copyWith => __$MemberLocationCopyWithImpl<_MemberLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberLocation&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,latitude,longitude,accuracyM,updatedAt,expiresAt);

@override
String toString() {
  return 'MemberLocation(userId: $userId, latitude: $latitude, longitude: $longitude, accuracyM: $accuracyM, updatedAt: $updatedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$MemberLocationCopyWith<$Res> implements $MemberLocationCopyWith<$Res> {
  factory _$MemberLocationCopyWith(_MemberLocation value, $Res Function(_MemberLocation) _then) = __$MemberLocationCopyWithImpl;
@override @useResult
$Res call({
 String userId, double latitude, double longitude, double? accuracyM, DateTime updatedAt, DateTime expiresAt
});




}
/// @nodoc
class __$MemberLocationCopyWithImpl<$Res>
    implements _$MemberLocationCopyWith<$Res> {
  __$MemberLocationCopyWithImpl(this._self, this._then);

  final _MemberLocation _self;
  final $Res Function(_MemberLocation) _then;

/// Create a copy of MemberLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? latitude = null,Object? longitude = null,Object? accuracyM = freezed,Object? updatedAt = null,Object? expiresAt = null,}) {
  return _then(_MemberLocation(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
