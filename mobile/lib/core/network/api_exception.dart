import 'package:dio/dio.dart';

/// What went wrong, at the level a screen has to care about.
enum ApiFailure {
  /// The request never completed in time.
  timeout,

  /// The device could not reach the server at all.
  offline,

  /// The server answered, and the answer was a refusal.
  response,
}

/// A failure the UI can branch on.
///
/// Dio errors are too low-level to act on; this collapses them into a kind, a
/// status code and any structured detail the API sent. Deliberately no
/// user-facing text: the server speaks English to developers, and the sentence a
/// person reads is chosen by `friendlyError` in their own language.
class ApiException implements Exception {
  const ApiException(
    this.kind, {
    this.statusCode,
    this.fieldErrors,
    this.code,
    this.details,
    this.serverMessage,
  });

  final ApiFailure kind;
  final int? statusCode;

  /// Per-field validation messages from a 422, keyed by field name. English,
  /// from the server: useful in a log, not on screen.
  final Map<String, String>? fieldErrors;

  /// Machine-readable reason, when the API sends one. Two conflicts on the same
  /// endpoint can need two different screens — "hand the trip over first" is not
  /// "settle up first" — and branching on English prose would break the day the
  /// wording changes.
  final String? code;

  /// The rest of a structured error: an amount, a user id, whatever the code
  /// needs to be rendered as a sentence.
  final Map<String, dynamic>? details;

  /// Kept for logs and for `toString`. Never rendered.
  final String? serverMessage;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory ApiException.from(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(ApiFailure.timeout);
      case DioExceptionType.connectionError:
        return const ApiException(ApiFailure.offline);
      default:
        break;
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (status == 422 && data is Map && data['detail'] is List) {
      // FastAPI validation errors: loc is a path like ["body", "email"].
      final fields = <String, String>{};
      for (final item in data['detail'] as List) {
        if (item is! Map) continue;
        final loc = item['loc'];
        final field = (loc is List && loc.length > 1) ? '${loc.last}' : 'form';
        fields[field] = '${item['msg']}';
      }
      return ApiException(
        ApiFailure.response,
        statusCode: status,
        fieldErrors: fields,
        serverMessage: fields.values.firstOrNull,
      );
    }

    if (data is Map && data['detail'] is String) {
      return ApiException(
        ApiFailure.response,
        statusCode: status,
        serverMessage: data['detail'] as String,
      );
    }

    // A structured error: {"detail": {"code": ..., "message": ..., ...}}.
    if (data is Map && data['detail'] is Map) {
      final detail = Map<String, dynamic>.from(data['detail'] as Map);
      return ApiException(
        ApiFailure.response,
        statusCode: status,
        code: detail['code'] as String?,
        details: detail,
        serverMessage: detail['message'] as String?,
      );
    }

    return ApiException(ApiFailure.response, statusCode: status);
  }

  @override
  String toString() =>
      'ApiException(${kind.name}, $statusCode, $serverMessage)';
}
