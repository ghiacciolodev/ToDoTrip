// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberPreview _$MemberPreviewFromJson(Map<String, dynamic> json) =>
    _MemberPreview(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$MemberPreviewToJson(_MemberPreview instance) =>
    <String, dynamic>{'id': instance.id, 'display_name': instance.displayName};

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  baseCurrency: json['base_currency'] as String,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
  memberPreview:
      (json['member_preview'] as List<dynamic>?)
          ?.map((e) => MemberPreview.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MemberPreview>[],
  myBalanceCents: (json['my_balance_cents'] as num?)?.toInt(),
  lastActivityAt: json['last_activity_at'] == null
      ? null
      : DateTime.parse(json['last_activity_at'] as String),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'start_date': instance.startDate?.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'base_currency': instance.baseCurrency,
  'icon': instance.icon,
  'color': instance.color,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'member_count': instance.memberCount,
  'member_preview': instance.memberPreview,
  'my_balance_cents': instance.myBalanceCents,
  'last_activity_at': instance.lastActivityAt?.toIso8601String(),
};
