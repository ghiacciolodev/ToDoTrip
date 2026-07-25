import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the access token, and transparently renews it on 401.
///
/// The backend issues short-lived access tokens and rotates refresh tokens on
/// every use, so two parallel 401s must not trigger two refreshes: the second
/// would present an already-rotated token and get the user logged out. The
/// single-flight [_refreshing] future makes concurrent callers share one call.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshClient,
    required this.onSessionExpired,
  });

  final TokenStorage storage;

  /// A bare Dio without this interceptor: refreshing through the main client
  /// would recurse on its own 401.
  final Dio refreshClient;

  final Future<void> Function() onSessionExpired;

  Future<String?>? _refreshing;

  /// Marks requests that must not carry a token (login, register, refresh).
  static const skipAuth = 'skipAuth';
  static const _retried = 'retried';

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    if (options.extra[skipAuth] != true) {
      final token = await storage.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final options = err.requestOptions;
    final retryable = err.response?.statusCode == 401 &&
        options.extra[skipAuth] != true &&
        options.extra[_retried] != true;

    if (!retryable) return handler.next(err);

    final token = await (_refreshing ??= _refresh());

    if (token == null) {
      await onSessionExpired();
      return handler.next(err);
    }

    // Replay the original request once, with the new token.
    options.extra[_retried] = true;
    options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await refreshClient.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refresh() async {
    try {
      final refreshToken = await storage.readRefresh();
      if (refreshToken == null) return null;

      final response = await refreshClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {skipAuth: true}),
      );

      final access = response.data['access_token'] as String;
      await storage.save(
        access: access,
        refresh: response.data['refresh_token'] as String,
      );
      return access;
    } on DioException {
      await storage.clear();
      return null;
    } finally {
      // Release the slot so a later expiry can refresh again.
      _refreshing = null;
    }
  }
}