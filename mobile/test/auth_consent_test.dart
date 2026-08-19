import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/core/providers.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/auth/presentation/auth_screen.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// Records what it was asked to do, and refuses nothing: the point is whether
/// the form lets the request out at all.
class _RecordingAuth extends AuthNotifier {
  int registrations = 0;

  @override
  Future<User?> build() async => null;

  @override
  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    registrations++;
  }

  @override
  Future<void> login(String email, String password) async {}
}

void main() {
  late _RecordingAuth auth;

  Future<void> pump(WidgetTester tester) async {
    auth = _RecordingAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => auth)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> switchToRegister(WidgetTester tester) async {
    final toggle = find.text("Don't have an account? Sign up");
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }

  /// The form is taller than the test viewport once the consent row is there,
  /// so anything below the fold has to be scrolled to before it can be tapped.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillTheForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Mario');
    await tester.enterText(find.byType(TextFormField).at(1), 'mario@test.it');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
  }

  testWidgets('signing in is not asked to accept anything', (tester) async {
    // The consent belongs to creating an account, not to using one.
    await pump(tester);

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('creating an account asks, and starts unticked', (tester) async {
    // A box already checked when the screen opens is not consent.
    await pump(tester);
    await switchToRegister(tester);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
    expect(find.textContaining('privacy policy'), findsOne);
  });

  testWidgets('an unticked box blocks the request', (tester) async {
    await pump(tester);
    await switchToRegister(tester);
    await fillTheForm(tester);

    await tapVisible(tester, find.byType(FilledButton));

    expect(auth.registrations, 0);
    expect(
      find.text('You have to accept the privacy policy to create an account'),
      findsOne,
    );
  });

  testWidgets('ticking it lets the request through', (tester) async {
    await pump(tester);
    await switchToRegister(tester);
    await fillTheForm(tester);

    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.byType(FilledButton));

    expect(auth.registrations, 1);
  });

  testWidgets('leaving and returning does not keep the tick', (tester) async {
    // Otherwise a stray tap earlier in the session counts as consent given on
    // the form actually being submitted.
    await pump(tester);
    await switchToRegister(tester);
    await tapVisible(tester, find.byType(Checkbox));

    await tapVisible(tester, find.text('Already have an account? Sign in'));
    await switchToRegister(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}
