import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/item.dart';
import 'package:todotrip/features/trips/presentation/tabs/calendar_tab.dart';
import 'package:todotrip/features/trips/providers.dart';

/// The agenda renders inside a ListView, so its cards get an unbounded height
/// to lay out in. A card that needs a bounded one throws instead of drawing,
/// which is invisible in `flutter analyze` and empties the tab at runtime.
void main() {
  Item event({required String title, required DateTime at}) => Item(
    id: 'i-$title',
    tripId: 't',
    type: ItemType.event,
    title: title,
    startsAt: at,
    createdBy: 'u',
    createdAt: DateTime(2026),
  );

  Future<void> pump(WidgetTester tester, List<Item> items) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsProvider('t').overrideWith((ref) async => items),
        ],
        child: const MaterialApp(home: Scaffold(body: CalendarTab(tripId: 't'))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an event', (tester) async {
    await pump(tester, [
      event(title: 'Volo per Lisbona', at: DateTime.now().add(const Duration(days: 3))),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Volo per Lisbona'), findsOne);
  });

  testWidgets('shows the empty state when there are only tasks', (tester) async {
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
}
