import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/notification.dart';
import 'data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(dio: ref.watch(dioProvider));
});

/// The number on the bell.
///
/// Its own provider, and its own request. It is refreshed when the app returns
/// to the foreground, when a websocket event arrives, and when something is
/// read — three moments the app already knows about, so there is nothing here
/// to poll.
class UnreadCount extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    // Dropped on sign-out, so the next person to use the phone does not inherit
    // a badge counting somebody else's notifications.
    ref.watch(authProvider);
    return ref.watch(notificationRepositoryProvider).unreadCount();
  }

  Future<void> refresh() async {
    state = AsyncData(
      await ref.read(notificationRepositoryProvider).unreadCount(),
    );
  }

  /// Drops the badge before the request goes out.
  ///
  /// A badge that stays red for half a second after the tap reads as broken,
  /// and the server is about to agree anyway.
  void clearOptimistically() => state = const AsyncData(0);

  void decrease(int by) {
    final current = state.value;
    if (current != null) state = AsyncData((current - by).clamp(0, current));
  }
}

final unreadCountProvider = AsyncNotifierProvider<UnreadCount, int>(
  UnreadCount.new,
);

/// The feed itself, one page at a time.
///
/// Keyset pagination: the cursor comes from the server and goes straight back,
/// so a notification arriving mid-scroll cannot shift the page boundaries and
/// show a row twice.
class NotificationFeed extends AsyncNotifier<List<AppNotification>> {
  String? _cursor;
  bool _loadingMore = false;

  bool get hasMore => _cursor != null;

  @override
  Future<List<AppNotification>> build() async {
    ref.watch(authProvider);
    final page = await ref.watch(notificationRepositoryProvider).page();
    _cursor = page.nextCursor;
    return page.items;
  }

  Future<void> loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .page(before: cursor);
      _cursor = page.nextCursor;
      state = AsyncData([...?state.value, ...page.items]);
    } finally {
      _loadingMore = false;
    }
  }

  /// Marks everything unread as read, locally first.
  ///
  /// Opening the screen is the act of reading it, so this runs on open rather
  /// than waiting for a button. The button exists too, for clearing the badge
  /// without reading anything.
  ///
  /// The badge is consulted as well as the loaded rows: deciding from the first
  /// page alone would leave a red dot over a screen that has nothing unread on
  /// it, which is precisely the state that reads as broken.
  Future<void> markAllRead() async {
    final rows = state.value ?? const <AppNotification>[];
    final badge = ref.read(unreadCountProvider).value ?? 0;
    if (!rows.any((row) => row.isUnread) && badge == 0) return;

    final now = DateTime.now();
    state = AsyncData([
      for (final row in rows) row.isUnread ? row.copyWith(readAt: now) : row,
    ]);
    ref.read(unreadCountProvider.notifier).clearOptimistically();

    // read-all rather than the ids on screen: anything older than the first
    // page is unread too, and the badge has already been set to zero.
    await ref.read(notificationRepositoryProvider).markAllRead();
    await ref.read(unreadCountProvider.notifier).refresh();
  }

  /// Removes one row. Local first, so the list closes under the finger.
  Future<void> remove(AppNotification row) async {
    state = AsyncData([
      for (final other in state.value ?? const <AppNotification>[])
        if (other.id != row.id) other,
    ]);
    if (row.isUnread) ref.read(unreadCountProvider.notifier).decrease(1);
    await ref.read(notificationRepositoryProvider).remove(row.id);
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    ref.read(unreadCountProvider.notifier).clearOptimistically();
    await ref.read(notificationRepositoryProvider).clear();
  }
}

final notificationFeedProvider =
    AsyncNotifierProvider<NotificationFeed, List<AppNotification>>(
      NotificationFeed.new,
    );
