import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/l10n/app_localizations.dart';
import 'package:todotrip/features/trips/data/checklist.dart';
import 'package:todotrip/features/trips/presentation/checklist_screen.dart';
import 'package:todotrip/features/trips/providers.dart';

void main() {
  ChecklistEntry entry(String id, String text, {bool checked = false}) =>
      ChecklistEntry(
        id: id,
        checklistId: 'c1',
        text: text,
        checkedAt: checked ? DateTime(2026) : null,
        createdAt: DateTime(2026),
      );

  Future<void> pump(WidgetTester tester, List<Checklist> lists) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [checklistsProvider('t').overrideWith((ref) async => lists)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChecklistScreen(tripId: 't', checklistId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final checklist = Checklist(
    id: 'c1',
    tripId: 't',
    name: 'Spesa',
    createdBy: 'u',
    createdAt: DateTime(2026),
    entries: [entry('e1', 'Pane'), entry('e2', 'Latte', checked: true)],
  );

  testWidgets('shows the entries and the progress', (tester) async {
    await pump(tester, [checklist]);

    expect(tester.takeException(), isNull);
    expect(find.text('Pane'), findsOne);
    expect(find.text('Latte'), findsOne);
    expect(find.text('1 of 2'), findsOne);
  });

  testWidgets('says so when the list was deleted elsewhere', (tester) async {
    await pump(tester, []);

    expect(tester.takeException(), isNull);
    expect(find.text('This list is gone'), findsOne);
  });
}
