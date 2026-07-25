// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Item _$ItemFromJson(Map<String, dynamic> json) => _Item(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  type: $enumDecode(_$ItemTypeEnumMap, json['type']),
  title: json['title'] as String,
  description: json['description'] as String?,
  location: json['location'] as String?,
  startsAt: json['starts_at'] == null
      ? null
      : DateTime.parse(json['starts_at'] as String),
  endsAt: json['ends_at'] == null
      ? null
      : DateTime.parse(json['ends_at'] as String),
  assignees:
      (json['assignees'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  completedBy: json['completed_by'] as String?,
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ItemToJson(_Item instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'type': _$ItemTypeEnumMap[instance.type]!,
  'title': instance.title,
  'description': instance.description,
  'location': instance.location,
  'starts_at': instance.startsAt?.toIso8601String(),
  'ends_at': instance.endsAt?.toIso8601String(),
  'assignees': instance.assignees,
  'completed_at': instance.completedAt?.toIso8601String(),
  'completed_by': instance.completedBy,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$ItemTypeEnumMap = {ItemType.event: 'event', ItemType.task: 'task'};
