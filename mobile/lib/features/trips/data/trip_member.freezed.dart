// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripMember {

 User get user; MemberRole get role; DateTime get joinedAt;
/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMemberCopyWith<TripMember> get copyWith => _$TripMemberCopyWithImpl<TripMember>(this as TripMember, _$identity);

  /// Serializes this TripMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMember&&(identical(other.user, user) || other.user == user)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,role,joinedAt);

@override
String toString() {
  return 'TripMember(user: $user, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $TripMemberCopyWith<$Res>  {
  factory $TripMemberCopyWith(TripMember value, $Res Function(TripMember) _then) = _$TripMemberCopyWithImpl;
@useResult
$Res call({
 User user, MemberRole role, DateTime joinedAt
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$TripMemberCopyWithImpl<$Res>
    implements $TripMemberCopyWith<$Res> {
  _$TripMemberCopyWithImpl(this._self, this._then);

  final TripMember _self;
  final $Res Function(TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripMember].
extension TripMemberPatterns on TripMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMember value)  $default,){
final _that = this;
switch (_that) {
case _TripMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMember value)?  $default,){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( User user,  MemberRole role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.user,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( User user,  MemberRole role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _TripMember():
return $default(_that.user,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( User user,  MemberRole role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.user,_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMember implements TripMember {
  const _TripMember({required this.user, required this.role, required this.joinedAt});
  factory _TripMember.fromJson(Map<String, dynamic> json) => _$TripMemberFromJson(json);

@override final  User user;
@override final  MemberRole role;
@override final  DateTime joinedAt;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMemberCopyWith<_TripMember> get copyWith => __$TripMemberCopyWithImpl<_TripMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMember&&(identical(other.user, user) || other.user == user)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,role,joinedAt);

@override
String toString() {
  return 'TripMember(user: $user, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$TripMemberCopyWith<$Res> implements $TripMemberCopyWith<$Res> {
  factory _$TripMemberCopyWith(_TripMember value, $Res Function(_TripMember) _then) = __$TripMemberCopyWithImpl;
@override @useResult
$Res call({
 User user, MemberRole role, DateTime joinedAt
});


@override $UserCopyWith<$Res> get user;

}
/// @nodoc
class __$TripMemberCopyWithImpl<$Res>
    implements _$TripMemberCopyWith<$Res> {
  __$TripMemberCopyWithImpl(this._self, this._then);

  final _TripMember _self;
  final $Res Function(_TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_TripMember(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
