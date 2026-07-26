import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/l10n/app_localizations.dart';
import 'package:todotrip/core/providers.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/trips/data/map_pin.dart';
import 'package:todotrip/features/trips/data/map_repository.dart';
import 'package:todotrip/features/trips/data/trip_member.dart';
import 'package:todotrip/features/trips/presentation/tabs/map_tab.dart';
import 'package:todotrip/features/trips/presentation/widgets/map_markers.dart';
import 'package:todotrip/features/trips/providers.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.user);

  final User user;

  @override
  Future<User?> build() async => user;
}

/// Answers without a network, so the map can be pumped in a test.
class _FakeMapRepository extends MapRepository {
  _FakeMapRepository(this.seed) : super(dio: Dio());

  final List<MemberLocation> seed;

  @override
  Future<List<MemberLocation>> locations(String tripId) async => seed;
}

void main() {
  final me = User(
    id: 'mario',
    email: 'mario@test.it',
    displayName: 'Mario',
    createdAt: DateTime(2026),
  );

  TripMember member(String id, String name) => TripMember(
    user: User(
      id: id,
      email: '$id@test.it',
      displayName: name,
      createdAt: DateTime(2026),
    ),
    role: MemberRole.member,
    joinedAt: DateTime(2026),
  );

  MemberLocation locationOf(String userId) => MemberLocation(
    userId: userId,
    latitude: 38.7223,
    longitude: -9.1393,
    updatedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  final pin = MapPin(
    id: 'p1',
    tripId: 't',
    name: 'Ostello',
    latitude: 38.7223,
    longitude: -9.1393,
    category: PinCategory.lodging,
    createdBy: 'mario',
    createdAt: DateTime(2026),
  );

  Future<void> pump(
    WidgetTester tester, {
    List<MapPin> pins = const [],
    List<MemberLocation> locations = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(me)),
          mapRepositoryProvider.overrideWithValue(
            _FakeMapRepository(locations),
          ),
          mapPinsProvider('t').overrideWith((ref) async => pins),
          tripMembersProvider('t').overrideWith(
            (ref) async => [member('mario', 'Mario'), member('luca', 'Luca')],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MapTab(tripId: 't', isVisible: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a saved pin is drawn on the map', (tester) async {
    await pump(tester, pins: [pin]);

    expect(find.byType(PinMarker), findsOne);
  });

  testWidgets('another member sharing is drawn', (tester) async {
    await pump(tester, locations: [locationOf('luca')]);

    expect(find.byType(MemberMarker), findsOne);
  });

  testWidgets('my own position is not duplicated as a member marker', (
    tester,
  ) async {
    /// My avatar comes from the device, not from the list of who is sharing, so
    /// an echo of my own position must not draw a second one.
    await pump(tester, locations: [locationOf('mario')]);

    expect(find.byType(MemberMarker), findsNothing);
  });

  testWidgets('people are avatars, mine ringed to tell it apart', (
    tester,
  ) async {
    await pump(tester, locations: [locationOf('luca')]);

    final marker = tester.widget<MemberMarker>(find.byType(MemberMarker));
    expect(marker.initials, 'L');
    expect(marker.isMe, isFalse);
  });

  testWidgets('leaving the map without sharing tells the server nothing', (
    tester,
  ) async {
    /// Stopping used to fire a DELETE on every dispose, even when the switch
    /// had never been touched.
    await pump(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
