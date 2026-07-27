import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/trips/data/trip.dart';
import 'package:todotrip/features/trips/data/trip_member.dart';
import 'package:todotrip/features/trips/presentation/trip_settings_screen.dart';
import 'package:todotrip/features/trips/providers.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The load-bearing rule on this screen is who may do what, and the failure it
/// guards against is a button that can only ever produce a 403. So the tests are
/// mostly about what a plain member does *not* see.
void main() {
  User user(String id) => User(
    id: id,
    email: '$id@test.it',
    displayName: id,
    createdAt: DateTime(2026),
  );

  TripMember member(String id, MemberRole role) =>
      TripMember(user: user(id), role: role, joinedAt: DateTime(2026));

  Trip trip({DateTime? archivedAt, int expenses = 3}) => Trip(
    id: 't',
    name: 'Lisbona',
    baseCurrency: 'EUR',
    createdBy: 'u1',
    createdByName: 'Mario',
    createdAt: DateTime(2026, 6, 3),
    archivedAt: archivedAt,
    memberCount: 2,
    expenseCount: expenses,
    itemCount: 5,
    totalSpentCents: 12550,
  );

  Future<void> pump(
    WidgetTester tester, {
    required MemberRole role,
    Trip? value,
  }) async {
    // A tall viewport: the screen is a long ListView, and its lower sections —
    // which is where the permission rules live — are never built on a phone
    // sized window, so a finder would report them absent for the wrong reason.
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final me = member('u1', role);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripProvider('t').overrideWith((ref) async => value ?? trip()),
          myMembershipProvider('t').overrideWithValue(me),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TripSettingsScreen(tripId: 't'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('as the owner', () {
    testWidgets('the destructive actions are there', (tester) async {
      await pump(tester, role: MemberRole.owner);
      expect(find.text('Archive trip'), findsOne);
      expect(find.text('Delete trip'), findsOne);
    });

    testWidgets('the currency warning is spelled out, not an asterisk', (
      tester,
    ) async {
      /// The one place on this screen where somebody can quietly break
      /// everybody's accounts: amounts are stored without an exchange rate, so
      /// changing the currency renames them rather than converting them.
      await pump(tester, role: MemberRole.owner);
      expect(find.textContaining("won't convert existing expenses"), findsOne);
    });

    testWidgets('the save bar turns up only once something changes', (
      tester,
    ) async {
      /// It used to be a greyed-out button halfway down a long list, which is
      /// easy to scroll past and easy to read as decoration. Nothing to save,
      /// nothing on screen.
      await pump(tester, role: MemberRole.owner);
      expect(find.text('Save changes'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Lisbona 2027');
      await tester.pump();
      expect(find.text('Save changes'), findsOne);
      expect(find.text('You have unsaved changes'), findsOne);
    });

    testWidgets('editing the icon counts as a change too', (tester) async {
      /// The dirty check has to cover the pickers, not just the text fields —
      /// otherwise a colour chosen and never saved would silently be lost.
      await pump(tester, role: MemberRole.owner);
      await tester.tap(find.byIcon(Icons.beach_access));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOne);
    });
  });

  group('as a plain member', () {
    testWidgets('nothing destructive is offered', (tester) async {
      /// Not disabled — absent. A control that always fails is worse than one
      /// that was never drawn.
      await pump(tester, role: MemberRole.member);
      expect(find.text('Archive trip'), findsNothing);
      expect(find.text('Delete trip'), findsNothing);
      expect(find.text('Save changes'), findsNothing);
    });

    testWidgets('the facts are still readable', (tester) async {
      /// Knowing which currency the trip counts in is everybody's business;
      /// only changing it is the owner's.
      await pump(tester, role: MemberRole.member);
      expect(find.text('EUR'), findsOne);
      expect(find.text('Lisbona'), findsWidgets);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('leaving is offered to them', (tester) async {
      await pump(tester, role: MemberRole.member);
      expect(find.text('Leave trip'), findsOne);
    });
  });

  testWidgets('the counters and the total are shown', (tester) async {
    await pump(tester, role: MemberRole.owner);
    expect(find.text('2 members'), findsOne);
    expect(find.text('3 expenses'), findsOne);
    expect(find.text('5 plan entries'), findsOne);
    expect(find.textContaining('125.50'), findsOne);
  });

  testWidgets('an archived trip says so and offers the way back', (
    tester,
  ) async {
    await pump(
      tester,
      role: MemberRole.owner,
      value: trip(archivedAt: DateTime(2026, 7, 1)),
    );
    expect(find.textContaining('This trip is archived'), findsOne);
    expect(find.text('Bring back from the archive'), findsOne);
    expect(find.text('Archive trip'), findsNothing);
  });
}
