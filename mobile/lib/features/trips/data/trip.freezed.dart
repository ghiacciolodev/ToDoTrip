// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberPreview {

 String get id; String get displayName;
/// Create a copy of MemberPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberPreviewCopyWith<MemberPreview> get copyWith => _$MemberPreviewCopyWithImpl<MemberPreview>(this as MemberPreview, _$identity);

  /// Serializes this MemberPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'MemberPreview(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $MemberPreviewCopyWith<$Res>  {
  factory $MemberPreviewCopyWith(MemberPreview value, $Res Function(MemberPreview) _then) = _$MemberPreviewCopyWithImpl;
@useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class _$MemberPreviewCopyWithImpl<$Res>
    implements $MemberPreviewCopyWith<$Res> {
  _$MemberPreviewCopyWithImpl(this._self, this._then);

  final MemberPreview _self;
  final $Res Function(MemberPreview) _then;

/// Create a copy of MemberPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberPreview].
extension MemberPreviewPatterns on MemberPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberPreview value)  $default,){
final _that = this;
switch (_that) {
case _MemberPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberPreview value)?  $default,){
final _that = this;
switch (_that) {
case _MemberPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberPreview() when $default != null:
return $default(_that.id,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _MemberPreview():
return $default(_that.id,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _MemberPreview() when $default != null:
return $default(_that.id,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberPreview implements MemberPreview {
  const _MemberPreview({required this.id, required this.displayName});
  factory _MemberPreview.fromJson(Map<String, dynamic> json) => _$MemberPreviewFromJson(json);

@override final  String id;
@override final  String displayName;

/// Create a copy of MemberPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberPreviewCopyWith<_MemberPreview> get copyWith => __$MemberPreviewCopyWithImpl<_MemberPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'MemberPreview(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$MemberPreviewCopyWith<$Res> implements $MemberPreviewCopyWith<$Res> {
  factory _$MemberPreviewCopyWith(_MemberPreview value, $Res Function(_MemberPreview) _then) = __$MemberPreviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class __$MemberPreviewCopyWithImpl<$Res>
    implements _$MemberPreviewCopyWith<$Res> {
  __$MemberPreviewCopyWithImpl(this._self, this._then);

  final _MemberPreview _self;
  final $Res Function(_MemberPreview) _then;

/// Create a copy of MemberPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_MemberPreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Trip {

 String get id; String get name; String? get description; DateTime? get startDate; DateTime? get endDate; String get baseCurrency; String? get icon; String? get color; DateTime? get archivedAt; String get createdBy; DateTime get createdAt; int get memberCount; List<MemberPreview> get memberPreview; int? get myBalanceCents; DateTime? get lastActivityAt; int get expenseCount; int get itemCount; int get totalSpentCents; String? get createdByName;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other.memberPreview, memberPreview)&&(identical(other.myBalanceCents, myBalanceCents) || other.myBalanceCents == myBalanceCents)&&(identical(other.lastActivityAt, lastActivityAt) || other.lastActivityAt == lastActivityAt)&&(identical(other.expenseCount, expenseCount) || other.expenseCount == expenseCount)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.totalSpentCents, totalSpentCents) || other.totalSpentCents == totalSpentCents)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,description,startDate,endDate,baseCurrency,icon,color,archivedAt,createdBy,createdAt,memberCount,const DeepCollectionEquality().hash(memberPreview),myBalanceCents,lastActivityAt,expenseCount,itemCount,totalSpentCents,createdByName]);

@override
String toString() {
  return 'Trip(id: $id, name: $name, description: $description, startDate: $startDate, endDate: $endDate, baseCurrency: $baseCurrency, icon: $icon, color: $color, archivedAt: $archivedAt, createdBy: $createdBy, createdAt: $createdAt, memberCount: $memberCount, memberPreview: $memberPreview, myBalanceCents: $myBalanceCents, lastActivityAt: $lastActivityAt, expenseCount: $expenseCount, itemCount: $itemCount, totalSpentCents: $totalSpentCents, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, DateTime? startDate, DateTime? endDate, String baseCurrency, String? icon, String? color, DateTime? archivedAt, String createdBy, DateTime createdAt, int memberCount, List<MemberPreview> memberPreview, int? myBalanceCents, DateTime? lastActivityAt, int expenseCount, int itemCount, int totalSpentCents, String? createdByName
});




}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? baseCurrency = null,Object? icon = freezed,Object? color = freezed,Object? archivedAt = freezed,Object? createdBy = null,Object? createdAt = null,Object? memberCount = null,Object? memberPreview = null,Object? myBalanceCents = freezed,Object? lastActivityAt = freezed,Object? expenseCount = null,Object? itemCount = null,Object? totalSpentCents = null,Object? createdByName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberPreview: null == memberPreview ? _self.memberPreview : memberPreview // ignore: cast_nullable_to_non_nullable
as List<MemberPreview>,myBalanceCents: freezed == myBalanceCents ? _self.myBalanceCents : myBalanceCents // ignore: cast_nullable_to_non_nullable
as int?,lastActivityAt: freezed == lastActivityAt ? _self.lastActivityAt : lastActivityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expenseCount: null == expenseCount ? _self.expenseCount : expenseCount // ignore: cast_nullable_to_non_nullable
as int,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentCents: null == totalSpentCents ? _self.totalSpentCents : totalSpentCents // ignore: cast_nullable_to_non_nullable
as int,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  DateTime? startDate,  DateTime? endDate,  String baseCurrency,  String? icon,  String? color,  DateTime? archivedAt,  String createdBy,  DateTime createdAt,  int memberCount,  List<MemberPreview> memberPreview,  int? myBalanceCents,  DateTime? lastActivityAt,  int expenseCount,  int itemCount,  int totalSpentCents,  String? createdByName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.startDate,_that.endDate,_that.baseCurrency,_that.icon,_that.color,_that.archivedAt,_that.createdBy,_that.createdAt,_that.memberCount,_that.memberPreview,_that.myBalanceCents,_that.lastActivityAt,_that.expenseCount,_that.itemCount,_that.totalSpentCents,_that.createdByName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  DateTime? startDate,  DateTime? endDate,  String baseCurrency,  String? icon,  String? color,  DateTime? archivedAt,  String createdBy,  DateTime createdAt,  int memberCount,  List<MemberPreview> memberPreview,  int? myBalanceCents,  DateTime? lastActivityAt,  int expenseCount,  int itemCount,  int totalSpentCents,  String? createdByName)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.name,_that.description,_that.startDate,_that.endDate,_that.baseCurrency,_that.icon,_that.color,_that.archivedAt,_that.createdBy,_that.createdAt,_that.memberCount,_that.memberPreview,_that.myBalanceCents,_that.lastActivityAt,_that.expenseCount,_that.itemCount,_that.totalSpentCents,_that.createdByName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  DateTime? startDate,  DateTime? endDate,  String baseCurrency,  String? icon,  String? color,  DateTime? archivedAt,  String createdBy,  DateTime createdAt,  int memberCount,  List<MemberPreview> memberPreview,  int? myBalanceCents,  DateTime? lastActivityAt,  int expenseCount,  int itemCount,  int totalSpentCents,  String? createdByName)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.startDate,_that.endDate,_that.baseCurrency,_that.icon,_that.color,_that.archivedAt,_that.createdBy,_that.createdAt,_that.memberCount,_that.memberPreview,_that.myBalanceCents,_that.lastActivityAt,_that.expenseCount,_that.itemCount,_that.totalSpentCents,_that.createdByName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip extends Trip {
  const _Trip({required this.id, required this.name, this.description, this.startDate, this.endDate, required this.baseCurrency, this.icon, this.color, this.archivedAt, required this.createdBy, required this.createdAt, this.memberCount = 0, final  List<MemberPreview> memberPreview = const <MemberPreview>[], this.myBalanceCents, this.lastActivityAt, this.expenseCount = 0, this.itemCount = 0, this.totalSpentCents = 0, this.createdByName}): _memberPreview = memberPreview,super._();
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String baseCurrency;
@override final  String? icon;
@override final  String? color;
@override final  DateTime? archivedAt;
@override final  String createdBy;
@override final  DateTime createdAt;
@override@JsonKey() final  int memberCount;
 final  List<MemberPreview> _memberPreview;
@override@JsonKey() List<MemberPreview> get memberPreview {
  if (_memberPreview is EqualUnmodifiableListView) return _memberPreview;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberPreview);
}

@override final  int? myBalanceCents;
@override final  DateTime? lastActivityAt;
@override@JsonKey() final  int expenseCount;
@override@JsonKey() final  int itemCount;
@override@JsonKey() final  int totalSpentCents;
@override final  String? createdByName;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other._memberPreview, _memberPreview)&&(identical(other.myBalanceCents, myBalanceCents) || other.myBalanceCents == myBalanceCents)&&(identical(other.lastActivityAt, lastActivityAt) || other.lastActivityAt == lastActivityAt)&&(identical(other.expenseCount, expenseCount) || other.expenseCount == expenseCount)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.totalSpentCents, totalSpentCents) || other.totalSpentCents == totalSpentCents)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,description,startDate,endDate,baseCurrency,icon,color,archivedAt,createdBy,createdAt,memberCount,const DeepCollectionEquality().hash(_memberPreview),myBalanceCents,lastActivityAt,expenseCount,itemCount,totalSpentCents,createdByName]);

@override
String toString() {
  return 'Trip(id: $id, name: $name, description: $description, startDate: $startDate, endDate: $endDate, baseCurrency: $baseCurrency, icon: $icon, color: $color, archivedAt: $archivedAt, createdBy: $createdBy, createdAt: $createdAt, memberCount: $memberCount, memberPreview: $memberPreview, myBalanceCents: $myBalanceCents, lastActivityAt: $lastActivityAt, expenseCount: $expenseCount, itemCount: $itemCount, totalSpentCents: $totalSpentCents, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, DateTime? startDate, DateTime? endDate, String baseCurrency, String? icon, String? color, DateTime? archivedAt, String createdBy, DateTime createdAt, int memberCount, List<MemberPreview> memberPreview, int? myBalanceCents, DateTime? lastActivityAt, int expenseCount, int itemCount, int totalSpentCents, String? createdByName
});




}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? baseCurrency = null,Object? icon = freezed,Object? color = freezed,Object? archivedAt = freezed,Object? createdBy = null,Object? createdAt = null,Object? memberCount = null,Object? memberPreview = null,Object? myBalanceCents = freezed,Object? lastActivityAt = freezed,Object? expenseCount = null,Object? itemCount = null,Object? totalSpentCents = null,Object? createdByName = freezed,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberPreview: null == memberPreview ? _self._memberPreview : memberPreview // ignore: cast_nullable_to_non_nullable
as List<MemberPreview>,myBalanceCents: freezed == myBalanceCents ? _self.myBalanceCents : myBalanceCents // ignore: cast_nullable_to_non_nullable
as int?,lastActivityAt: freezed == lastActivityAt ? _self.lastActivityAt : lastActivityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expenseCount: null == expenseCount ? _self.expenseCount : expenseCount // ignore: cast_nullable_to_non_nullable
as int,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentCents: null == totalSpentCents ? _self.totalSpentCents : totalSpentCents // ignore: cast_nullable_to_non_nullable
as int,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
