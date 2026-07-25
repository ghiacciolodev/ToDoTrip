import 'package:dio/dio.dart';

/// A failure the UI can actually render.
///
/// Dio errors are too low-level to show a user; this collapses them into a
/// message plus enough structure for callers to branch on.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;

  /// Per-field validation messages from a 422, keyed by field name.
  final Map<String, String>? fieldErrors;

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

    return ApiException('Qualcosa è andato storto.', statusCode: status);
  }

  @override
  String toString() => message;
}