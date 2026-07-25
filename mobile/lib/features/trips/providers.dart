import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/trip.dart';
import 'data/trip_repository.dart';

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