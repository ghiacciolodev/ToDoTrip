import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/trips/presentation/add_screen.dart';
import '../../features/trips/presentation/trip_shell.dart';
import '../../features/trips/presentation/trips_screen.dart';
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

  // Lets a route opt out of the tab shell and cover it entirely.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/trips',
    refreshListenable: session,
    redirect: (context, state) {
      final auth = session.value;

      // Session still unknown on cold start: hold on the splash rather than
      // flashing sign-in at a user who is in fact signed in.
      if (auth.isLoading) return '/splash';

      final signedIn = auth.value != null;
      final onAuthScreen = state.matchedLocation == '/auth';
      final onSplash = state.matchedLocation == '/splash';

      if (!signedIn) return onAuthScreen ? null : '/auth';
      if (onAuthScreen || onSplash) return '/trips';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),

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
        builder: (_, state) =>
            TripShell(tripId: state.pathParameters['tripId']!),
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
