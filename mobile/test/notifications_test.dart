import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/notifications/data/notification.dart';
import 'package:todotrip/features/notifications/data/notification_repository.dart';
import 'package:todotrip/features/notifications/presentation/notification_bell.dart';
import 'package:todotrip/features/notifications/presentation/notifications_screen.dart';
import 'package:todotrip/features/notifications/providers.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The feed's whole value is that the wording is built here rather than stored,
/// so a change of language does not leave the history in the old one — and that
/// a row whose expense was deleted still reads as a sentence.
void main() {
  AppNotification row({
    required NotificationKind kind,
    Map<String, dynamic> payload = const {},
    DateTime? readAt,
  }) => AppNotification(
    id: 'n-${kind.name}',
    tripId: 't1',
    kind: kind,
    actorId: 'u2',
    payload: payload,
    readAt: readAt,
    createdAt: DateTime.now(),
  );

  group('parsing', () {
    test('a kind this build has never heard of does not break the feed', () {
      /// A newer server adding a kind must not stop an older app from showing
      /// the rest of what it was sent.
      final parsed = AppNotification.fromJson({
        'id': 'n1',
        'trip_id': 't1',
        'kind': 'something_invented_later',
        'actor_id': 'u2',
        'entity_id': null,
        'payload': {'actor_name': 'Luca'},
        'read_at': null,
        'created_at': DateTime(2026, 7, 27).toIso8601String(),
      });

      expect(parsed.kind, NotificationKind.unknown);
      expect(parsed.actorName, 'Luca');
    });

    test('read_at is what unread means', () {
      expect(row(kind: NotificationKind.memberJoined).isUnread, isTrue);
      expect(
        row(
          kind: NotificationKind.memberJoined,
          readAt: DateTime.now(),
        ).isUnread,
        isFalse,
      );
    });
  });

  group('where a notification leads', () {
    test('money goes to the money tab', () {
      /// The point of the feature: landing on the calendar after tapping "Luca
      /// added an expense" leaves the reader to go hunting.
      expect(NotificationKind.expenseAdded.tab, 2);
      expect(NotificationKind.expenseDeleted.tab, 2);
      expect(NotificationKind.settlementReceived.tab, 2);
    });

    test('the others go where they belong', () {
      expect(NotificationKind.eventAdded.tab, 0);
      expect(NotificationKind.taskAssigned.tab, 1);
      expect(NotificationKind.memberJoined.tab, 4);
    });

    test('an unknown kind still leads somewhere', () {
      expect(NotificationKind.unknown.tab, 0);
    });
  });

  group('reading and deleting', () {
    Future<(ProviderContainer, _FakeRepository)> containerWith(
      List<AppNotification> rows, {
      int count = 0,
    }) async {
      final repository = _FakeRepository(rows, count: count);
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(notificationFeedProvider.future);
      await container.read(unreadCountProvider.future);
      return (container, repository);
    }

    test(
      'the badge is cleared even when the page holds nothing unread',
      () async {
        /// The bug this pins: with an empty or already-read first page, deciding
        /// from the loaded rows alone left the server never told and the red dot
        /// sitting over a screen with nothing new on it.
        final (container, repository) = await containerWith(const [], count: 3);

        await container.read(notificationFeedProvider.notifier).markAllRead();

        expect(repository.markAllCalled, isTrue);
        expect(container.read(unreadCountProvider).value, 0);
      },
    );

    test('with nothing unread anywhere it leaves the server alone', () async {
      final (container, repository) = await containerWith(const []);

      await container.read(notificationFeedProvider.notifier).markAllRead();
      expect(repository.markAllCalled, isFalse);
    });

    test('deleting a row drops it and the badge with it', () async {
      final unread = row(kind: NotificationKind.expenseAdded);
      final (container, repository) = await containerWith([unread], count: 1);

      await container.read(notificationFeedProvider.notifier).remove(unread);

      expect(container.read(notificationFeedProvider).value, isEmpty);
      expect(repository.removed, [unread.id]);
      expect(container.read(unreadCountProvider).value, 0);
    });

    test('deleting an already-read row leaves the badge alone', () async {
      final read = row(
        kind: NotificationKind.expenseAdded,
        readAt: DateTime.now(),
      );
      final (container, _) = await containerWith([read], count: 2);

      await container.read(notificationFeedProvider.notifier).remove(read);
      expect(container.read(unreadCountProvider).value, 2);
    });

    test('clearing empties both the list and the badge', () async {
      final (container, repository) = await containerWith([
        row(kind: NotificationKind.expenseAdded),
      ], count: 1);

      await container.read(notificationFeedProvider.notifier).clearAll();

      expect(container.read(notificationFeedProvider).value, isEmpty);
      expect(container.read(unreadCountProvider).value, 0);
      expect(repository.cleared, isTrue);
    });
  });

  testWidgets('the empty state is centred on the screen', (tester) async {
    /// It was not, and nothing caught it: a Column inside a ConstrainedBox that
    /// only fixes the height shrinks to its widest line, so "centre" meant the
    /// middle of a two-hundred-pixel box parked against the left margin.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            _FakeRepository(const []),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(MaterialApp)).width;
    expect(
      tester.getCenter(find.text("You're all caught up")).dx,
      moreOrLessEquals(screen / 2, epsilon: 1),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.notifications_none)).dx,
      moreOrLessEquals(screen / 2, epsilon: 1),
    );
  });

  group('the badge', () {
    Future<void> pump(WidgetTester tester, int count) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadCountProvider.overrideWith(() => _FixedCount(count)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(appBar: null, body: NotificationBell()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('nothing unread means no badge', (tester) async {
      await pump(tester, 0);
      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsOne);
    });

    testWidgets('it shows the number', (tester) async {
      await pump(tester, 3);
      expect(find.text('3'), findsOne);
    });

    testWidgets('past nine it stops counting', (tester) async {
      /// Three digits in a badge that size are unreadable, and alarming.
      await pump(tester, 42);
      expect(find.text('9+'), findsOne);
      expect(find.text('42'), findsNothing);
    });
  });
}

class _FixedCount extends UnreadCount {
  _FixedCount(this.value);

  final int value;

  @override
  Future<int> build() async => value;
}

/// Records what was asked of the server, and answers with a fixed page.
class _FakeRepository implements NotificationRepository {
  _FakeRepository(this.rows, {this.count = 0});

  List<AppNotification> rows;
  int count;
  var markAllCalled = false;
  final removed = <String>[];
  var cleared = false;

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<NotificationPage> page({String? before, int limit = 30}) async =>
      NotificationPage(items: rows);

  @override
  Future<int> unreadCount() async => count;

  // These keep the fake honest: the notifier re-reads the count from the
  // server after writing, so a fake that kept answering the old number would
  // make a passing test out of a badge that never clears.
  @override
  Future<void> markAllRead() async {
    markAllCalled = true;
    count = 0;
  }

  @override
  Future<void> markRead(List<String> ids) async {}

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    rows = [
      for (final row in rows)
        if (row.id != id) row,
    ];
  }

  @override
  Future<void> clear() async {
    cleared = true;
    rows = const [];
    count = 0;
  }
}
