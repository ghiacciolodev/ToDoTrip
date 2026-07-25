import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../data/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.luggage_outlined,
                    color: AppColors.primaryDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateRange(trip),
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  /// Collapses the range when both dates fall in the same month: "12 – 18 Aug"
  /// rather than "12 Aug – 18 Aug".
  static String _dateRange(Trip trip) {
    final start = trip.startDate;
    final end = trip.endDate;
    if (start == null && end == null) return 'No dates yet';

    final dayMonth = DateFormat('d MMM');
    final full = DateFormat('d MMM y');

    if (start != null && end != null) {
      if (start.year == end.year && start.month == end.month) {
        return '${start.day} – ${full.format(end)}';
      }
      return '${dayMonth.format(start)} – ${full.format(end)}';
    }
    if (start != null) return 'From ${full.format(start)}';
    return 'Until ${full.format(end!)}';
  }
}