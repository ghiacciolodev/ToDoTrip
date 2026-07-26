// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistEntry {

 String get id; String get checklistId; String get text; DateTime? get checkedAt; String? get checkedBy; DateTime get createdAt;
/// Create a copy of ChecklistEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistEntryCopyWith<ChecklistEntry> get copyWith => _$ChecklistEntryCopyWithImpl<ChecklistEntry>(this as ChecklistEntry, _$identity);

  /// Serializes this ChecklistEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.checklistId, checklistId) || other.checklistId == checklistId)&&(identical(other.text, text) || other.text == text)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.checkedBy, checkedBy) || other.checkedBy == checkedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,checklistId,text,checkedAt,checkedBy,createdAt);

@override
String toString() {
  return 'ChecklistEntry(id: $id, checklistId: $checklistId, text: $text, checkedAt: $checkedAt, checkedBy: $checkedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChecklistEntryCopyWith<$Res>  {
  factory $ChecklistEntryCopyWith(ChecklistEntry value, $Res Function(ChecklistEntry) _then) = _$ChecklistEntryCopyWithImpl;
@useResult
$Res call({
 String id, String checklistId, String text, DateTime? checkedAt, String? checkedBy, DateTime createdAt
});




}
/// @nodoc
class _$ChecklistEntryCopyWithImpl<$Res>
    implements $ChecklistEntryCopyWith<$Res> {
  _$ChecklistEntryCopyWithImpl(this._self, this._then);

  final ChecklistEntry _self;
  final $Res Function(ChecklistEntry) _then;

/// Create a copy of ChecklistEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? checklistId = null,Object? text = null,Object? checkedAt = freezed,Object? checkedBy = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,checklistId: null == checklistId ? _self.checklistId : checklistId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,checkedBy: freezed == checkedBy ? _self.checkedBy : checkedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistEntry].
extension ChecklistEntryPatterns on ChecklistEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistEntry value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String checklistId,  String text,  DateTime? checkedAt,  String? checkedBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistEntry() when $default != null:
return $default(_that.id,_that.checklistId,_that.text,_that.checkedAt,_that.checkedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String checklistId,  String text,  DateTime? checkedAt,  String? checkedBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ChecklistEntry():
return $default(_that.id,_that.checklistId,_that.text,_that.checkedAt,_that.checkedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String checklistId,  String text,  DateTime? checkedAt,  String? checkedBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistEntry() when $default != null:
return $default(_that.id,_that.checklistId,_that.text,_that.checkedAt,_that.checkedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistEntry extends ChecklistEntry {
  const _ChecklistEntry({required this.id, required this.checklistId, required this.text, this.checkedAt, this.checkedBy, required this.createdAt}): super._();
  factory _ChecklistEntry.fromJson(Map<String, dynamic> json) => _$ChecklistEntryFromJson(json);

@override final  String id;
@override final  String checklistId;
@override final  String text;
@override final  DateTime? checkedAt;
@override final  String? checkedBy;
@override final  DateTime createdAt;

/// Create a copy of ChecklistEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistEntryCopyWith<_ChecklistEntry> get copyWith => __$ChecklistEntryCopyWithImpl<_ChecklistEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.checklistId, checklistId) || other.checklistId == checklistId)&&(identical(other.text, text) || other.text == text)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.checkedBy, checkedBy) || other.checkedBy == checkedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,checklistId,text,checkedAt,checkedBy,createdAt);

@override
String toString() {
  return 'ChecklistEntry(id: $id, checklistId: $checklistId, text: $text, checkedAt: $checkedAt, checkedBy: $checkedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ChecklistEntryCopyWith<$Res> implements $ChecklistEntryCopyWith<$Res> {
  factory _$ChecklistEntryCopyWith(_ChecklistEntry value, $Res Function(_ChecklistEntry) _then) = __$ChecklistEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String checklistId, String text, DateTime? checkedAt, String? checkedBy, DateTime createdAt
});




}
/// @nodoc
class __$ChecklistEntryCopyWithImpl<$Res>
    implements _$ChecklistEntryCopyWith<$Res> {
  __$ChecklistEntryCopyWithImpl(this._self, this._then);

  final _ChecklistEntry _self;
  final $Res Function(_ChecklistEntry) _then;

/// Create a copy of ChecklistEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? checklistId = null,Object? text = null,Object? checkedAt = freezed,Object? checkedBy = freezed,Object? createdAt = null,}) {
  return _then(_ChecklistEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,checklistId: null == checklistId ? _self.checklistId : checklistId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,checkedBy: freezed == checkedBy ? _self.checkedBy : checkedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Checklist {

 String get id; String get tripId; String get name; String get createdBy; DateTime get createdAt; List<ChecklistEntry> get entries;
/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistCopyWith<Checklist> get copyWith => _$ChecklistCopyWithImpl<Checklist>(this as Checklist, _$identity);

  /// Serializes this Checklist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Checklist&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,createdBy,createdAt,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'Checklist(id: $id, tripId: $tripId, name: $name, createdBy: $createdBy, createdAt: $createdAt, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ChecklistCopyWith<$Res>  {
  factory $ChecklistCopyWith(Checklist value, $Res Function(Checklist) _then) = _$ChecklistCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String name, String createdBy, DateTime createdAt, List<ChecklistEntry> entries
});




}
/// @nodoc
class _$ChecklistCopyWithImpl<$Res>
    implements $ChecklistCopyWith<$Res> {
  _$ChecklistCopyWithImpl(this._self, this._then);

  final Checklist _self;
  final $Res Function(Checklist) _then;

/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? createdBy = null,Object? createdAt = null,Object? entries = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ChecklistEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [Checklist].
extension ChecklistPatterns on Checklist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Checklist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Checklist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Checklist value)  $default,){
final _that = this;
switch (_that) {
case _Checklist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Checklist value)?  $default,){
final _that = this;
switch (_that) {
case _Checklist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String createdBy,  DateTime createdAt,  List<ChecklistEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Checklist() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.createdBy,_that.createdAt,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String createdBy,  DateTime createdAt,  List<ChecklistEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _Checklist():
return $default(_that.id,_that.tripId,_that.name,_that.createdBy,_that.createdAt,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String name,  String createdBy,  DateTime createdAt,  List<ChecklistEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _Checklist() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.createdBy,_that.createdAt,_that.entries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Checklist extends Checklist {
  const _Checklist({required this.id, required this.tripId, required this.name, required this.createdBy, required this.createdAt, final  List<ChecklistEntry> entries = const <ChecklistEntry>[]}): _entries = entries,super._();
  factory _Checklist.fromJson(Map<String, dynamic> json) => _$ChecklistFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String name;
@override final  String createdBy;
@override final  DateTime createdAt;
 final  List<ChecklistEntry> _entries;
@override@JsonKey() List<ChecklistEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistCopyWith<_Checklist> get copyWith => __$ChecklistCopyWithImpl<_Checklist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Checklist&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,createdBy,createdAt,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'Checklist(id: $id, tripId: $tripId, name: $name, createdBy: $createdBy, createdAt: $createdAt, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$ChecklistCopyWith<$Res> implements $ChecklistCopyWith<$Res> {
  factory _$ChecklistCopyWith(_Checklist value, $Res Function(_Checklist) _then) = __$ChecklistCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String name, String createdBy, DateTime createdAt, List<ChecklistEntry> entries
});




}
/// @nodoc
class __$ChecklistCopyWithImpl<$Res>
    implements _$ChecklistCopyWith<$Res> {
  __$ChecklistCopyWithImpl(this._self, this._then);

  final _Checklist _self;
  final $Res Function(_Checklist) _then;

/// Create a copy of Checklist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? createdBy = null,Object? createdAt = null,Object? entries = null,}) {
  return _then(_Checklist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ChecklistEntry>,
  ));
}


}

// dart format on
