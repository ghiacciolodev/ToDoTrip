// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseShare {

 String get userId; int get shareCents;
/// Create a copy of ExpenseShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseShareCopyWith<ExpenseShare> get copyWith => _$ExpenseShareCopyWithImpl<ExpenseShare>(this as ExpenseShare, _$identity);

  /// Serializes this ExpenseShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseShare&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.shareCents, shareCents) || other.shareCents == shareCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,shareCents);

@override
String toString() {
  return 'ExpenseShare(userId: $userId, shareCents: $shareCents)';
}


}

/// @nodoc
abstract mixin class $ExpenseShareCopyWith<$Res>  {
  factory $ExpenseShareCopyWith(ExpenseShare value, $Res Function(ExpenseShare) _then) = _$ExpenseShareCopyWithImpl;
@useResult
$Res call({
 String userId, int shareCents
});




}
/// @nodoc
class _$ExpenseShareCopyWithImpl<$Res>
    implements $ExpenseShareCopyWith<$Res> {
  _$ExpenseShareCopyWithImpl(this._self, this._then);

  final ExpenseShare _self;
  final $Res Function(ExpenseShare) _then;

/// Create a copy of ExpenseShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? shareCents = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,shareCents: null == shareCents ? _self.shareCents : shareCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseShare].
extension ExpenseSharePatterns on ExpenseShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseShare value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseShare value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  int shareCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseShare() when $default != null:
return $default(_that.userId,_that.shareCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  int shareCents)  $default,) {final _that = this;
switch (_that) {
case _ExpenseShare():
return $default(_that.userId,_that.shareCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  int shareCents)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseShare() when $default != null:
return $default(_that.userId,_that.shareCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseShare implements ExpenseShare {
  const _ExpenseShare({required this.userId, required this.shareCents});
  factory _ExpenseShare.fromJson(Map<String, dynamic> json) => _$ExpenseShareFromJson(json);

@override final  String userId;
@override final  int shareCents;

/// Create a copy of ExpenseShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseShareCopyWith<_ExpenseShare> get copyWith => __$ExpenseShareCopyWithImpl<_ExpenseShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseShare&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.shareCents, shareCents) || other.shareCents == shareCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,shareCents);

@override
String toString() {
  return 'ExpenseShare(userId: $userId, shareCents: $shareCents)';
}


}

/// @nodoc
abstract mixin class _$ExpenseShareCopyWith<$Res> implements $ExpenseShareCopyWith<$Res> {
  factory _$ExpenseShareCopyWith(_ExpenseShare value, $Res Function(_ExpenseShare) _then) = __$ExpenseShareCopyWithImpl;
@override @useResult
$Res call({
 String userId, int shareCents
});




}
/// @nodoc
class __$ExpenseShareCopyWithImpl<$Res>
    implements _$ExpenseShareCopyWith<$Res> {
  __$ExpenseShareCopyWithImpl(this._self, this._then);

  final _ExpenseShare _self;
  final $Res Function(_ExpenseShare) _then;

/// Create a copy of ExpenseShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? shareCents = null,}) {
  return _then(_ExpenseShare(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,shareCents: null == shareCents ? _self.shareCents : shareCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Expense {

 String get id; String get tripId; String get description; int get amountCents; String get currency; String get paidBy; DateTime get spentAt; String get createdBy; DateTime get createdAt; List<ExpenseShare> get shares;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.spentAt, spentAt) || other.spentAt == spentAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.shares, shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,description,amountCents,currency,paidBy,spentAt,createdBy,createdAt,const DeepCollectionEquality().hash(shares));

@override
String toString() {
  return 'Expense(id: $id, tripId: $tripId, description: $description, amountCents: $amountCents, currency: $currency, paidBy: $paidBy, spentAt: $spentAt, createdBy: $createdBy, createdAt: $createdAt, shares: $shares)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String description, int amountCents, String currency, String paidBy, DateTime spentAt, String createdBy, DateTime createdAt, List<ExpenseShare> shares
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? description = null,Object? amountCents = null,Object? currency = null,Object? paidBy = null,Object? spentAt = null,Object? createdBy = null,Object? createdAt = null,Object? shares = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,spentAt: null == spentAt ? _self.spentAt : spentAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as List<ExpenseShare>,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String description,  int amountCents,  String currency,  String paidBy,  DateTime spentAt,  String createdBy,  DateTime createdAt,  List<ExpenseShare> shares)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.tripId,_that.description,_that.amountCents,_that.currency,_that.paidBy,_that.spentAt,_that.createdBy,_that.createdAt,_that.shares);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String description,  int amountCents,  String currency,  String paidBy,  DateTime spentAt,  String createdBy,  DateTime createdAt,  List<ExpenseShare> shares)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.tripId,_that.description,_that.amountCents,_that.currency,_that.paidBy,_that.spentAt,_that.createdBy,_that.createdAt,_that.shares);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String description,  int amountCents,  String currency,  String paidBy,  DateTime spentAt,  String createdBy,  DateTime createdAt,  List<ExpenseShare> shares)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.tripId,_that.description,_that.amountCents,_that.currency,_that.paidBy,_that.spentAt,_that.createdBy,_that.createdAt,_that.shares);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense extends Expense {
  const _Expense({required this.id, required this.tripId, required this.description, required this.amountCents, required this.currency, required this.paidBy, required this.spentAt, required this.createdBy, required this.createdAt, required final  List<ExpenseShare> shares}): _shares = shares,super._();
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String description;
@override final  int amountCents;
@override final  String currency;
@override final  String paidBy;
@override final  DateTime spentAt;
@override final  String createdBy;
@override final  DateTime createdAt;
 final  List<ExpenseShare> _shares;
@override List<ExpenseShare> get shares {
  if (_shares is EqualUnmodifiableListView) return _shares;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shares);
}


/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.spentAt, spentAt) || other.spentAt == spentAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._shares, _shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,description,amountCents,currency,paidBy,spentAt,createdBy,createdAt,const DeepCollectionEquality().hash(_shares));

@override
String toString() {
  return 'Expense(id: $id, tripId: $tripId, description: $description, amountCents: $amountCents, currency: $currency, paidBy: $paidBy, spentAt: $spentAt, createdBy: $createdBy, createdAt: $createdAt, shares: $shares)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String description, int amountCents, String currency, String paidBy, DateTime spentAt, String createdBy, DateTime createdAt, List<ExpenseShare> shares
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? description = null,Object? amountCents = null,Object? currency = null,Object? paidBy = null,Object? spentAt = null,Object? createdBy = null,Object? createdAt = null,Object? shares = null,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,spentAt: null == spentAt ? _self.spentAt : spentAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,shares: null == shares ? _self._shares : shares // ignore: cast_nullable_to_non_nullable
as List<ExpenseShare>,
  ));
}


}


/// @nodoc
mixin _$BalanceEntry {

 String get userId; int get balanceCents;
/// Create a copy of BalanceEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceEntryCopyWith<BalanceEntry> get copyWith => _$BalanceEntryCopyWithImpl<BalanceEntry>(this as BalanceEntry, _$identity);

  /// Serializes this BalanceEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.balanceCents, balanceCents) || other.balanceCents == balanceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,balanceCents);

@override
String toString() {
  return 'BalanceEntry(userId: $userId, balanceCents: $balanceCents)';
}


}

/// @nodoc
abstract mixin class $BalanceEntryCopyWith<$Res>  {
  factory $BalanceEntryCopyWith(BalanceEntry value, $Res Function(BalanceEntry) _then) = _$BalanceEntryCopyWithImpl;
@useResult
$Res call({
 String userId, int balanceCents
});




}
/// @nodoc
class _$BalanceEntryCopyWithImpl<$Res>
    implements $BalanceEntryCopyWith<$Res> {
  _$BalanceEntryCopyWithImpl(this._self, this._then);

  final BalanceEntry _self;
  final $Res Function(BalanceEntry) _then;

/// Create a copy of BalanceEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? balanceCents = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,balanceCents: null == balanceCents ? _self.balanceCents : balanceCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceEntry].
extension BalanceEntryPatterns on BalanceEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceEntry value)  $default,){
final _that = this;
switch (_that) {
case _BalanceEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  int balanceCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceEntry() when $default != null:
return $default(_that.userId,_that.balanceCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  int balanceCents)  $default,) {final _that = this;
switch (_that) {
case _BalanceEntry():
return $default(_that.userId,_that.balanceCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  int balanceCents)?  $default,) {final _that = this;
switch (_that) {
case _BalanceEntry() when $default != null:
return $default(_that.userId,_that.balanceCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceEntry implements BalanceEntry {
  const _BalanceEntry({required this.userId, required this.balanceCents});
  factory _BalanceEntry.fromJson(Map<String, dynamic> json) => _$BalanceEntryFromJson(json);

@override final  String userId;
@override final  int balanceCents;

/// Create a copy of BalanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceEntryCopyWith<_BalanceEntry> get copyWith => __$BalanceEntryCopyWithImpl<_BalanceEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.balanceCents, balanceCents) || other.balanceCents == balanceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,balanceCents);

@override
String toString() {
  return 'BalanceEntry(userId: $userId, balanceCents: $balanceCents)';
}


}

/// @nodoc
abstract mixin class _$BalanceEntryCopyWith<$Res> implements $BalanceEntryCopyWith<$Res> {
  factory _$BalanceEntryCopyWith(_BalanceEntry value, $Res Function(_BalanceEntry) _then) = __$BalanceEntryCopyWithImpl;
@override @useResult
$Res call({
 String userId, int balanceCents
});




}
/// @nodoc
class __$BalanceEntryCopyWithImpl<$Res>
    implements _$BalanceEntryCopyWith<$Res> {
  __$BalanceEntryCopyWithImpl(this._self, this._then);

  final _BalanceEntry _self;
  final $Res Function(_BalanceEntry) _then;

/// Create a copy of BalanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? balanceCents = null,}) {
  return _then(_BalanceEntry(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,balanceCents: null == balanceCents ? _self.balanceCents : balanceCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TransferSuggestion {

 String get fromUserId; String get toUserId; int get amountCents;
/// Create a copy of TransferSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferSuggestionCopyWith<TransferSuggestion> get copyWith => _$TransferSuggestionCopyWithImpl<TransferSuggestion>(this as TransferSuggestion, _$identity);

  /// Serializes this TransferSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferSuggestion&&(identical(other.fromUserId, fromUserId) || other.fromUserId == fromUserId)&&(identical(other.toUserId, toUserId) || other.toUserId == toUserId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromUserId,toUserId,amountCents);

@override
String toString() {
  return 'TransferSuggestion(fromUserId: $fromUserId, toUserId: $toUserId, amountCents: $amountCents)';
}


}

/// @nodoc
abstract mixin class $TransferSuggestionCopyWith<$Res>  {
  factory $TransferSuggestionCopyWith(TransferSuggestion value, $Res Function(TransferSuggestion) _then) = _$TransferSuggestionCopyWithImpl;
@useResult
$Res call({
 String fromUserId, String toUserId, int amountCents
});




}
/// @nodoc
class _$TransferSuggestionCopyWithImpl<$Res>
    implements $TransferSuggestionCopyWith<$Res> {
  _$TransferSuggestionCopyWithImpl(this._self, this._then);

  final TransferSuggestion _self;
  final $Res Function(TransferSuggestion) _then;

/// Create a copy of TransferSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromUserId = null,Object? toUserId = null,Object? amountCents = null,}) {
  return _then(_self.copyWith(
fromUserId: null == fromUserId ? _self.fromUserId : fromUserId // ignore: cast_nullable_to_non_nullable
as String,toUserId: null == toUserId ? _self.toUserId : toUserId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferSuggestion].
extension TransferSuggestionPatterns on TransferSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _TransferSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _TransferSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fromUserId,  String toUserId,  int amountCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferSuggestion() when $default != null:
return $default(_that.fromUserId,_that.toUserId,_that.amountCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fromUserId,  String toUserId,  int amountCents)  $default,) {final _that = this;
switch (_that) {
case _TransferSuggestion():
return $default(_that.fromUserId,_that.toUserId,_that.amountCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fromUserId,  String toUserId,  int amountCents)?  $default,) {final _that = this;
switch (_that) {
case _TransferSuggestion() when $default != null:
return $default(_that.fromUserId,_that.toUserId,_that.amountCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransferSuggestion implements TransferSuggestion {
  const _TransferSuggestion({required this.fromUserId, required this.toUserId, required this.amountCents});
  factory _TransferSuggestion.fromJson(Map<String, dynamic> json) => _$TransferSuggestionFromJson(json);

@override final  String fromUserId;
@override final  String toUserId;
@override final  int amountCents;

/// Create a copy of TransferSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferSuggestionCopyWith<_TransferSuggestion> get copyWith => __$TransferSuggestionCopyWithImpl<_TransferSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferSuggestion&&(identical(other.fromUserId, fromUserId) || other.fromUserId == fromUserId)&&(identical(other.toUserId, toUserId) || other.toUserId == toUserId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fromUserId,toUserId,amountCents);

@override
String toString() {
  return 'TransferSuggestion(fromUserId: $fromUserId, toUserId: $toUserId, amountCents: $amountCents)';
}


}

/// @nodoc
abstract mixin class _$TransferSuggestionCopyWith<$Res> implements $TransferSuggestionCopyWith<$Res> {
  factory _$TransferSuggestionCopyWith(_TransferSuggestion value, $Res Function(_TransferSuggestion) _then) = __$TransferSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String fromUserId, String toUserId, int amountCents
});




}
/// @nodoc
class __$TransferSuggestionCopyWithImpl<$Res>
    implements _$TransferSuggestionCopyWith<$Res> {
  __$TransferSuggestionCopyWithImpl(this._self, this._then);

  final _TransferSuggestion _self;
  final $Res Function(_TransferSuggestion) _then;

/// Create a copy of TransferSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromUserId = null,Object? toUserId = null,Object? amountCents = null,}) {
  return _then(_TransferSuggestion(
fromUserId: null == fromUserId ? _self.fromUserId : fromUserId // ignore: cast_nullable_to_non_nullable
as String,toUserId: null == toUserId ? _self.toUserId : toUserId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BalanceReport {

 List<BalanceEntry> get balances; List<TransferSuggestion> get suggestedTransfers; int get totalSpentCents;
/// Create a copy of BalanceReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceReportCopyWith<BalanceReport> get copyWith => _$BalanceReportCopyWithImpl<BalanceReport>(this as BalanceReport, _$identity);

  /// Serializes this BalanceReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceReport&&const DeepCollectionEquality().equals(other.balances, balances)&&const DeepCollectionEquality().equals(other.suggestedTransfers, suggestedTransfers)&&(identical(other.totalSpentCents, totalSpentCents) || other.totalSpentCents == totalSpentCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(balances),const DeepCollectionEquality().hash(suggestedTransfers),totalSpentCents);

@override
String toString() {
  return 'BalanceReport(balances: $balances, suggestedTransfers: $suggestedTransfers, totalSpentCents: $totalSpentCents)';
}


}

/// @nodoc
abstract mixin class $BalanceReportCopyWith<$Res>  {
  factory $BalanceReportCopyWith(BalanceReport value, $Res Function(BalanceReport) _then) = _$BalanceReportCopyWithImpl;
@useResult
$Res call({
 List<BalanceEntry> balances, List<TransferSuggestion> suggestedTransfers, int totalSpentCents
});




}
/// @nodoc
class _$BalanceReportCopyWithImpl<$Res>
    implements $BalanceReportCopyWith<$Res> {
  _$BalanceReportCopyWithImpl(this._self, this._then);

  final BalanceReport _self;
  final $Res Function(BalanceReport) _then;

/// Create a copy of BalanceReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balances = null,Object? suggestedTransfers = null,Object? totalSpentCents = null,}) {
  return _then(_self.copyWith(
balances: null == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as List<BalanceEntry>,suggestedTransfers: null == suggestedTransfers ? _self.suggestedTransfers : suggestedTransfers // ignore: cast_nullable_to_non_nullable
as List<TransferSuggestion>,totalSpentCents: null == totalSpentCents ? _self.totalSpentCents : totalSpentCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceReport].
extension BalanceReportPatterns on BalanceReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceReport value)  $default,){
final _that = this;
switch (_that) {
case _BalanceReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceReport value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BalanceEntry> balances,  List<TransferSuggestion> suggestedTransfers,  int totalSpentCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceReport() when $default != null:
return $default(_that.balances,_that.suggestedTransfers,_that.totalSpentCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BalanceEntry> balances,  List<TransferSuggestion> suggestedTransfers,  int totalSpentCents)  $default,) {final _that = this;
switch (_that) {
case _BalanceReport():
return $default(_that.balances,_that.suggestedTransfers,_that.totalSpentCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BalanceEntry> balances,  List<TransferSuggestion> suggestedTransfers,  int totalSpentCents)?  $default,) {final _that = this;
switch (_that) {
case _BalanceReport() when $default != null:
return $default(_that.balances,_that.suggestedTransfers,_that.totalSpentCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceReport extends BalanceReport {
  const _BalanceReport({required final  List<BalanceEntry> balances, required final  List<TransferSuggestion> suggestedTransfers, required this.totalSpentCents}): _balances = balances,_suggestedTransfers = suggestedTransfers,super._();
  factory _BalanceReport.fromJson(Map<String, dynamic> json) => _$BalanceReportFromJson(json);

 final  List<BalanceEntry> _balances;
@override List<BalanceEntry> get balances {
  if (_balances is EqualUnmodifiableListView) return _balances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_balances);
}

 final  List<TransferSuggestion> _suggestedTransfers;
@override List<TransferSuggestion> get suggestedTransfers {
  if (_suggestedTransfers is EqualUnmodifiableListView) return _suggestedTransfers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestedTransfers);
}

@override final  int totalSpentCents;

/// Create a copy of BalanceReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceReportCopyWith<_BalanceReport> get copyWith => __$BalanceReportCopyWithImpl<_BalanceReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceReport&&const DeepCollectionEquality().equals(other._balances, _balances)&&const DeepCollectionEquality().equals(other._suggestedTransfers, _suggestedTransfers)&&(identical(other.totalSpentCents, totalSpentCents) || other.totalSpentCents == totalSpentCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_balances),const DeepCollectionEquality().hash(_suggestedTransfers),totalSpentCents);

@override
String toString() {
  return 'BalanceReport(balances: $balances, suggestedTransfers: $suggestedTransfers, totalSpentCents: $totalSpentCents)';
}


}

/// @nodoc
abstract mixin class _$BalanceReportCopyWith<$Res> implements $BalanceReportCopyWith<$Res> {
  factory _$BalanceReportCopyWith(_BalanceReport value, $Res Function(_BalanceReport) _then) = __$BalanceReportCopyWithImpl;
@override @useResult
$Res call({
 List<BalanceEntry> balances, List<TransferSuggestion> suggestedTransfers, int totalSpentCents
});




}
/// @nodoc
class __$BalanceReportCopyWithImpl<$Res>
    implements _$BalanceReportCopyWith<$Res> {
  __$BalanceReportCopyWithImpl(this._self, this._then);

  final _BalanceReport _self;
  final $Res Function(_BalanceReport) _then;

/// Create a copy of BalanceReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balances = null,Object? suggestedTransfers = null,Object? totalSpentCents = null,}) {
  return _then(_BalanceReport(
balances: null == balances ? _self._balances : balances // ignore: cast_nullable_to_non_nullable
as List<BalanceEntry>,suggestedTransfers: null == suggestedTransfers ? _self._suggestedTransfers : suggestedTransfers // ignore: cast_nullable_to_non_nullable
as List<TransferSuggestion>,totalSpentCents: null == totalSpentCents ? _self.totalSpentCents : totalSpentCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
