import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'item.dart';

class ItemRepository {
  ItemRepository({required this.dio});

  final Dio dio;

  Future<List<Item>> list(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/items');
      return (response.data as List)
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Item> create({
    required String tripId,
    required ItemType type,
    required String title,
    String? description,
    String? location,
    DateTime? startsAt,
    List<String> assignedTo = const [],
  }) async {
    try {
      final response = await dio.post(
        '/trips/$tripId/items',
        data: {
          'type': type == ItemType.event ? 'event' : 'task',
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (location != null && location.isNotEmpty) 'location': location,
          // Sent in UTC: the API stores timestamptz, and a trip can cross time
          // zones between planning and travelling.
          if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
          if (assignedTo.isNotEmpty) 'assigned_to': assignedTo,
        },
      );
      return Item.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Replaces the whole set: the caller sends who should be assigned now, not
  /// a delta, which keeps the client from having to track what changed.
  Future<Item> setAssignees({
    required String tripId,
    required String itemId,
    required List<String> assignedTo,
  }) async {
    try {
      final response = await dio.patch(
        '/trips/$tripId/items/$itemId',
        data: {'assigned_to': assignedTo},
      );
      return Item.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Item> setCompleted({
    required String tripId,
    required String itemId,
    required bool done,
  }) async {
    try {
      final path = '/trips/$tripId/items/$itemId/complete';
      final response = done ? await dio.post(path) : await dio.delete(path);
      return Item.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String tripId, String itemId) async {
    try {
      await dio.delete('/trips/$tripId/items/$itemId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
