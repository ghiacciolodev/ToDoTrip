import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/refresh_on_resume.dart';
import '../../../core/theme/colors.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../notifications/providers.dart';
import '../providers.dart';
import 'widgets/trip_card.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).tripsTitle),
        actions: const [NotificationBell()],
      ),
      // Someone else may have added a trip, or invited this user to one, while
      // the app was in the background: refetch on resume rather than trusting
      // whatever was on screen an hour ago.
      body: RefreshOnResume(
        onResume: () {
          ref.invalidate(tripsProvider);
          // Three hours in a pocket is exactly when the badge is wrong.
          ref.read(unreadCountProvider.notifier).refresh();
        },
        child: RefreshIndicator(
          onRefresh: () async {
            // The badge rides along: this screen has no websocket of its own,
            // so a pull is one of the few moments it can learn it is stale.
            ref.read(unreadCountProvider.notifier).refresh();
            ref.invalidate(tripsProvider);
            await ref.read(tripsProvider.future);
          },
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

    // Already ordered by the server, most recently active first.
    final archived = ref.watch(archivedTripsProvider).value ?? const [];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      // One more row at the end when there is an archive to open.
      itemCount: list.length + (archived.isEmpty ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        if (index == list.length) {
          return _ArchiveRow(count: archived.length);
        }
        return TripCard(
          trip: list[index],
          // push, not go: the trip detail sits on top of the tab shell, so back
          // returns here instead of exiting the app.
          onTap: () => context.push('/trips/${list[index].id}'),
        );
      },
    );
  }
}

/// The way into the archive, shown only when there is something in it.
class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.archive_outlined, color: AppColors.inkMuted),
        title: Text(
          AppLocalizations.of(context).tripsArchivedCount(count),
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        onTap: () => context.push('/archive'),
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
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        // The height and shape of a real card, so nothing jumps when the data
        // lands.
        height: 118,
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
          // Align, not a centred Column: only the height is constrained here,
          // so a Column left to itself shrinks to its widest line and the
          // Padding leaves it against the left edge.
          child: Align(
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).tripsEmptyTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).tripsEmptyBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      height: 1.4,
                    ),
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
          child: Align(
            alignment: const Alignment(0, -0.25),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
