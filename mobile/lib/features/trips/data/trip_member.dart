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
    // Set for people who have left. They are still listed because expenses
    // outlive membership: without them the ledger would show "Unknown" next to
    // real amounts.
    DateTime? leftAt,
  }) = _TripMember;

  const TripMember._();

  /// Anything that picks a person — an assignee, a payer, a split — must offer
  /// only members where this is false.
  bool get hasLeft => leftAt != null;

  factory TripMember.fromJson(Map<String, dynamic> json) =>
      _$TripMemberFromJson(json);
}