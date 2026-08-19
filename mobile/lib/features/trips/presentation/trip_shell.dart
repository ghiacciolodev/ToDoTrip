import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/refresh_on_resume.dart';
import '../../../core/theme/colors.dart';
import '../data/map_pin.dart';
import '../data/trip_events.dart';
import '../providers.dart';
import 'add_expense_screen.dart';
import 'tabs/calendar_tab.dart';
import '../../notifications/providers.dart';
import 'tabs/expenses_tab.dart';
import 'tabs/group_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/tasks_tab.dart';
import 'widgets/add_item_sheet.dart';

/// Container for a single trip.
///
/// An IndexedStack driven by local state rather than a nested shell route: the
/// tabs here are views of one resource, not independent destinations, and this
/// keeps each tab's scroll position without a second router hierarchy. The trip
/// itself stays addressable at /trips/:tripId, which is what deep links need.
///
/// Every destination is one tap away: hiding one kind of content behind a
/// switch inside another tab made the to-dos cost two taps and put two
/// unrelated screens under one label.
///
/// The trip and its members are awaited once, here, so every tab below can
/// assume both are present.
class TripShell extends ConsumerStatefulWidget {
  const TripShell({super.key, required this.tripId, this.initialTab});

  final String tripId;

  /// Which tab to open on. Set by a notification, so tapping "Luca added an
  /// expense" lands on the money rather than the calendar. Out-of-range values
  /// fall back to the first tab: the parameter comes off a URL.
  final int? initialTab;

  @override
  ConsumerState<TripShell> createState() => _TripShellState();
}

class _TripShellState extends ConsumerState<TripShell> {
  late int _index = switch (widget.initialTab) {
    final tab? when tab >= 0 && tab < 5 => tab,
    _ => 0,
  };

  /// Owned here rather than inside TasksTab so the action button can create
  /// whichever kind of thing is currently on screen.
  TasksView _tasksView = TasksView.todo;

  /// Throttles per tab, so flicking through the bar does not fire a burst of
  /// identical requests.
  final _lastRefresh = <int, DateTime>{};
  static const _minInterval = Duration(seconds: 15);

  /// Rings when another member changes something, so this phone updates
  /// without waiting for a pull-to-refresh.
  late final TripEventsChannel _events;

  @override
  void initState() {
    super.initState();
    _events = TripEventsChannel(
      tripId: widget.tripId,
      storage: ref.read(tokenStorageProvider),
      onEvent: _onRemoteEvent,
      onReconnected: _refreshEverything,
      onTokenRejected: _rotateToken,
    )..start();
  }

  @override
  void dispose() {
    _events.dispose();
    super.dispose();
  }

  /// Any authenticated request makes the interceptor notice the expiry and
  /// rotate the token, so the socket reconnects with a fresh one instead of
  /// retrying the expired one until the backoff gives up.
  Future<void> _rotateToken() async {
    await ref.read(dioProvider).get('/auth/me');
  }

  /// One provider group per event type: the client re-runs GETs it already
  /// knows. Positions are the single exception — they arrive with their data,
  /// because two floats every twenty seconds are not worth a round trip each.
  void _onRemoteEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    // Most of these also wrote a notification row. The badge is refreshed from
    // the same signal rather than polled — the bell is one screen away.
    if (event['type'] != 'location.update' &&
        event['type'] != 'location.cleared') {
      ref.read(unreadCountProvider.notifier).refresh();
    }
    switch (event['type']) {
      case 'expenses.changed':
        invalidateMoney(ref, widget.tripId);
      case 'items.changed':
        ref.invalidate(itemsProvider(widget.tripId));
        ref.invalidate(checklistsProvider(widget.tripId));
      case 'members.changed':
        ref.invalidate(tripMembersProvider(widget.tripId));
        ref.invalidate(tripInvitesProvider(widget.tripId));
      case 'pins.changed':
        ref.invalidate(mapPinsProvider(widget.tripId));
      case 'location.update':
        _applyLocation(event);
      case 'location.cleared':
        _clearLocation(event['user_id'] as String?);
      case 'trip.changed':
        ref.invalidate(tripProvider(widget.tripId));
      case 'trip.deleted':
        // Staying here would mean a screen where every action answers 404.
        ref.invalidate(tripsProvider);
        context.go('/trips');
    }
  }

  void _applyLocation(Map<String, dynamic> event) {
    final userId = event['user_id'] as String?;
    final lat = (event['lat'] as num?)?.toDouble();
    final lng = (event['lng'] as num?)?.toDouble();
    final at = DateTime.tryParse('${event['at']}');
    if (userId == null || lat == null || lng == null || at == null) return;

    final locations = ref.read(memberLocationsProvider(widget.tripId));
    locations.value = {
      ...locations.value,
      userId: MemberLocation(
        userId: userId,
        latitude: lat,
        longitude: lng,
        accuracyM: (event['accuracy_m'] as num?)?.toDouble(),
        updatedAt: at,
        // The client never enforces the TTL — the server stops serving expired
        // rows — but the field is part of the model, so it is filled honestly.
        expiresAt: at.add(const Duration(minutes: 30)),
      ),
    };
  }

  void _clearLocation(String? userId) {
    if (userId == null) return;
    final locations = ref.read(memberLocationsProvider(widget.tripId));
    locations.value = {...locations.value}..remove(userId);
  }

  /// After a gap in the connection anything may have changed, so everything is
  /// refetched: recovering the missed events one by one is the kind of sync
  /// bookkeeping this design deliberately avoids.
  void _refreshEverything() {
    if (!mounted) return;
    ref.invalidate(tripProvider(widget.tripId));
    ref.invalidate(tripMembersProvider(widget.tripId));
    ref.invalidate(tripInvitesProvider(widget.tripId));
    ref.invalidate(itemsProvider(widget.tripId));
    ref.invalidate(checklistsProvider(widget.tripId));
    invalidateMoney(ref, widget.tripId);
  }

  /// Refetches what the given tab shows.
  ///
  /// Changes made by other members arrive only when asked for, so this runs on
  /// tab switch and on app resume — the two moments a user assumes they are
  /// looking at current data.
  void _refresh(int index, {bool force = false}) {
    final now = DateTime.now();
    final last = _lastRefresh[index];
    if (!force && last != null && now.difference(last) < _minInterval) return;
    _lastRefresh[index] = now;

    // Shared by every tab: expenses name the payer, tasks name an assignee.
    ref.invalidate(tripMembersProvider(widget.tripId));

    switch (index) {
      case 0:
        ref.invalidate(itemsProvider(widget.tripId));
      case 1:
        ref.invalidate(itemsProvider(widget.tripId));
        ref.invalidate(checklistsProvider(widget.tripId));
      case 2:
        invalidateMoney(ref, widget.tripId);
      case 3:
        ref.invalidate(mapPinsProvider(widget.tripId));
      case 4:
        ref.invalidate(tripProvider(widget.tripId));
        ref.invalidate(tripInvitesProvider(widget.tripId));
    }
  }

  void _onTabSelected(int index) {
    setState(() => _index = index);
    _refresh(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = ref.watch(tripProvider(widget.tripId));
    final members = ref.watch(tripMembersProvider(widget.tripId));

    // Only gate on the first load. Checking hasValue as well means a refresh
    // updates the content in place instead of replacing the whole screen with
    // a spinner and remounting every tab.
    final firstLoad =
        (trip.isLoading && !trip.hasValue) ||
        (members.isLoading && !members.hasValue);
    // Likewise for errors: a failed refresh should not discard data already on
    // screen, so this only fires when there is nothing to show.
    final fatalError =
        (!trip.hasValue ? trip.error : null) ??
        (!members.hasValue ? members.error : null);
    final ready = !firstLoad && fatalError == null;

    return Scaffold(
      appBar: AppBar(title: Text(trip.value?.name ?? l10n.tripFallbackName)),
      body: RefreshOnResume(
        onResume: () => _refresh(_index, force: true),
        child: switch ((firstLoad, fatalError)) {
          (true, _) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          (_, final Object e) => _TripError(
            message: '$e',
            onRetry: () => _refresh(_index, force: true),
          ),
          _ => IndexedStack(
            index: _index,
            children: [
              CalendarTab(tripId: widget.tripId),
              TasksTab(
                tripId: widget.tripId,
                view: _tasksView,
                onViewChanged: (v) => setState(() => _tasksView = v),
              ),
              ExpensesTab(tripId: widget.tripId),
              // isVisible, not mounted: the tab survives inside the
              // IndexedStack, but the GPS must stop the moment it is off screen.
              MapTab(tripId: widget.tripId, isVisible: _index == 3),
              GroupTab(tripId: widget.tripId),
            ],
          ),
        },
      ),

      // Contextual: one button that does the right thing for the tab in view.
      // Map and Group have none, because they have nothing to create yet and
      // their actions live inline in the cards.
      //
      // Gone entirely on an archived trip. The server refuses the write either
      // way, but offering a button whose only possible outcome is an error is
      // the thing this app keeps refusing to do.
      floatingActionButton: ready && !(trip.value?.isArchived ?? false)
          ? _buildFab()
          : null,

      // Colours, height and label styling come from navigationBarTheme.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: l10n.tabCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n.tabTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.tabMoney,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.tabMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.tabGroup,
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    final l10n = AppLocalizations.of(context);

    return switch (_index) {
      0 => FloatingActionButton.extended(
        onPressed: () =>
            showAddItemSheet(context, widget.tripId, AddKind.event),
        icon: const Icon(Icons.add),
        label: Text(l10n.fabEvent),
      ),
      // Follows the segmented control above it: a task in the to-do view, a
      // list in the lists view.
      1 => FloatingActionButton.extended(
        onPressed: () => showAddItemSheet(
          context,
          widget.tripId,
          _tasksView == TasksView.todo ? AddKind.task : AddKind.list,
        ),
        icon: const Icon(Icons.add),
        label: Text(_tasksView == TasksView.todo ? l10n.fabTask : l10n.fabList),
      ),
      2 => FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(tripId: widget.tripId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.fabExpense),
      ),
      _ => null,
    };
  }
}

class _TripError extends StatelessWidget {
  const _TripError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.inkMuted),
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
    );
  }
}
