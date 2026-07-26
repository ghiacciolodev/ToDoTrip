import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/storage/token_storage.dart';
import 'user.dart';

/// Talks to /auth. Converts Dio failures into ApiException so nothing
/// Dio-specific leaks into the UI layer.
class AuthRepository {
  AuthRepository({required this.dio, required this.storage});

  final Dio dio;
  final TokenStorage storage;

  /// Login and register do not carry a token, and must not trigger a refresh
  /// on 401: skipAuth tells the interceptor to stay out of the way.
  static final _noAuth = Options(extra: {AuthInterceptor.skipAuth: true});

  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
        options: _noAuth,
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: _noAuth,
      );
      await storage.save(
        access: response.data['access_token'] as String,
        refresh: response.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<User> me() async {
    try {
      final response = await dio.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Best effort: the server revokes the refresh token, but local tokens are
  /// cleared either way. A failed network call must never trap a user in a
  /// session they asked to end.
  Future<void> logout() async {
    final refresh = await storage.readRefresh();
    if (refresh != null) {
      try {
        await dio.post(
          '/auth/logout',
          data: {'refresh_token': refresh},
          options: _noAuth,
        );
      } on DioException {
        // Ignored deliberately.
      }
    }
    await storage.clear();
  }
}
