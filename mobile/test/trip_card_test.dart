import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/trip.dart';
import 'package:todotrip/features/trips/data/trip_identity.dart';
import 'package:todotrip/features/trips/presentation/widgets/avatar_stack.dart';
import 'package:todotrip/features/trips/presentation/widgets/trip_card.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The card says where a trip stands, who is in it and what it costs you. All
/// three are computed, and each of them can legitimately be absent — which is
/// where a card usually goes wrong: an empty slot that still takes up room, or
/// a claim about money nobody has spent.
void main() {
  Trip trip({
    DateTime? start,
    DateTime? end,
    int? balance,
    String? description,
    DateTime? lastActivity,
    String? icon,
    String? color,
    int members = 1,
    List<MemberPreview> preview = const [],
  }) => Trip(
    id: 't1',
    name: 'Lisbona',
    description: description,
    baseCurrency: 'EUR',
    icon: icon,
    color: color,
    createdBy: 'u1',
    createdAt: DateTime(2026),
    startDate: start,
    endDate: end,
    memberCount: members,
    memberPreview: preview,
    myBalanceCents: balance,
    lastActivityAt: lastActivity,
  );

  DateTime day(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
  }

  Future<void> pump(WidgetTester tester, Trip value) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TripCard(trip: value)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('stage', () {
    test('a trip with no dates has no stage to show', () {
      expect(trip().stage, TripStage.undated);
    });

    test('starting today counts as running, not upcoming', () {
      /// A trip that starts this evening starts today: comparing at day
      /// precision is what keeps it out of "In 1 day".
      expect(trip(start: day(0), end: day(3)).stage, TripStage.running);
    });

    test('day of trip counts from one', () {
      expect(trip(start: day(-2), end: day(4)).dayOfTrip, 3);
      expect(trip(start: day(-2), end: day(4)).totalDays, 7);
    });

    test('past its end date it has ended', () {
      expect(trip(start: day(-9), end: day(-2)).stage, TripStage.ended);
    });
  });

  group('the badge', () {
    testWidgets('an upcoming trip says how long is left', (tester) async {
      await pump(tester, trip(start: day(12), end: day(19)));
      expect(find.text('In 12 days'), findsOne);
    });

    testWidgets('a running trip says which day it is on', (tester) async {
      await pump(tester, trip(start: day(-2), end: day(4)));
      expect(find.text('Day 3 of 7'), findsOne);
    });

    testWidgets('a finished trip drops the countdown for the last activity', (
      tester,
    ) async {
      /// "Ended" is not something anyone acts on; whether the group is still
      /// doing anything in there is.
      await pump(
        tester,
        trip(
          start: day(-9),
          end: day(-2),
          lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      expect(find.text('2 hours ago'), findsOne);
      expect(find.byIcon(Icons.schedule), findsOne);
    });

    testWidgets('with neither dates nor activity there is no badge', (
      tester,
    ) async {
      await pump(tester, trip());
      expect(find.byIcon(Icons.schedule), findsNothing);
    });
  });

  group('the description', () {
    testWidgets('is shown when there is one', (tester) async {
      await pump(tester, trip(description: 'Quattro giorni di pastéis'));
      expect(find.text('Quattro giorni di pastéis'), findsOne);
    });

    testWidgets('blank draws nothing', (tester) async {
      /// Whitespace is not a description: it would open a gap under the name
      /// for nothing.
      await pump(tester, trip(description: '   '));
      expect(find.text('   '), findsNothing);
    });
  });

  group('the money', () {
    testWidgets('a debt shows as a negative amount', (tester) async {
      await pump(tester, trip(balance: -1800));
      expect(find.textContaining('18.00'), findsOne);
    });

    testWidgets('no expenses means no chip at all', (tester) async {
      /// "Settled" on a trip nobody has spent on would be a claim about money
      /// that does not exist.
      await pump(tester, trip());
      expect(find.text('Settled'), findsNothing);
    });

    testWidgets('a settled trip says settled', (tester) async {
      await pump(tester, trip(balance: 0));
      expect(find.text('Settled'), findsOne);
    });
  });

  testWidgets('members are drawn from the preview', (tester) async {
    await pump(
      tester,
      trip(
        members: 5,
        preview: const [
          MemberPreview(id: 'u1', displayName: 'Mario'),
          MemberPreview(id: 'u2', displayName: 'Luca'),
        ],
      ),
    );
    expect(find.byType(AvatarStack), findsOne);
    // Five members, two previewed: the stack says "+3".
    expect(find.text('+3'), findsOne);
  });

  testWidgets('a trip from the detail endpoint draws no avatars', (
    tester,
  ) async {
    /// It carries no preview, and an empty stack would leave a gap before the
    /// dates.
    await pump(tester, trip());
    expect(find.byType(AvatarStack), findsNothing);
  });

  group('identity', () {
    testWidgets('a chosen icon reaches the card', (tester) async {
      await pump(tester, trip(icon: 'beach'));
      expect(find.byIcon(Icons.beach_access), findsOne);
    });

    test('a chosen icon and colour are used', () {
      final identity = TripIdentity.of(
        tripId: 't1',
        icon: 'ski',
        color: 'blue',
      );
      expect(identity.icon, tripIcons['ski']);
      expect(identity.colour, tripColors['blue']);
    });

    test('no choice means a neutral skyline, not a guess', () {
      /// A random glyph would claim the trip is about mountains or sailing when
      /// nobody said so.
      expect(TripIdentity.of(tripId: 'abc').icon, tripIcons['city']);
    });

    test('an unknown key falls back instead of throwing', () {
      /// A key added by a newer client must not crash an older one.
      expect(
        TripIdentity.of(tripId: 't1', icon: 'submarine').icon,
        tripIcons['city'],
      );
    });

    test('the derived colour is stable across builds', () {
      expect(
        TripIdentity.of(tripId: 'abc').colour,
        TripIdentity.of(tripId: 'abc').colour,
      );
    });
  });
}
