import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/config.dart';
import '../../../core/storage/token_storage.dart';

/// The realtime bell for one trip.
///
/// The server never pushes data, only `{"type": "…changed"}`; on every ring the
/// shell invalidates the same providers pull-to-refresh already invalidates and
/// the client re-runs a GET it already knows. One behaviour, four triggers —
/// and when this channel is down the app degrades to exactly what it was
/// before the channel existed, which is why none of the existing refreshes
/// were removed.
class TripEventsChannel with WidgetsBindingObserver {
  TripEventsChannel({
    required this.tripId,
    required this.storage,
    required this.onEvent,
    required this.onReconnected,
  });

  final String tripId;
  final TokenStorage storage;

  /// The decoded event. Most carry only a type; live positions also carry
  /// their coordinates, which is the one thing this channel pushes rather than
  /// announces.
  final void Function(Map<String, dynamic> event) onEvent;

  /// The channel came back after dropping, or access was lost for good. Events
  /// may have been missed in between; the caller refetches everything rather
  /// than guessing which — recovering individual events is a sync problem this
  /// design exists to avoid.
  final VoidCallback onReconnected;

  WebSocket? _socket;
  Timer? _retry;
  int _attempts = 0;
  bool _disposed = false;
  bool _inBackground = false;
  bool _everConnected = false;

  /// Set on a 4403 close: no longer a member, so reconnecting would only be
  /// rejected again. The refetch shows the user what happened.
  bool _lostAccess = false;

  final _random = Random();

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    _socket?.close();
    _socket = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // iOS suspends sockets within seconds of backgrounding anyway; closing
    // eagerly saves battery, and the resume refetch covers whatever was missed.
    if (state == AppLifecycleState.paused) {
      _inBackground = true;
      _retry?.cancel();
      _socket?.close();
      _socket = null;
    } else if (state == AppLifecycleState.resumed && _inBackground) {
      _inBackground = false;
      _attempts = 0;
      _connect();
    }
  }

  Future<void> _connect() async {
    if (_disposed || _inBackground || _lostAccess) return;
    try {
      final token = await storage.readAccess();
      if (token == null || _disposed) return;

      final socket = await WebSocket.connect(
        '${AppConfig.wsBaseUrl}/trips/$tripId/events',
      );
      // Keeps proxies and NAT routers from reaping the connection as idle.
      socket.pingInterval = const Duration(seconds: 30);
      _socket = socket;

      // The token goes in the first frame, never in the URL: URLs end up in
      // server and proxy logs, tokens must not.
      socket.add(jsonEncode({'token': token}));
      socket.listen(
        _onMessage,
        onDone: () => _onClosed(socket),
        onError: (_) => _onClosed(socket),
        cancelOnError: true,
      );
    } on Exception {
      _scheduleRetry();
    }
  }

  void _onMessage(dynamic data) {
    if (_disposed) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(data as String);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final type = decoded['type'];
    if (type is! String) return;

    // The server acknowledges a successful handshake, which is what lets a
    // reconnection be told apart from the first connect.
    if (type == 'connected') {
      _attempts = 0;
      if (_everConnected) onReconnected();
      _everConnected = true;
      return;
    }
    onEvent(decoded);
  }

  void _onClosed(WebSocket socket) {
    // A stale callback from a socket that was already replaced must not
    // schedule retries against the live one.
    if (!identical(socket, _socket)) return;
    _socket = null;
    if (_disposed || _inBackground) return;

    if (socket.closeCode == 4403) {
      _lostAccess = true;
      onReconnected();
      return;
    }
    _scheduleRetry();
  }

  /// Exponential backoff with jitter: 1s, 2s, 4s, 8s, 16s, then 30s. Mobile
  /// networks drop constantly — metro, lift, Wi-Fi handover — and hammering a
  /// dead link helps nobody.
  void _scheduleRetry() {
    if (_disposed || _inBackground || _lostAccess) return;
    final seconds = min(30, 1 << min(_attempts, 5));
    _attempts++;
    final jitter = Duration(milliseconds: _random.nextInt(500));
    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds) + jitter, _connect);
  }
}
