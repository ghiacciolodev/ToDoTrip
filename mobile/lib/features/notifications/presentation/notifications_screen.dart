import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/money.dart';
import '../../../core/relative_time.dart';
import '../../../core/theme/avatar_color.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/notification.dart';
import '../providers.dart';

/// What happened while the phone was in a pocket.
///
/// Grouped by day like the agenda, because a feed with no dividers reads as one
/// undifferentiated wall the moment it is longer than a screen.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  /// Refetch, then mark read.
  ///
  /// The refetch is the important half. The feed provider is kept alive for the
  /// whole session, so without this the second visit renders the list as it was
  /// when the app started — which looked exactly like notifications never
  /// arriving until a restart.
  Future<void> _open() async {
    if (!mounted) return;
    ref.invalidate(notificationFeedProvider);
    try {
      await ref.read(notificationFeedProvider.future);
    } on Object {
      // A failed refetch shows the error state; nothing to mark read anyway.
      return;
    }
    await _markRead();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(notificationFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    await ref.read(notificationFeedProvider.notifier).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(notificationFeedProvider);
    final rows = feed.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (rows != null && rows.isNotEmpty)
            PopupMenuButton<_FeedAction>(
              onSelected: (action) => switch (action) {
                _FeedAction.markAllRead => _markRead(),
                _FeedAction.clearAll => _confirmClearAll(),
              },
              itemBuilder: (context) => [
                if (rows.any((row) => row.isUnread))
                  PopupMenuItem(
                    value: _FeedAction.markAllRead,
                    child: Text(l10n.notificationsMarkAllRead),
                  ),
                PopupMenuItem(
                  value: _FeedAction.clearAll,
                  child: Text(
                    l10n.notificationsClearAll,
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationFeedProvider);
          await ref.read(unreadCountProvider.notifier).refresh();
        },
        child: switch ((rows, feed.hasError)) {
          (null, true) => _Message(text: l10n.errorGeneric),
          (null, _) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          // Inside the RefreshIndicator too: an empty feed is exactly when
          // somebody pulls down to check whether it is really empty.
          ([], _) => const _EmptyState(),
          (final list?, _) => _Feed(
            rows: list,
            controller: _scroll,
            onDelete: _confirmDelete,
          ),
        },
      ),
    );
  }

  /// Long press, not swipe.
  ///
  /// Swiping is how everything else in the app deletes, but here the rows are
  /// the only thing on screen and a stray horizontal thumb would keep throwing
  /// them away.
  Future<void> _confirmDelete(AppNotification row) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.notificationDeleteTitle),
        content: Text(l10n.notificationDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notificationFeedProvider.notifier).remove(row);
  }

  Future<void> _confirmClearAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.notificationsClearAllTitle),
        content: Text(l10n.notificationsClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.notificationsClearAll,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notificationFeedProvider.notifier).clearAll();
  }
}

enum _FeedAction { markAllRead, clearAll }

class _Feed extends StatelessWidget {
  const _Feed({
    required this.rows,
    required this.controller,
    required this.onDelete,
  });

  final List<AppNotification> rows;
  final ScrollController controller;
  final ValueChanged<AppNotification> onDelete;

  @override
  Widget build(BuildContext context) {
    // Grouped as they come: the feed is already newest first, so a change of
    // day is simply the point where the previous row's date differs.
    final groups = <DateTime, List<AppNotification>>{};
    for (final row in rows) {
      final at = row.createdAt.toLocal();
      groups
          .putIfAbsent(DateTime(at.year, at.month, at.day), () => [])
          .add(row);
    }

    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final group in groups.entries) ...[
          _DayLabel(day: group.key),
          for (final row in group.value)
            _NotificationRow(notification: row, onDelete: () => onDelete(row)),
        ],
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = switch (day.difference(today).inDays) {
      0 => l10n.calendarToday,
      -1 => l10n.calendarYesterday,
      _ => DateFormat('d MMMM y').format(day),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification, required this.onDelete});

  final AppNotification notification;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actor = notification.actorName ?? l10n.commonSomeone;

    return Material(
      // Unread rows are tinted rather than dotted: a column of dots down an
      // already dense list is one more thing to look at, and the tint is read
      // without being looked at.
      color: notification.isUnread
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
          : AppColors.surface,
      child: InkWell(
        onTap: () {
          // Straight to the tab that answers it. Landing on the trip's default
          // tab would leave the reader hunting for the thing they were just
          // told about.
          context.push(
            '/trips/${notification.tripId}?tab=${notification.kind.tab}',
          );
        },
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColorFor(
                  notification.actorId ?? notification.tripId,
                ),
                child: Text(
                  initialsFor(actor),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sentence(l10n, notification, actor),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (notification.tripName != null) ...[
                          Flexible(
                            child: Text(
                              notification.tripName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Text(
                            '  ·  ',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        Text(
                          relativeTime(l10n, notification.createdAt),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Built here from raw facts, never read from the server.
  ///
  /// A sentence stored in the database would be written in whatever language
  /// the reader used that day, and changing language would leave the history
  /// behind in the old one.
  static String _sentence(
    AppLocalizations l10n,
    AppNotification row,
    String actor,
  ) {
    final amount = row.amountCents == null
        ? ''
        : Money(row.amountCents!).formatted;
    return switch (row.kind) {
      NotificationKind.expenseAdded => l10n.notificationExpenseAdded(
        actor,
        amount,
        row.description ?? '',
      ),
      NotificationKind.expenseDeleted => l10n.notificationExpenseDeleted(
        actor,
        row.description ?? '',
      ),
      NotificationKind.settlementReceived => l10n.notificationSettlement(
        actor,
        amount,
      ),
      NotificationKind.taskAssigned => l10n.notificationTaskAssigned(
        actor,
        row.title ?? '',
      ),
      NotificationKind.eventAdded => l10n.notificationEventAdded(
        actor,
        row.title ?? '',
      ),
      NotificationKind.memberJoined => l10n.notificationMemberJoined(actor),
      // A kind this build has never heard of, sent by a newer server. Better a
      // vague line than a gap in the feed.
      NotificationKind.unknown => l10n.notificationSomethingHappened(actor),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          // Align, not a centred Column. The ConstrainedBox only sets a minimum
          // height, so the width stays loose, the Column shrinks to its widest
          // line and the Padding drops it against the left edge — centring
          // inside a box narrower than the screen centres nothing.
          child: Align(
            // Slightly above centre: dead centre of the available space reads
            // as low, because the eye places the optical centre higher.
            alignment: const Alignment(0, -0.25),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      // Was AppColors.background — near-white on a white page,
                      // so the bell floated with nothing behind it.
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Not "no notifications", which reads like something failed.
                  Text(
                    l10n.notificationsEmptyTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notificationsEmptyBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkMuted),
        ),
      ),
    );
  }
}
