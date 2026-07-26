import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/trips/data/trip_member.dart';
import 'package:todotrip/features/trips/presentation/widgets/member_actions.dart';
import 'package:todotrip/features/trips/providers.dart';

/// Which actions a member row offers depends on who is looking and at whom.
/// Getting it wrong either hides a legitimate action or shows one the API will
/// reject, so every combination is pinned down here.
void main() {
  TripMember member(String id, String name, MemberRole role) => TripMember(
    user: User(id: id, email: '$id@test.it', displayName: name, createdAt: DateTime(2026)),
    role: role,
    joinedAt: DateTime(2026),
  );

  final owner = member('u1', 'Mario', MemberRole.owner);
  final plain = member('u2', 'Luca', MemberRole.member);

  /// Opens the sheet as [me], tapping on [target].
  Future<void> open(
    WidgetTester tester, {
    required List<TripMember> members,
    required TripMember me,
    required TripMember target,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripMembersProvider('t').overrideWith((ref) async => members),
          myMembershipProvider('t').overrideWithValue(me),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showMemberActionsSheet(context, 't', target.user.id),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('an owner can promote or remove another member', (tester) async {
    await open(tester, members: [owner, plain], me: owner, target: plain);

    expect(find.text('Make owner'), findsOne);
    expect(find.text('Remove from trip'), findsOne);
  });

  testWidgets('a member is offered nothing on someone else', (tester) async {
    await open(tester, members: [owner, plain], me: plain, target: owner);

    expect(find.text('Only the owner can manage members.'), findsOne);
    expect(find.text('Remove from trip'), findsNothing);
  });

  testWidgets('an owner with company cannot leave yet', (tester) async {
    await open(tester, members: [owner, plain], me: owner, target: owner);

    expect(find.text('Leave trip'), findsOne);
    expect(
      find.text("You're the owner. Make someone else the owner first."),
      findsOne,
    );

    // Tapping the disabled row must not resolve the sheet with an action.
    await tester.tap(find.text('Leave trip'));
    await tester.pumpAndSettle();
    expect(find.text('Leave trip'), findsOne);
  });

  testWidgets('the last member leaves and takes the trip with them', (tester) async {
    await open(tester, members: [owner], me: owner, target: owner);

    expect(find.text('Leave and delete trip'), findsOne);
    expect(find.text("You're the only one left, so the trip goes too."), findsOne);
  });

  testWidgets('a plain member can leave', (tester) async {
    await open(tester, members: [owner, plain], me: plain, target: plain);

    expect(find.text('Leave trip'), findsOne);
    expect(find.text('Make owner'), findsNothing);
  });

  testWidgets('someone removed while the sheet opens is reported', (tester) async {
    await open(tester, members: [owner], me: owner, target: plain);

    expect(find.text('This person is no longer in the trip.'), findsOne);
  });

  testWidgets('a former member is not offered any action', (tester) async {
    /// They stay in the list so old expenses can name them; there is nothing
    /// left to do to them.
    final left = member('u3', 'Giulia', MemberRole.member)
        .copyWith(leftAt: DateTime(2026, 7, 20));
    await open(tester, members: [owner, left], me: owner, target: left);

    expect(find.text('This person is no longer in the trip.'), findsOne);
    expect(find.text('Remove from trip'), findsNothing);
  });
}
