import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite.freezed.dart';
part 'invite.g.dart';

@freezed
abstract class Invite with _$Invite {
  const factory Invite({
    required String id,
    required String code,
    DateTime? expiresAt,
    int? maxUses,
    required int usesCount,
    DateTime? revokedAt,
    required DateTime createdAt,
  }) = _Invite;

  const Invite._();

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  /// Mirrors the backend's own checks, so a code the API would reject is never
  /// presented as usable.
  bool get isActive {
    if (revokedAt != null) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    if (maxUses != null && usesCount >= maxUses!) return false;
    return true;
  }
}