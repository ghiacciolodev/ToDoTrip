import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers.dart';
import 'widgets/trip_card.dart';

/// Trips that have been put away.
///
/// Its own screen rather than a section at the bottom of the list: most people
/// have none, and a heading that is empty for a year is worse than a door that
/// only appears when there is something behind it.
class ArchivedTripsScreen extends ConsumerWidget {
  const ArchivedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(archivedTripsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripsArchivedTitle)),
      body: switch (trips) {
        null => const Center(child: CircularProgressIndicator()),
        [] => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.tripsArchivedEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ),
        ),
        // Still fully openable: being able to go back and look is the whole
        // reason an archived trip is kept rather than deleted.
        final list => RefreshIndicator(
          onRefresh: () => ref.refresh(archivedTripsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, index) => TripCard(
              trip: list[index],
              onTap: () => context.push('/trips/${list[index].id}'),
            ),
          ),
        ),
      },
    );
  }
}
