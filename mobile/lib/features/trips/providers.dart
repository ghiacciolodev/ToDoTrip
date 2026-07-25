import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/trip.dart';
import 'data/trip_member.dart';
import 'data/trip_repository.dart';
import 'data/invite.dart';
import 'data/expense.dart';
import 'data/expense_repository.dart';

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

/// One trip, by id.
///
/// A family: Riverpod keeps one instance per tripId and disposes it when no
/// screen is watching, so visiting several trips does not accumulate stale
/// copies in memory.
final tripProvider = FutureProvider.family<Trip, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).byId(tripId);
});

/// Members of a trip.
///
/// Loaded once at the trip shell and shared by every tab: expenses show "paid
/// by Luca", tasks show an assignee, balances show names — the API returns only
/// UUIDs, and three tabs fetching the same list would mean three round trips
/// and three unsynchronised spinners.
final tripMembersProvider =
FutureProvider.family<List<TripMember>, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).members(tripId);
});

/// Members indexed by user id, for turning an id into a name at render time.
final memberLookupProvider =
Provider.family<Map<String, TripMember>, String>((ref, tripId) {
  final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
  return {for (final member in members) member.user.id: member};
});

/// Invites for a trip. Owner-only: the API answers 403 to everyone else, so
/// this is never watched unless the current user owns the trip.
final tripInvitesProvider =
FutureProvider.family<List<Invite>, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).invites(tripId);
});

/// The current user's membership in a trip, or null while members load.
///
/// Drives every owner-only affordance: showing a button the backend will
/// reject with 403 is worse than not showing it at all.
final myMembershipProvider =
Provider.family<TripMember?, String>((ref, tripId) {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return null;
  final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
  for (final member in members) {
    if (member.user.id == userId) return member;
  }
  return null;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(dio: ref.watch(dioProvider));
});

final expensesProvider =
FutureProvider.family<List<Expense>, String>((ref, tripId) {
  return ref.watch(expenseRepositoryProvider).list(tripId);
});

final balanceProvider =
FutureProvider.family<BalanceReport, String>((ref, tripId) {
  return ref.watch(expenseRepositoryProvider).balance(tripId);
});

/// Refreshes everything money-related after a change.
///
/// Expenses and balances are separate endpoints, so invalidating only the list
/// leaves the balance card showing figures from before the change. Every caller
/// that touches money goes through here rather than remembering both.
void invalidateMoney(WidgetRef ref, String tripId) {
  ref.invalidate(expensesProvider(tripId));
  ref.invalidate(balanceProvider(tripId));
}