import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/relative_time.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trip.dart';
import '../../data/trip_identity.dart';
import 'avatar_stack.dart';
import 'progress_ring.dart';

/// One trip in the list.
///
/// One anatomy, shared with everything else that scrolls in this app: a circle
/// on the left carrying identity and state, the name in the middle, the state
/// on the right. The circle is a ring around the trip's icon, filled as the trip
/// goes by — the same drawing a checklist uses for its items, so "three days
/// into seven" and "three things left" read as the same kind of fact.
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
      // A shadow rather than the usual hairline: these read as objects lying on
      // the list, and a border would flatten them back into rows of a table.
      elevation: 1.5,
      shadowColor: AppColors.ink.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              _Identity(trip: trip, identity: identity),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusBadge(trip: trip),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Meta(trip: trip),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon in its colour, inside a ring that shows how far along the trip is.
class _Identity extends StatelessWidget {
  const _Identity({required this.trip, required this.identity});

  final Trip trip;
  final TripIdentity identity;

  @override
  Widget build(BuildContext context) {
    // Only a running trip has a fraction to draw. Everything else gets the bare
    // track, which still reads as the same object rather than a different one.
    final progress = trip.stage == TripStage.running && trip.endDate != null
        ? trip.dayOfTrip / trip.totalDays
        : null;

    return ProgressRing(
      size: 52,
      stroke: 3,
      colour: identity.colour,
      value: progress,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: identity.colour,
          shape: BoxShape.circle,
        ),
        // Picking a different icon crossfades instead of cutting — the card is
        // usually on screen while that choice is being made.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            identity.icon,
            key: ValueKey(identity.icon.codePoint),
            color: Colors.white,
            size: 21,
          ),
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
      // anyone is still doing anything in there.
      TripStage.ended || TripStage.undated => (
        trip.lastActivityAt == null
            ? null
            : relativeTime(l10n, trip.lastActivityAt!),
        false,
      ),
    };
    if (label == null) return const SizedBox.shrink();

    if (!prominent) {
      // Cold information: no pill around it, just the clock and the words.
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.inkMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Faces, dates and money on one line, in that order: who, when, how much.
class _Meta extends StatelessWidget {
  const _Meta({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (trip.memberPreview.isNotEmpty) ...[
          AvatarStack(
            people: [
              for (final member in trip.memberPreview)
                AvatarPerson(id: member.id, name: member.displayName),
            ],
            total: trip.memberCount,
            size: 24,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            _dateRange(context, trip),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ),
        _Balance(trip: trip),
      ],
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

    if (start != null && end != null) {
      if (start.year == end.year && start.month == end.month) {
        return '${start.day} – ${dayMonth.format(end)}';
      }
      return '${dayMonth.format(start)} – ${dayMonth.format(end)}';
    }
    if (start != null) return l10n.tripDatesFrom(dayMonth.format(start));
    return l10n.tripDatesUntil(dayMonth.format(end!));
  }
}

/// What this trip costs you, or nothing at all when it has no expenses.
///
/// Shown only when there is something to say: "Settled" on a trip nobody has
/// spent on is a claim about money that does not exist.
class _Balance extends StatelessWidget {
  const _Balance({required this.trip});

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
        '+${Money(cents).formattedIn(trip.baseCurrency)}',
        AppColors.primaryDark,
      ),
      _ => (
        '−${Money(cents).abs.formattedIn(trip.baseCurrency)}',
        AppColors.terracotta,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(left: 8),
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
