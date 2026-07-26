// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settlement _$SettlementFromJson(Map<String, dynamic> json) => _Settlement(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  fromUserId: json['from_user_id'] as String,
  toUserId: json['to_user_id'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  note: json['note'] as String?,
  settledAt: DateTime.parse(json['settled_at'] as String),
);

Map<String, dynamic> _$SettlementToJson(_Settlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'amount_cents': instance.amountCents,
      'note': instance.note,
      'settled_at': instance.settledAt.toIso8601String(),
    };
