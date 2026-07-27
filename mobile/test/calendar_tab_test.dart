import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/l10n/app_localizations.dart';
import 'package:todotrip/features/trips/data/item.dart';
import 'package:todotrip/features/trips/presentation/tabs/calendar_tab.dart';
import 'package:todotrip/features/trips/providers.dart';

/// The agenda renders inside a ListView, so its cards get an unbounded height
/// to lay out in. A card that needs a bounded one throws instead of drawing,
/// which is invisible in `flutter analyze` and empties the tab at runtime.
///
/// The rest of these are about the two things the day-grouped agenda claims to
/// do: say each date once, and point at the one event that has not happened yet.
void main() {
  Item event({required String title, required DateTime at, String? location}) =>
      Item(
        id: 'i-$title',
        tripId: 't',
        type: ItemType.event,
        title: title,
        location: location,
        startsAt: at,
        createdBy: 'u',
        createdAt: DateTime(2026),
      );

  /// A time on a given day, well clear of midnight so a test never straddles it.
  DateTime dayAt(int offset, int hour) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
    ).add(Duration(days: offset));
  }

  Future<void> pump(WidgetTester tester, List<Item> items) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemsProvider('t').overrideWith((ref) async => items)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CalendarTab(tripId: 't')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an event', (tester) async {
    await pump(tester, [
      event(
        title: 'Volo per Lisbona',
        at: DateTime.now().add(const Duration(days: 3)),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Volo per Lisbona'), findsOne);
  });

  testWidgets('shows the empty state when there are only tasks', (
    tester,
  ) async {
    await pump(tester, [
      Item(
        id: 'i1',
        tripId: 't',
        type: ItemType.task,
        title: 'Fare la spesa',
        createdBy: 'u',
        createdAt: DateTime(2026),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Nothing planned yet'), findsOne);
  });

  testWidgets('a day is named once, however many events it holds', (
    tester,
  ) async {
    /// The whole reason for the rewrite: three events on the twelfth used to
    /// print the twelfth three times.
    await pump(tester, [
      event(title: 'Colazione', at: dayAt(1, 9)),
      event(title: 'Museo', at: dayAt(1, 14)),
      event(title: 'Cena', at: dayAt(1, 20)),
    ]);

    expect(find.text('Tomorrow'), findsOne);
    expect(find.text('09:00'), findsOne);
    expect(find.text('14:00'), findsOne);
    expect(find.text('20:00'), findsOne);
  });

  testWidgets('each day gets its own heading', (tester) async {
    await pump(tester, [
      event(title: 'Volo', at: dayAt(0, 23)),
      event(title: 'Museo', at: dayAt(1, 10)),
    ]);

    expect(find.text('Today'), findsOne);
    expect(find.text('Tomorrow'), findsOne);
  });

  testWidgets('the next event carries a countdown, the others do not', (
    tester,
  ) async {
    /// Only one row on the screen is allowed to ask for attention, and it is
    /// the one you are about to be late for.
    await pump(tester, [
      event(title: 'Passata', at: dayAt(0, 0)),
      event(
        title: 'Prossima',
        at: DateTime.now().add(const Duration(hours: 2)),
      ),
      event(title: 'Dopo', at: dayAt(2, 10)),
    ]);

    expect(find.textContaining('IN 2 HOURS'), findsOne);
  });

  testWidgets('a countdown only appears when the next event is close', (
    tester,
  ) async {
    /// "In 3 days" shouted on the only highlighted row would be noise, and the
    /// day heading has already said it.
    await pump(tester, [event(title: 'Lontana', at: dayAt(3, 10))]);

    expect(find.textContaining('IN '), findsNothing);
    expect(find.text('Lontana'), findsOne);
  });

  testWidgets('an event with nothing but a title still draws', (tester) async {
    /// Location and description are both optional and both used to be the
    /// source of empty gaps.
    await pump(tester, [event(title: 'Solo titolo', at: dayAt(1, 10))]);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.place_outlined), findsNothing);
  });

  testWidgets('a location is shown when there is one', (tester) async {
    await pump(tester, [
      event(title: 'Volo', at: dayAt(1, 10), location: 'Bergamo'),
    ]);

    expect(find.text('Bergamo'), findsOne);
    expect(find.byIcon(Icons.place_outlined), findsOne);
  });
}
