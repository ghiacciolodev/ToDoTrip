import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// Scaffold shared by the three top-level tabs.
///
/// Backed by StatefulShellRoute so each branch keeps its own navigation stack
/// and scroll position: switching tabs never rebuilds the list from scratch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      // Colours, height and label styling come from navigationBarTheme.
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab returns to the root of that branch, the
          // behaviour users expect from every native app.
          initialLocation: index == navigationShell.currentIndex,
        ),
        // German labels run about 30% longer than English, which is what breaks
        // a bar this narrow: the theme shows them at 11pt and the destinations
        // ellipsize rather than overflow.
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.luggage_outlined),
            selectedIcon: const Icon(Icons.luggage),
            label: l10n.navTrips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.navAdd,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
