import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// The authenticated user, mirroring the API's UserPublic schema.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String displayName,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

extension UserName on User {
  /// The name to draw, or null when there is none to draw.
  ///
  /// A closed account keeps its row — expenses point at it and decide what
  /// everybody else owes — but its name is erased, so the field comes back
  /// empty. Returning null here means every place that already falls back for a
  /// member it cannot find falls back for a member who has gone, too, instead
  /// of rendering a blank space where a name belongs.
  String? get nameOrNull => displayName.isEmpty ? null : displayName;
}
