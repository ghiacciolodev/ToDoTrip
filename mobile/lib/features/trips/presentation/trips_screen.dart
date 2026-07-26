import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/refresh_on_resume.dart';
import '../../../core/theme/colors.dart';
import '../data/trip.dart';
import '../providers.dart';
import 'widgets/trip_card.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tripsTitle)),
      // Someone else may have added a trip, or invited this user to one, while
      // the app was in the background: refetch on resume rather than trusting
      // whatever was on screen an hour ago.
      body: RefreshOnResume(
        onResume: () => ref.invalidate(tripsProvider),
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(tripsProvider.future),
          child: _buildBody(context, ref),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final list = trips.value;

    // Only the first load shows skeletons. Once there is data, a refresh
    // updates it in place instead of wiping the list.
    if (list == null) {
      if (trips.hasError) {
        return _ErrorState(
          message: '${trips.error}',
          onRetry: () => ref.invalidate(tripsProvider),
        );
      }
      return const _LoadingList();
    }

    if (list.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => TripCard(
        trip: list[index],
        // push, not go: the trip detail sits on top of the tab shell, so back
        // returns here instead of exiting the app.
        onTap: () => context.push('/trips/${list[index].id}'),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    // Skeletons rather than a spinner: the layout is already known, and showing
    // it makes the wait feel roughly half as long.
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // A scroll view even when empty, so pull-to-refresh still works here.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 88,
                  width: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).tripsEmptyTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).tripsEmptyBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted, height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => context.go('/add'),
                  child: Text(AppLocalizations.of(context).tripsEmptyAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context).commonTryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
