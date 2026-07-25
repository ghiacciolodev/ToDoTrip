import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/refresh_on_resume.dart';
import '../../../core/theme/colors.dart';
import '../data/item.dart';
import '../providers.dart';
import 'add_expense_screen.dart';
import 'tabs/expenses_tab.dart';
import 'tabs/group_tab.dart';
import 'tabs/plan_tab.dart';
import 'widgets/add_item_sheet.dart';

/// Container for a single trip.
///
/// An IndexedStack driven by local state rather than a nested shell route: the
/// tabs here are views of one resource, not independent destinations, and this
/// keeps each tab's scroll position without a second router hierarchy. The trip
/// itself stays addressable at /trips/:tripId, which is what deep links need.
///
/// The trip and its members are awaited once, here, so every tab below can
/// assume both are present.
class TripShell extends ConsumerStatefulWidget {
  const TripShell({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripShell> createState() => _TripShellState();
}

class _TripShellState extends ConsumerState<TripShell> {
  int _index = 0;

  /// Owned here rather than inside PlanTab so the action button can create
  /// whichever kind of item is currently on screen.
  ItemType _planView = ItemType.event;

  /// Throttles per tab, so flicking through the bar does not fire a burst of
  /// identical requests.
  final _lastRefresh = <int, DateTime>{};
  static const _minInterval = Duration(seconds: 15);

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
        invalidateMoney(ref, widget.tripId);
      case 2:
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
    final trip = ref.watch(tripProvider(widget.tripId));
    final members = ref.watch(tripMembersProvider(widget.tripId));

    // Only gate on the first load. Checking hasValue as well means a refresh
    // updates the content in place instead of replacing the whole screen with
    // a spinner and remounting every tab.
    final firstLoad = (trip.isLoading && !trip.hasValue) ||
        (members.isLoading && !members.hasValue);
    // Likewise for errors: a failed refresh should not discard data already on
    // screen, so this only fires when there is nothing to show.
    final fatalError = (!trip.hasValue ? trip.error : null) ??
        (!members.hasValue ? members.error : null);
    final ready = !firstLoad && fatalError == null;

    return Scaffold(
      appBar: AppBar(title: Text(trip.value?.name ?? 'Trip')),
      body: RefreshOnResume(
        onResume: () => _refresh(_index, force: true),
        child: switch ((firstLoad, fatalError)) {
          (true, _) => const Center(child: CircularProgressIndicator.adaptive()),
          (_, final Object e) => _TripError(
            message: '$e',
            onRetry: () => _refresh(_index, force: true),
          ),
          _ => IndexedStack(
            index: _index,
            children: [
              PlanTab(
                tripId: widget.tripId,
                view: _planView,
                onViewChanged: (v) => setState(() => _planView = v),
              ),
              ExpensesTab(tripId: widget.tripId),
              GroupTab(tripId: widget.tripId),
            ],
          ),
        },
      ),

      // Contextual: one button that does the right thing for the tab in view.
      // Group has no action button because its actions live inline in the cards.
      floatingActionButton: ready ? _buildFab() : null,

      // Colours, height and label styling come from navigationBarTheme.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Group',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    return switch (_index) {
      0 => FloatingActionButton.extended(
        onPressed: () => showAddItemSheet(context, widget.tripId, _planView),
        icon: const Icon(Icons.add),
        label: Text(_planView == ItemType.event ? 'Event' : 'Task'),
      ),
      1 => FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(tripId: widget.tripId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}