import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import 'data/trip.dart';
import 'data/trip_member.dart';
import 'data/trip_repository.dart';
import 'data/invite.dart';
import 'data/expense.dart';
import 'data/expense_repository.dart';
import 'data/settlement.dart';
import 'data/item.dart';
import 'data/item_repository.dart';
import 'data/checklist.dart';
import 'data/checklist_repository.dart';
import 'data/map_pin.dart';
import 'data/map_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(dio: ref.watch(dioProvider));
});

/// The signed-in user's trips.
///
/// Depends on authProvider so the list is dropped on sign-out: without that,
/// the next user to sign in on the same device would briefly see the previous
/// one's trips from cache.
final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(tripRepositoryProvider).list();
});

/// Trips that have been put away. A separate request, made only when the
/// archive is opened: most people have none, and nobody scrolling their live
/// trips is waiting on it.
final archivedTripsProvider = FutureProvider<List<Trip>>((ref) async {
  ref.watch(authProvider);
  return ref.watch(tripRepositoryProvider).list(archived: true);
});

/// One trip, by id.
///
/// A family: Riverpod keeps one instance per tripId and disposes it when no
/// screen is watching, so visiting several trips does not accumulate stale
/// copies in memory.
final tripProvider = FutureProvider.family<Trip, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).byId(tripId);
});

/// Everyone the trip knows about, including people who have left.
///
/// Loaded once at the trip shell and shared by every tab: expenses show "paid
/// by Luca", tasks show an assignee, balances show names — the API returns only
/// UUIDs, and three tabs fetching the same list would mean three round trips
/// and three unsynchronised spinners.
///
/// Former members are in here on purpose, so their name still resolves beside
/// the expenses they took part in. Use [activeMembersProvider] wherever people
/// are picked or counted.
final tripMembersProvider = FutureProvider.family<List<TripMember>, String>((
  ref,
  tripId,
) {
  return ref.watch(tripRepositoryProvider).members(tripId);
});

/// Who is in the trip right now.
///
/// The list every screen that offers a choice must use: assigning a task to
/// someone who left, or splitting a bill with them, is rejected by the API.
final activeMembersProvider = Provider.family<List<TripMember>, String>((
  ref,
  tripId,
) {
  final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
  return [
    for (final member in members)
      if (!member.hasLeft) member,
  ];
});

/// Members indexed by user id, for turning an id into a name at render time.
///
/// Built from the full list, former members included: that is the whole point of
/// a lookup — an id from an old expense must still find a name.
final memberLookupProvider = Provider.family<Map<String, TripMember>, String>((
  ref,
  tripId,
) {
  final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
  return {for (final member in members) member.user.id: member};
});

/// Invites for a trip. Owner-only: the API answers 403 to everyone else, so
/// this is never watched unless the current user owns the trip.
final tripInvitesProvider = FutureProvider.family<List<Invite>, String>((
  ref,
  tripId,
) {
  return ref.watch(tripRepositoryProvider).invites(tripId);
});

/// The current user's membership in a trip, or null while members load.
///
/// Drives every owner-only affordance: showing a button the backend will
/// reject with 403 is worse than not showing it at all.
final myMembershipProvider = Provider.family<TripMember?, String>((
  ref,
  tripId,
) {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return null;
  // Active only: a former membership must not keep granting affordances.
  for (final member in ref.watch(activeMembersProvider(tripId))) {
    if (member.user.id == userId) return member;
  }
  return null;
});

/// The currency a trip's amounts are written in.
///
/// Its own provider so a single row can ask for the symbol without depending on
/// the whole trip object. Euro while the trip is still loading: a symbol that
/// settles a frame later is better than an amount that appears a frame later.
///
/// The trip's current currency, not the one frozen on each expense. That is the
/// behaviour the settings screen promises — changing it renames, it does not
/// convert — and it was a promise the app did not keep while the euro sign was
/// hardcoded.
final tripCurrencyProvider = Provider.family<String, String>((ref, tripId) {
  return ref.watch(tripProvider(tripId)).value?.baseCurrency ?? 'EUR';
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(dio: ref.watch(dioProvider));
});

/// A trip's expenses, one page at a time.
///
/// The only list in the app without a natural ceiling: a plan has as many
/// entries as the group bothers to write, but expenses grow with every coffee.
///
/// Keyset pagination rather than offsets: the cursor comes from the server and
/// goes straight back, so an expense added mid-scroll cannot shift the page
/// boundaries and show a row twice.
class ExpenseList extends AsyncNotifier<List<Expense>> {
  ExpenseList(this.tripId);

  final String tripId;

  String? _cursor;
  bool _loadingMore = false;

  /// How many the trip has, not how many are loaded.
  ///
  /// Comes from the server: counting what is on screen gives a figure that
  /// grows as you scroll, which is worse than no figure at all.
  int total = 0;

  bool get hasMore => _cursor != null;

  @override
  Future<List<Expense>> build() async {
    final page = await ref.watch(expenseRepositoryProvider).list(tripId);
    _cursor = page.nextCursor;
    total = page.total;
    return page.items;
  }

  /// Fetches the next page and appends it.
  ///
  /// A failure here leaves the list exactly as it was rather than replacing a
  /// screen full of expenses with an error: the cursor is kept, so scrolling
  /// again or pulling to refresh retries.
  Future<void> loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(expenseRepositoryProvider)
          .list(tripId, before: cursor);
      _cursor = page.nextCursor;
      total = page.total;
      state = AsyncData([...?state.value, ...page.items]);
    } on ApiException {
      // Swallowed on purpose. Nothing called this: the list scrolled.
    } finally {
      _loadingMore = false;
    }
  }
}

final expensesProvider =
    AsyncNotifierProvider.family<ExpenseList, List<Expense>, String>(
      ExpenseList.new,
    );

final balanceProvider = FutureProvider.family<BalanceReport, String>((
  ref,
  tripId,
) {
  return ref.watch(expenseRepositoryProvider).balance(tripId);
});

/// Repayments recorded between members.
///
/// Shown alongside the expenses because they move the balances just as much: a
/// repayment that survives the expense it was made against is otherwise a change
/// in the figures with nothing on screen to explain it.
final settlementsProvider = FutureProvider.family<List<Settlement>, String>((
  ref,
  tripId,
) {
  return ref.watch(expenseRepositoryProvider).listSettlements(tripId);
});

/// Refreshes everything money-related after a change.
///
/// Expenses, repayments and balances are three separate endpoints, so
/// invalidating one leaves the others showing figures from before the change.
/// Every caller that touches money goes through here rather than remembering
/// all three.
void invalidateMoney(WidgetRef ref, String tripId) {
  ref.invalidate(expensesProvider(tripId));
  ref.invalidate(settlementsProvider(tripId));
  ref.invalidate(balanceProvider(tripId));
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(dio: ref.watch(dioProvider));
});

/// Every item of a trip, events and tasks together.
///
/// One request rather than two: they are one table on the server, and the
/// segmented control is a filter over this list, not a separate resource.
final itemsProvider = FutureProvider.family<List<Item>, String>((ref, tripId) {
  return ref.watch(itemRepositoryProvider).list(tripId);
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(dio: ref.watch(dioProvider));
});

/// The checklists of a trip, entries included.
///
/// The single source for both the cards and the screen a card opens: the API
/// inlines the entries, so an open list stays in step with a refresh without a
/// second provider to keep synchronised.
final checklistsProvider = FutureProvider.family<List<Checklist>, String>((
  ref,
  tripId,
) {
  return ref.watch(checklistRepositoryProvider).list(tripId);
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(dio: ref.watch(dioProvider));
});

/// Saved places. Durable group data, so it lives behind a GET like everything
/// else; the socket only says when to re-run it.
final mapPinsProvider = FutureProvider.family<List<MapPin>, String>((
  ref,
  tripId,
) {
  return ref.watch(mapRepositoryProvider).pins(tripId);
});

/// Live positions, keyed by user id.
///
/// A ValueNotifier rather than a provider holding the state: positions change
/// every twenty seconds per moving member, and only the layer drawing the
/// avatars may rebuild that often. Tiles and pins listen to nothing here, so a
/// fix never touches them.
final memberLocationsProvider =
    Provider.family<ValueNotifier<Map<String, MemberLocation>>, String>((
      ref,
      tripId,
    ) {
      final locations = ValueNotifier<Map<String, MemberLocation>>(const {});
      ref.onDispose(locations.dispose);
      return locations;
    });

/// One checklist, or null once it has been deleted — by anyone.
final checklistProvider =
    Provider.family<Checklist?, ({String tripId, String checklistId})>((
      ref,
      key,
    ) {
      final lists = ref.watch(checklistsProvider(key.tripId)).value ?? const [];
      for (final list in lists) {
        if (list.id == key.checklistId) return list;
      }
      return null;
    });
