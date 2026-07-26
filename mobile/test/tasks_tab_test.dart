import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/checklist.dart';
import 'package:todotrip/features/trips/data/item.dart';
import 'package:todotrip/features/trips/presentation/tabs/tasks_tab.dart';
import 'package:todotrip/features/trips/providers.dart';

void main() {
  final task = Item(
    id: 'i1',
    tripId: 't',
    type: ItemType.task,
    title: 'Prenotare l’ostello',
    startsAt: DateTime.now().add(const Duration(days: 2)),
    createdBy: 'u',
    createdAt: DateTime(2026),
  );

  ChecklistEntry entry(String id, String text, {bool checked = false}) =>
      ChecklistEntry(
        id: id,
        checklistId: 'c1',
        text: text,
        checkedAt: checked ? DateTime(2026) : null,
        createdAt: DateTime(2026),
      );

  final checklist = Checklist(
    id: 'c1',
    tripId: 't',
    name: 'Spesa',
    createdBy: 'u',
    createdAt: DateTime(2026),
    entries: [entry('e1', 'Pane'), entry('e2', 'Latte', checked: true)],
  );

  Future<void> pump(WidgetTester tester, TasksView view) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsProvider('t').overrideWith((ref) async => [task]),
          checklistsProvider('t').overrideWith((ref) async => [checklist]),
          tripMembersProvider('t').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TasksTab(tripId: 't', view: view, onViewChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the to-do view lists tasks', (tester) async {
    await pump(tester, TasksView.todo);

    expect(tester.takeException(), isNull);
    expect(find.text('Prenotare l’ostello'), findsOne);
  });

  testWidgets('the lists view shows what is left', (tester) async {
    await pump(tester, TasksView.lists);

    expect(tester.takeException(), isNull);
    expect(find.text('Spesa'), findsOne);
    expect(find.text('1 left of 2'), findsOne);
  });
}
