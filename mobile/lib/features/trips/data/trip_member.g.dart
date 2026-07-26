// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripMember _$TripMemberFromJson(Map<String, dynamic> json) => _TripMember(
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  role: $enumDecode(_$MemberRoleEnumMap, json['role']),
  joinedAt: DateTime.parse(json['joined_at'] as String),
  leftAt: json['left_at'] == null
      ? null
      : DateTime.parse(json['left_at'] as String),
);

Map<String, dynamic> _$TripMemberToJson(_TripMember instance) =>
    <String, dynamic>{
      'user': instance.user,
      'role': _$MemberRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_at': instance.leftAt?.toIso8601String(),
    };

const _$MemberRoleEnumMap = {
  MemberRole.owner: 'owner',
  MemberRole.member: 'member',
};
