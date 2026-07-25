import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../providers.dart';

/// Application routes.
///
/// The redirect derives navigation from session state instead of pushing and
/// popping on login: whatever ends a session — an expired refresh token, a
/// revoked one — lands on the same screen, with no scattered navigation code.
final routerProvider = Provider<GoRouter>((ref) {
  // One GoRouter for the app's lifetime. Watching authProvider here would
  // rebuild the router on every change, recreating the whole navigator and
  // discarding screen state — including a half-typed form and its error.
  // refreshListenable re-runs the redirect instead, leaving widgets alone.
  final session = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());
  ref.listen(authProvider, (_, next) => session.value = next, fireImmediately: true);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: '/trips',
    refreshListenable: session,
    redirect: (context, state) {
      final auth = session.value;

      // Session still unknown on cold start: hold on the splash rather than
      // flashing login at a user who is in fact signed in.
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
      GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
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