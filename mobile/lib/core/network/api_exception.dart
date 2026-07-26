import 'package:dio/dio.dart';

/// A failure the UI can actually render.
///
/// Dio errors are too low-level to show a user; this collapses them into a
/// message plus enough structure for callers to branch on.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;

  /// Per-field validation messages from a 422, keyed by field name.
  final Map<String, String>? fieldErrors;

  /// Machine-readable reason, when the API sends one. Two conflicts on the same
  /// endpoint can need two different screens — "hand the trip over first" is not
  /// "settle up first" — and branching on English prose would break the day the
  /// wording changes.
  final String? code;

  /// The rest of a structured error: an amount, a user id, whatever the code
  /// needs to be rendered as a sentence.
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory ApiException.from(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException('Connessione lenta. Riprova.');
      case DioExceptionType.connectionError:
        return const ApiException('Nessuna connessione al server.');
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
        fields.values.firstOrNull ?? 'Dati non validi.',
        statusCode: status,
        fieldErrors: fields,
      );
    }

    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String, statusCode: status);
    }

    // A structured error: {"detail": {"code": ..., "message": ..., ...}}.
    if (data is Map && data['detail'] is Map) {
      final detail = Map<String, dynamic>.from(data['detail'] as Map);
      return ApiException(
        detail['message'] as String? ?? 'Qualcosa è andato storto.',
        statusCode: status,
        code: detail['code'] as String?,
        details: detail,
      );
    }

    return ApiException('Qualcosa è andato storto.', statusCode: status);
  }

  @override
  String toString() => message;
}