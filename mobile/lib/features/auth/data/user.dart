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
