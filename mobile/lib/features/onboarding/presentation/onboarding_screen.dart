import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/onboarding.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// What the app is, in four screens, before anybody is asked to sign up.
///
/// Shown once per device and skippable from the first page. It exists because
/// the sign-in screen alone cannot answer "what is this and why would I want an
/// account", and a person who has to guess that closes the app instead.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() =>
      ref.read(onboardingSeenProvider.notifier).markSeen();

  void _next(int total) {
    if (_page >= total - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final pages = <_Page>[
      _Page(
        icon: Icons.luggage_outlined,
        title: l10n.onboardTripsTitle,
        body: l10n.onboardTripsBody,
      ),
      _Page(
        icon: Icons.event_outlined,
        title: l10n.onboardPlanTitle,
        body: l10n.onboardPlanBody,
      ),
      _Page(
        icon: Icons.payments_outlined,
        title: l10n.onboardMoneyTitle,
        body: l10n.onboardMoneyBody,
      ),
      _Page(
        icon: Icons.groups_outlined,
        title: l10n.onboardTogetherTitle,
        body: l10n.onboardTogetherBody,
      ),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip stays on every page, not just the first: somebody who
            // started reading and changed their mind should not have to finish.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n.onboardSkip,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (index) => setState(() => _page = index),
                children: pages,
              ),
            ),
            _Dots(count: pages.length, current: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: FilledButton(
                onPressed: () => _next(pages.length),
                child: Text(last ? l10n.onboardStart : l10n.onboardNext),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: scheme.surface,
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 132,
            width: 132,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Where you are in the four, and how many there are left.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            // The current one stretches rather than only changing colour, so
            // the position reads without relying on hue.
            width: index == current ? 24 : 8,
            decoration: BoxDecoration(
              color: index == current ? scheme.primary : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
