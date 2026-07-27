import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/relative_time.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trip.dart';
import '../../data/trip_identity.dart';
import 'avatar_stack.dart';

/// One trip in the list.
///
/// Two zones. The head carries identity — the trip's own colour, washed out
/// behind a disc of the same colour that holds the icon — and the foot carries
/// state: who is in it, when it is, what it costs you. The saturated colour is
/// confined to the disc on purpose: eight trips are then distinguishable before
/// the name is read, without the list becoming a wall of colour.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final identity = TripIdentity.of(
      tripId: trip.id,
      icon: trip.icon,
      color: trip.color,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      // A shadow instead of the usual hairline: these cards are meant to read as
      // objects lying on the list, and the coloured head already gives them an
      // edge the border would only duplicate.
      elevation: 1.5,
      shadowColor: AppColors.ink.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Head(trip: trip, identity: identity),
            _Foot(trip: trip),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.trip, required this.identity});

  final Trip trip;
  final TripIdentity identity;

  @override
  Widget build(BuildContext context) {
    final description = trip.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Container(
      // A wash, not the colour itself: dark text on it keeps full contrast,
      // which is what buys the three levels of hierarchy on this card.
      color: identity.colour.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        // Without a description the row is a single line and centres on the
        // disc; with one it hangs from the top.
        crossAxisAlignment: hasDescription
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          _IconDisc(identity: identity),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 10),
          _StatusBadge(trip: trip),
        ],
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.identity});

  final TripIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(color: identity.colour, shape: BoxShape.circle),
      // Picking a different icon crossfades instead of cutting — the card is
      // usually on screen while that choice is being made.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          identity.icon,
          key: ValueKey(identity.icon.codePoint),
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Where the trip stands, or — once there is no longer a "when" worth naming —
/// when something last happened in it.
///
/// One slot rather than two: "Ended" on its own says nothing anyone acts on, and
/// a trip with no dates had no badge at all before.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, prominent) = switch (trip.stage) {
      TripStage.running => (
        trip.endDate == null
            ? l10n.tripStageNow
            : l10n.tripStageDayOf(trip.dayOfTrip, trip.totalDays),
        true,
      ),
      TripStage.upcoming => (
        switch (trip.daysUntilStart) {
          0 => l10n.tripStageToday,
          1 => l10n.tripStageTomorrow,
          final days => l10n.tripStageInDays(days),
        },
        true,
      ),
      // Nothing left to count down to: the useful question becomes whether
      // anyone is still doing anything here.
      TripStage.ended || TripStage.undated => (
        trip.lastActivityAt == null
            ? null
            : relativeTime(l10n, trip.lastActivityAt!),
        false,
      ),
    };
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: prominent ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: prominent ? AppColors.border : AppColors.inkMuted,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!prominent) ...[
            const Icon(Icons.schedule, size: 12, color: AppColors.inkMuted),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: prominent ? AppColors.ink : AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (trip.memberPreview.isNotEmpty) ...[
                  AvatarStack(
                    people: [
                      for (final member in trip.memberPreview)
                        AvatarPerson(id: member.id, name: member.displayName),
                    ],
                    total: trip.memberCount,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    _dateRange(context, trip),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BalanceChip(trip: trip),
        ],
      ),
    );
  }

  /// Collapses the range when both dates fall in the same month: "12 – 18 Aug"
  /// rather than "12 Aug – 18 Aug".
  static String _dateRange(BuildContext context, Trip trip) {
    final l10n = AppLocalizations.of(context);
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null && end == null) return l10n.tripNoDates;

    final dayMonth = DateFormat('d MMM');
    final full = DateFormat('d MMM y');

    if (start != null && end != null) {
      if (start.year == end.year && start.month == end.month) {
        return '${start.day} – ${full.format(end)}';
      }
      return '${dayMonth.format(start)} – ${full.format(end)}';
    }
    if (start != null) return l10n.tripDatesFrom(full.format(start));
    return l10n.tripDatesUntil(full.format(end!));
  }
}

/// What this trip costs you, or nothing at all when it has no expenses.
///
/// Shown only when there is something to say: a chip reading "Settled" on a trip
/// nobody has spent on is noise.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final cents = trip.myBalanceCents;
    if (cents == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    // Wording and sign, not colour alone: red and green carry no meaning for
    // roughly 8% of men.
    final (label, colour) = switch (cents) {
      0 => (l10n.moneySettledShort, AppColors.inkMuted),
      > 0 => (
        '+${Money(cents).formatted}',
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      _ => ('−${Money(cents).abs.formatted}', AppColors.terracotta),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colour,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
