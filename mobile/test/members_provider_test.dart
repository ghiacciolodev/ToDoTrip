import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/trips/data/trip_member.dart';
import 'package:todotrip/features/trips/providers.dart';

/// The member list serves two different questions, and mixing them up is either
/// a name shown as "Unknown" or a person offered for a task they can no longer
/// be assigned.
void main() {
  TripMember member(String id, {DateTime? leftAt}) => TripMember(
    user: User(
      id: id,
      email: '$id@test.it',
      displayName: id,
      createdAt: DateTime(2026),
    ),
    role: MemberRole.member,
    joinedAt: DateTime(2026),
    leftAt: leftAt,
  );

  Future<ProviderContainer> containerWith(List<TripMember> members) async {
    final container = ProviderContainer(
      overrides: [
        tripMembersProvider('t').overrideWith((ref) async => members),
      ],
    );
    addTearDown(container.dispose);
    await container.read(tripMembersProvider('t').future);
    return container;
  }

  test('the active list leaves out anyone who has gone', () async {
    final container = await containerWith([
      member('luca'),
      member('giulia', leftAt: DateTime(2026, 7, 20)),
    ]);

    expect(container.read(activeMembersProvider('t')).map((m) => m.user.id), [
      'luca',
    ]);
  });

  test('the lookup still resolves someone who has gone', () async {
    final container = await containerWith([
      member('luca'),
      member('giulia', leftAt: DateTime(2026, 7, 20)),
    ]);

    final lookup = container.read(memberLookupProvider('t'));
    expect(lookup['giulia']?.user.displayName, 'giulia');
    expect(lookup['giulia']?.hasLeft, isTrue);
  });
}
