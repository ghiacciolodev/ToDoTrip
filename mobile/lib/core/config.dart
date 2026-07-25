import 'dart:io';

import 'package:flutter/foundation.dart';

/// Environment configuration.
abstract final class AppConfig {
  /// Base URL of the API.
  ///
  /// localhost means the device itself, not the development machine: the
  /// Android emulator reaches the host through 10.0.2.2, and a physical phone
  /// needs the machine's LAN address (plus a Windows firewall rule for the port).
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }
}