import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/core/onboarding.dart';
import 'package:todotrip/features/onboarding/presentation/onboarding_screen.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The introduction is shown once per device, and the ways out of it are what
/// matter: somebody who has already dismissed it must never see it again, and
/// somebody halfway through must be able to leave.
void main() {
  Future<void> pump(WidgetTester tester, {required _RecordingSeen seen}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingSeenProvider.overrideWith(() => seen)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('it opens on the first page', (tester) async {
    await pump(tester, seen: _RecordingSeen());
    expect(find.text('One place per trip'), findsOne);
    expect(find.text('Next'), findsOne);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('the button becomes Get started on the last page', (
    tester,
  ) async {
    final seen = _RecordingSeen();
    await pump(tester, seen: seen);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('And where everyone is'), findsOne);
    expect(find.text('Get started'), findsOne);
    // Not yet: reaching the last page is not the same as finishing it.
    expect(seen.marked, isFalse);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(seen.marked, isTrue);
  });

  testWidgets('skip works from the first page', (tester) async {
    /// Somebody who already knows the app should not have to page through four
    /// screens to reach the sign-in form.
    final seen = _RecordingSeen();
    await pump(tester, seen: seen);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(seen.marked, isTrue);
  });

  testWidgets('skip is still there halfway through', (tester) async {
    /// Started reading and changed your mind is a normal thing to do.
    final seen = _RecordingSeen();
    await pump(tester, seen: seen);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsOne);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(seen.marked, isTrue);
  });

  testWidgets('every page says something different', (tester) async {
    /// Four screens that repeat themselves are three screens of friction.
    await pump(tester, seen: _RecordingSeen());
    final headings = <String>[];

    for (var i = 0; i < 4; i++) {
      headings.add(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .firstWhere((t) => t.length > 12),
      );
      if (i < 3) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }

    expect(headings.toSet().length, 4);
  });
}

/// Records the completion instead of touching shared_preferences.
class _RecordingSeen extends OnboardingSeen {
  bool marked = false;

  @override
  Future<bool> build() async => false;

  @override
  Future<void> markSeen() async {
    marked = true;
    state = const AsyncData(true);
  }
}
