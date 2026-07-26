import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/trip_identity.dart';
import 'package:todotrip/features/trips/presentation/widgets/trip_sheets.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The point of the preview is that it tells the truth: whatever it shows while
/// the form is open is what the list will show afterwards. These pin the three
/// ways it could quietly stop matching — the name, the icon, and the icon being
/// unset again.
void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showCreateTripSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the preview stands in for the name until there is one', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Trip'), findsOne);

    await tester.enterText(find.byType(TextFormField).first, 'Lisbona');
    await tester.pump();
    // Once in the field being typed into, once in the preview above it.
    expect(find.text('Lisbona'), findsExactly(2));
    expect(find.text('Trip'), findsNothing);
  });

  testWidgets('with no icon chosen the preview shows the skyline', (
    tester,
  ) async {
    await open(tester);
    // Once in the preview, once in the picker row.
    expect(find.byIcon(tripIcons['city']!), findsExactly(2));
  });

  testWidgets('picking an icon moves it into the preview', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(tripIcons['beach']!));
    await tester.pumpAndSettle();

    expect(find.byIcon(tripIcons['beach']!), findsExactly(2));
    // The skyline is only in the picker now.
    expect(find.byIcon(tripIcons['city']!), findsOne);
  });

  testWidgets('tapping the chosen icon again clears it', (tester) async {
    /// Skipping the step has to stay possible after changing your mind, not
    /// only before touching anything.
    await open(tester);
    await tester.tap(find.byIcon(tripIcons['beach']!));
    await tester.pumpAndSettle();
    // The picker one, not the copy the preview now also draws above it.
    await tester.tap(find.byIcon(tripIcons['beach']!).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(tripIcons['city']!), findsExactly(2));
  });

  testWidgets('the description is out of the way until asked for', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Description'), findsNothing);

    await tester.tap(find.text('Add a description'));
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOne);
  });
}
