import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../data/item.dart';
import '../../providers.dart';
import '../widgets/delete_actions.dart';
import '../widgets/tab_states.dart';

/// Everything with a time on it.
///
/// Events and tasks are one table on the server and arrive in one request; this
/// tab renders the events half of it.
class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(tripId));
    final list = items.value;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(itemsProvider(tripId)),
      child: switch ((list, items.hasError)) {
        (null, true) => ErrorState(
          message: '${items.error}',
          onRetry: () => ref.invalidate(itemsProvider(tripId)),
        ),
        (null, _) => const Center(child: CircularProgressIndicator.adaptive()),
        (final all?, _) => _Agenda(tripId: tripId, items: all),
      },
    );
  }
}

/// A flat agenda: each card carries its own date, so no day headers are needed
/// and the list stays one uninterrupted column.
class _Agenda extends ConsumerWidget {
  const _Agenda({required this.tripId, required this.items});

  final String tripId;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.every((i) => i.type != ItemType.event)) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.event_outlined,
        title: l10n.calendarEmptyTitle,
        subtitle: l10n.calendarEmptyBody,
      );
    }

    // Newest first. Swap the operands to put upcoming events at the top:
    //   a.startsAt!.compareTo(b.startsAt!)
    final events = items.where((i) => i.type == ItemType.event).toList()
      ..sort((a, b) => b.startsAt!.compareTo(a.startsAt!));

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) =>
          _EventCard(tripId: tripId, item: events[index]),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.tripId, required this.item});

  final String tripId;
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = item.startsAt!.toLocal();
    final past = item.startsAt!.isBefore(DateTime.now());

    // Muted colours chosen explicitly instead of wrapping the card in Opacity:
    // opacity fades text and background together and drops contrast below the
    // readable threshold. primaryDark on primaryTint sits at 6.4:1.
    final blockColour = past ? AppColors.background : AppColors.primaryTint;
    final blockText = past ? AppColors.inkMuted : AppColors.primaryDark;
    final titleColour = past ? AppColors.inkMuted : AppColors.ink;

    return SwipeToDelete(
      id: item.id,
      onDelete: () => confirmDeleteItem(context, ref, tripId, item),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: () => confirmDeleteItem(context, ref, tripId, item),
          // A spine down the left edge, so a scroll reads as a timeline rather
          // than a stack of unrelated boxes; grey once the event is behind us.
          // Drawn as a border rather than a sibling in a stretched Row: inside a
          // list the card has no height to stretch to, and asking for one throws
          // at layout time instead of rendering.
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: past ? AppColors.border : AppColors.primary,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateBlock(
                    at: local,
                    background: blockColour,
                    foreground: blockText,
                    outlined: past,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DayLine(at: local, past: past),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.25,
                            color: titleColour,
                          ),
                        ),
                        if (item.location != null &&
                            item.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _MetaLine(
                            icon: Icons.place_outlined,
                            text: item.location!,
                          ),
                        ],
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.description!,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
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

/// Month, day and time in one tile, so each card stands on its own and the list
/// needs no sticky headers to be readable.
class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.at,
    required this.background,
    required this.foreground,
    required this.outlined,
  });

  final DateTime at;
  final Color background;
  final Color foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: outlined ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(at).toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${at.day}',
            style: TextStyle(
              color: foreground,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          // A hairline separates the date from the time without a second colour.
          Container(
            height: 1,
            width: 24,
            color: foreground.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('HH:mm').format(at),
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The weekday, plus a badge when the date is one people think of by name.
class _DayLine extends StatelessWidget {
  const _DayLine({required this.at, required this.past});

  final DateTime at;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(at.year, at.month, at.day).difference(today).inDays;
    final badge = switch (days) {
      0 => AppLocalizations.of(context).calendarToday,
      1 => AppLocalizations.of(context).calendarTomorrow,
      _ => null,
    };

    return Row(
      children: [
        Text(
          DateFormat('EEEE').format(at).toUpperCase(),
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (badge != null && !past) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
