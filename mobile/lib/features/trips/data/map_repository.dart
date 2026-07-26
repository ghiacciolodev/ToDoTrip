import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'map_pin.dart';

class MapRepository {
  MapRepository({required this.dio});

  final Dio dio;

  Future<List<MapPin>> pins(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/pins');
      return (response.data as List)
          .map((json) => MapPin.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<MapPin> createPin({
    required String tripId,
    required String name,
    required double latitude,
    required double longitude,
    required PinCategory category,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        '/trips/$tripId/pins',
        data: {
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'category': category.wire,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return MapPin.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deletePin(String tripId, String pinId) async {
    try {
      await dio.delete('/trips/$tripId/pins/$pinId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<MemberLocation>> locations(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/locations');
      return (response.data as List)
          .map((json) => MemberLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The caller is always the subject: the API takes the user from the token,
  /// so nobody can place someone else on the map.
  Future<void> shareLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    double? accuracyM,
  }) async {
    try {
      await dio.put(
        '/trips/$tripId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy_m': ?accuracyM,
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> stopSharing(String tripId) async {
    try {
      await dio.delete('/trips/$tripId/location');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
