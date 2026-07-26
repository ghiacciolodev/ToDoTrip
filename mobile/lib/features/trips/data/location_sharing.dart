import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'map_repository.dart';

/// Why sharing is not running, when the switch cannot simply be on.
enum LocationBlock {
  /// The device has location services switched off entirely.
  servicesOff,

  /// Refused this time; asking again is allowed.
  denied,

  /// Refused permanently — only the system settings can undo it, so the UI
  /// offers a button that opens them instead of a prompt that never appears.
  deniedForever,
}

/// Publishes the device's position to one trip, while the map is on screen.
///
/// Foreground only, always. Background location would mean
/// ACCESS_BACKGROUND_LOCATION on Android — which needs a written justification
/// to Google Play and is often refused — and "Always" on iOS, which the system
/// re-confirms periodically with an alarming prompt. The trade is that you see
/// others only while they too have the map open, which is exactly when it is
/// useful.
class LocationSharer {
  LocationSharer({required this.tripId, required this.repository});

  final String tripId;
  final MapRepository repository;

  StreamSubscription<Position>? _subscription;
  DateTime? _lastSent;

  /// At most one PUT per this interval, however chatty the stream gets. A city
  /// walk emits far more often than anyone needs to be followed.
  static const _minInterval = Duration(seconds: 20);

  static const _settings = LocationSettings(
    // Not `best`: high-accuracy GPS burns battery for a difference invisible at
    // city zoom, where the marker is bigger than the error either way.
    accuracy: LocationAccuracy.medium,
    distanceFilter: 25,
  );

  bool get isSharing => _subscription != null;

  /// Starts sharing, or returns why it could not.
  ///
  /// Every refusal is a distinct state because each one needs a different
  /// answer from the UI: retry, open settings, or turn the device's location
  /// services back on.
  Future<LocationBlock?> start({required void Function(Position) onFix}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationBlock.servicesOff;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationBlock.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationBlock.denied;
    }

    await _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(locationSettings: _settings).listen(
      (position) {
        onFix(position);
        unawaited(_publish(position));
      },
      onError: (_) {},
    );
    return null;
  }

  /// Stops and tells the server to forget the position.
  ///
  /// The row is deleted server-side, so nobody keeps seeing a last known place
  /// after the switch is off. Nothing is sent when sharing was never started:
  /// leaving the map would otherwise fire a pointless DELETE every single time.
  Future<void> stop() async {
    if (_subscription == null) return;

    await _subscription?.cancel();
    _subscription = null;
    _lastSent = null;
    try {
      await repository.stopSharing(tripId);
    } on Exception {
      // Best effort: the server drops it on its own when the TTL runs out.
    }
  }

  Future<void> _publish(Position position) async {
    final now = DateTime.now();
    if (_lastSent != null && now.difference(_lastSent!) < _minInterval) return;
    _lastSent = now;

    try {
      await repository.shareLocation(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
      );
    } on Exception {
      // A dropped fix is not worth surfacing: the next one is 20 seconds away,
      // and the server expires the old one by itself.
      _lastSent = null;
    }
  }
}
