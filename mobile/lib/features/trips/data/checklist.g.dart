// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistEntry _$ChecklistEntryFromJson(Map<String, dynamic> json) =>
    _ChecklistEntry(
      id: json['id'] as String,
      checklistId: json['checklist_id'] as String,
      text: json['text'] as String,
      checkedAt: json['checked_at'] == null
          ? null
          : DateTime.parse(json['checked_at'] as String),
      checkedBy: json['checked_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChecklistEntryToJson(_ChecklistEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'checklist_id': instance.checklistId,
      'text': instance.text,
      'checked_at': instance.checkedAt?.toIso8601String(),
      'checked_by': instance.checkedBy,
      'created_at': instance.createdAt.toIso8601String(),
    };

_Checklist _$ChecklistFromJson(Map<String, dynamic> json) => _Checklist(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  name: json['name'] as String,
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => ChecklistEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChecklistEntry>[],
);

Map<String, dynamic> _$ChecklistToJson(_Checklist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'name': instance.name,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'entries': instance.entries,
    };
