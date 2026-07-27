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

/// An itinerary: one heading per day, and the day's events strung along a line.
///
/// The day used to be repeated on every card — three events on the twelfth said
/// "AUG 12" three times. Said once at the top, the events below it can shrink to
/// a time and a title, and a day reads as a day.
class _Agenda extends ConsumerWidget {
  const _Agenda({required this.tripId, required this.items});

  final String tripId;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = items.where((i) => i.type == ItemType.event).toList()
      // Chronological, the way an itinerary is read. Past days stay at the top
      // and go grey rather than being hidden: a trip is a short thing, and what
      // happened yesterday is part of reading it.
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));

    if (events.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.event_outlined,
        title: l10n.calendarEmptyTitle,
        subtitle: l10n.calendarEmptyBody,
      );
    }

    // The one event worth pointing at: the next one that has not happened yet.
    // Everything else on the screen is either done or far away.
    final now = DateTime.now();
    final next = events
        .where((e) => e.startsAt!.toLocal().isAfter(now))
        .firstOrNull;

    final days = <DateTime, List<Item>>{};
    for (final event in events) {
      final at = event.startsAt!.toLocal();
      days
          .putIfAbsent(DateTime(at.year, at.month, at.day), () => [])
          .add(event);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        for (final day in days.entries) ...[
          _DayHeading(day: day.key),
          const SizedBox(height: 8),
          _DayCard(tripId: tripId, events: day.value, next: next),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

/// "Today", with the date it actually is beside it.
///
/// The relative word leads because that is how people hold a trip in their head;
/// the absolute date follows for when it matters.
class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = day.difference(today).inDays;

    final (lead, trail) = switch (offset) {
      0 => (l10n.calendarToday, DateFormat('EEEE d MMMM').format(day)),
      1 => (l10n.calendarTomorrow, DateFormat('EEEE d MMMM').format(day)),
      -1 => (l10n.calendarYesterday, DateFormat('EEEE d MMMM').format(day)),
      _ => (
        toBeginningOfSentenceCase(DateFormat('EEEE').format(day)),
        DateFormat('d MMMM').format(day),
      ),
    };
    final past = offset < 0;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            lead,
            style: TextStyle(
              color: past ? AppColors.inkMuted : AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// One day's events, strung along a single line.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.tripId,
    required this.events,
    required this.next,
  });

  final String tripId;
  final List<Item> events;
  final Item? next;

  /// Where the dots sit, measured from the left edge of the card: padding, the
  /// time column, the gap, then the middle of the twelve-pixel gutter.
  static const _timeWidth = 48.0;
  static const _gutter = 12.0;
  static const _lineLeft = 14 + _timeWidth + _gutter + _gutter / 2 - 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: AppColors.ink.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          // Drawn first so the highlighted row paints over it. Only when there
          // is more than one event: a line through a single dot is a stub.
          if (events.length > 1)
            Positioned(
              left: _lineLeft,
              top: 24,
              bottom: 24,
              child: Container(width: 2, color: AppColors.border),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final event in events)
                _EventRow(
                  tripId: tripId,
                  item: event,
                  isNext: identical(event, next),
                  timeWidth: _timeWidth,
                  gutter: _gutter,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({
    required this.tripId,
    required this.item,
    required this.isNext,
    required this.timeWidth,
    required this.gutter,
  });

  final String tripId;
  final Item item;
  final bool isNext;
  final double timeWidth;
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = item.startsAt!.toLocal();
    final past = at.isBefore(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    // Three states, three weights. Past fades, next shouts, the rest sit still.
    final timeColour = past
        ? AppColors.inkMuted.withValues(alpha: 0.7)
        : (isNext ? scheme.onPrimaryContainer : AppColors.ink);
    final titleColour = past ? AppColors.inkMuted : AppColors.ink;

    return SwipeToDelete(
      id: item.id,
      onDelete: () => confirmDeleteItem(context, ref, tripId, item),
      child: Material(
        color: isNext
            ? scheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        child: InkWell(
          onLongPress: () => confirmDeleteItem(context, ref, tripId, item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: timeWidth,
                  child: Text(
                    DateFormat('HH:mm').format(at),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: timeColour,
                      fontSize: 14,
                      fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(
                  width: gutter,
                  child: Center(
                    child: _Dot(past: past, isNext: isNext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: titleColour,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (item.location?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        _MetaLine(
                          icon: Icons.place_outlined,
                          text: item.location!,
                        ),
                      ],
                      if (item.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
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
                if (isNext) ...[const SizedBox(width: 8), _Countdown(at: at)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bead on the timeline. Its size is the state: filled and large for the
/// next thing, hollow for what is still to come, grey and small for the past.
class _Dot extends StatelessWidget {
  const _Dot({required this.past, required this.isNext});

  final bool past;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (isNext) {
      return Container(
        height: 12,
        width: 12,
        margin: const EdgeInsets.only(top: 3),
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          // A white gap between the bead and the line, so the line reads as
          // passing behind it rather than into it.
          border: Border.all(color: AppColors.surface, width: 3),
        ),
      );
    }
    return Container(
      height: 8,
      width: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: past ? AppColors.border : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: past ? AppColors.border : primary, width: 2),
      ),
    );
  }
}

/// How long until the next event, when that is a number anybody cares about.
///
/// Nothing beyond a day: "in 3 days" on the only highlighted row of the screen
/// is noise, and the day heading already said it.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = at.difference(DateTime.now());
    // Rounded, not truncated. An event two hours away is two hours away, and
    // `inHours` on a duration a few microseconds short of it answers one.
    final minutes = (left.inSeconds / 60).round();
    final hours = (left.inMinutes / 60).round();
    final label = switch (0) {
      _ when left.inSeconds < 30 => l10n.calendarStartsNow,
      _ when minutes < 60 => l10n.calendarStartsInMinutes(minutes),
      _ when hours < 24 => l10n.calendarStartsInHours(hours),
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
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
