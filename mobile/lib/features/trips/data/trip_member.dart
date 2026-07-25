import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/data/user.dart';

part 'trip_member.freezed.dart';
part 'trip_member.g.dart';

enum MemberRole {
  @JsonValue('owner')
  owner,
  @JsonValue('member')
  member,
}

@freezed
abstract class TripMember with _$TripMember {
  const factory TripMember({
    required User user,
    required MemberRole role,
    required DateTime joinedAt,
  }) = _TripMember;

  factory TripMember.fromJson(Map<String, dynamic> json) =>
      _$TripMemberFromJson(json);
}