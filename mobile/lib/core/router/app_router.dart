import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/trips/presentation/add_screen.dart';
import '../../features/trips/presentation/archived_trips_screen.dart';
import '../../features/trips/presentation/trip_settings_screen.dart';
import '../../features/trips/presentation/trip_shell.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../onboarding.dart';
import '../providers.dart';

/// Application routes.
///
/// The redirect derives navigation from session state instead of pushing and
/// popping on sign-in: whatever ends a session — an expired refresh token, a
/// revoked one — lands on the same screen, with no scattered navigation code.
final routerProvider = Provider<GoRouter>((ref) {
  // One GoRouter for the app's lifetime. Watching authProvider here would
  // rebuild the router on every change, recreating the whole navigator and
  // discarding screen state — including a half-typed form and its error.
  // refreshListenable re-runs the redirect instead, leaving widgets alone.
  final session = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());
  ref.listen(
    authProvider,
    (_, next) => session.value = next,
    fireImmediately: true,
  );
  ref.onDispose(session.dispose);

  // The introduction is device state, not session state, so it gets its own
  // listenable rather than being folded into the one above.
  final onboarding = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());
  ref.listen(
    onboardingSeenProvider,
    (_, next) => onboarding.value = next,
    fireImmediately: true,
  );
  ref.onDispose(onboarding.dispose);

  // Lets a route opt out of the tab shell and cover it entirely.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/trips',
    refreshListenable: Listenable.merge([session, onboarding]),
    redirect: (context, state) {
      final auth = session.value;
      final seen = onboarding.value;

      // Neither answer known yet on cold start: hold on the splash rather than
      // flashing sign-in at somebody who is in fact signed in, or the tour at
      // somebody who dismissed it months ago.
      if (auth.isLoading || seen.isLoading) return '/splash';

      final onOnboarding = state.matchedLocation == '/welcome';
      // Before the sign-in check, and only when signed out: the introduction
      // exists to answer "what is this" for somebody who has not decided to
      // make an account yet. Anybody already signed in has plainly decided.
      if (seen.value == false && auth.value == null) {
        return onOnboarding ? null : '/welcome';
      }

      final signedIn = auth.value != null;
      final onAuthScreen = state.matchedLocation == '/auth';
      final onSplash = state.matchedLocation == '/splash';

      if (!signedIn) return onAuthScreen ? null : '/auth';
      if (onAuthScreen || onSplash || onOnboarding) return '/trips';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/add', builder: (_, _) => const AddScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Declared after the shell so "/trips" still matches the branch above,
      // and attached to the root navigator so the trip detail covers the tab
      // bar: it is a separate context with its own tabs, entered and left with
      // back, not a fourth destination.
      GoRoute(
        path: '/trips/:tripId',
        parentNavigatorKey: rootNavigatorKey,
        // ?tab= lets a notification land on the part of the trip it is about,
        // instead of dropping the reader on the calendar to go hunting.
        builder: (_, state) => TripShell(
          tripId: state.pathParameters['tripId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? ''),
        ),
      ),

      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const NotificationsScreen(),
      ),

      // On the root navigator too: the profile is entered from settings and
      // left with back, not a fourth tab.
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/trips/:tripId/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) =>
            TripSettingsScreen(tripId: state.pathParameters['tripId']!),
      ),

      GoRoute(
        path: '/archive',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const ArchivedTripsScreen(),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
