// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invite _$InviteFromJson(Map<String, dynamic> json) => _Invite(
  id: json['id'] as String,
  code: json['code'] as String,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  maxUses: (json['max_uses'] as num?)?.toInt(),
  usesCount: (json['uses_count'] as num).toInt(),
  revokedAt: json['revoked_at'] == null
      ? null
      : DateTime.parse(json['revoked_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InviteToJson(_Invite instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'max_uses': instance.maxUses,
  'uses_count': instance.usesCount,
  'revoked_at': instance.revokedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
