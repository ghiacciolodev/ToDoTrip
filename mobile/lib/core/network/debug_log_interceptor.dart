import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Request logging for debug builds, with credentials left out.
///
/// Dio's own LogInterceptor prints every body, which on the auth routes means
/// the plain password on the way in and the tokens on the way back. Those lines
/// land in the device log, where nothing later removes them and any crash or
/// analytics tool that reads logs would carry them off. Auth is therefore logged
/// by shape only: method, path, status.
class DebugLogInterceptor extends Interceptor {
  static bool _isSensitive(String path) => path.startsWith('/auth');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.path}');
    if (options.data != null && !_isSensitive(options.path)) {
      debugPrint('  ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    debugPrint('← ${response.statusCode} $path');
    if (!_isSensitive(path)) debugPrint('  ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    debugPrint('× ${err.response?.statusCode ?? err.type.name} $path');
    // The failure detail is what makes a log useful, but on auth it can echo
    // back what was sent, so only other routes print it.
    if (!_isSensitive(path) && err.response?.data != null) {
      debugPrint('  ${err.response?.data}');
    }
    handler.next(err);
  }
}
