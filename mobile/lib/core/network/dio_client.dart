import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Builds the configured HTTP client.
Dio createDio({
  required TokenStorage storage,
  required Future<void> Function() onSessionExpired,
}) {
  final options = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
    // 4xx are handled as exceptions by the repositories, not swallowed here.
    validateStatus: (status) => status != null && status < 400,
  );

  final dio = Dio(options);
  final refreshClient = Dio(options);

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      refreshClient: refreshClient,
      onSessionExpired: onSessionExpired,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, requestHeader: false),
    );
  }

  return dio;
}