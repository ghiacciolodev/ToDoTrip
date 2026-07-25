import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'trip.dart';

/// Talks to /trips. Converts Dio failures into ApiException so nothing
/// Dio-specific leaks into the UI layer.
class TripRepository {
  TripRepository({required this.dio});

  final Dio dio;

  Future<List<Trip>> list() async {
    try {
      final response = await dio.get('/trips');
      return (response.data as List)
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Trip> create({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await dio.post(
        '/trips',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          // The API column is DATE, not timestamp: sending an ISO datetime
          // would be rejected, so only the calendar day is sent.
          if (startDate != null) 'start_date': _asDate(startDate),
          if (endDate != null) 'end_date': _asDate(endDate),
        },
      );
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Trip> joinByCode(String code) async {
    try {
      final response = await dio.post(
        '/trips/join',
        data: {'code': code.trim().toUpperCase()},
      );
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  static String _asDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
}