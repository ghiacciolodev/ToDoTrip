import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'notification.dart';

/// Talks to /notifications. Converts Dio failures into ApiException so nothing
/// Dio-specific leaks into the UI layer.
class NotificationRepository {
  NotificationRepository({required this.dio});

  final Dio dio;

  Future<NotificationPage> page({String? before, int limit = 30}) async {
    try {
      final response = await dio.get(
        '/notifications',
        queryParameters: {'limit': limit, if (before != null) 'before': before},
      );
      return NotificationPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Just the number. Its own endpoint because it is asked for on every cold
  /// start and every return to the foreground, and pulling thirty full
  /// notifications to render a dot would be most of the app's traffic.
  Future<int> unreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');
      return response.data['count'] as int;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> markRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await dio.post('/notifications/read', data: {'ids': ids});
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> clear() async {
    try {
      await dio.delete('/notifications');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
