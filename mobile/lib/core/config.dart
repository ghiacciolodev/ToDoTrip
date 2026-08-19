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

  /// Same origin as [apiBaseUrl] with the websocket scheme: http becomes ws,
  /// https becomes wss.
  static String get wsBaseUrl => apiBaseUrl.replaceFirst('http', 'ws');

  /// Where map tiles come from.
  ///
  /// OpenStreetMap's own servers by default, which is right for one developer
  /// and wrong for a published build: their usage policy does not cover an app
  /// handed to an unknown number of people. A release meant for other people
  /// sets this to a provider with a plan behind it — one `--dart-define`, plus
  /// whatever key that provider's URL template expects.
  static String get mapTileUrl {
    const override = String.fromEnvironment('MAP_TILE_URL');
    return override.isNotEmpty
        ? override
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Who to credit under the map.
  ///
  /// Travels with [mapTileUrl] rather than being hardcoded: crediting
  /// OpenStreetMap under somebody else's tiles would be wrong twice over —
  /// unfair to the provider whose licence requires attribution, and a false
  /// statement about where the data came from.
  static String get mapAttribution {
    const override = String.fromEnvironment('MAP_TILE_ATTRIBUTION');
    return override.isNotEmpty ? override : 'OpenStreetMap contributors';
  }

  /// True while the map is still pointing at OpenStreetMap's public servers.
  ///
  /// Used to keep a build that forgot to set a provider out of other people's
  /// hands, rather than discovering it from an angry email.
  static bool get usesPublicOsmTiles =>
      const String.fromEnvironment('MAP_TILE_URL').isEmpty;
}
