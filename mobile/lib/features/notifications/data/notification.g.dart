// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      kind: $enumDecode(
        _$NotificationKindEnumMap,
        json['kind'],
        unknownValue: NotificationKind.unknown,
      ),
      actorId: json['actor_id'] as String?,
      entityId: json['entity_id'] as String?,
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'kind': _$NotificationKindEnumMap[instance.kind]!,
      'actor_id': instance.actorId,
      'entity_id': instance.entityId,
      'payload': instance.payload,
      'read_at': instance.readAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$NotificationKindEnumMap = {
  NotificationKind.expenseAdded: 'expense_added',
  NotificationKind.expenseDeleted: 'expense_deleted',
  NotificationKind.settlementReceived: 'settlement_received',
  NotificationKind.taskAssigned: 'task_assigned',
  NotificationKind.eventAdded: 'event_added',
  NotificationKind.memberJoined: 'member_joined',
  NotificationKind.unknown: 'unknown',
};

_NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) =>
    _NotificationPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );

Map<String, dynamic> _$NotificationPageToJson(_NotificationPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'next_cursor': instance.nextCursor,
    };
