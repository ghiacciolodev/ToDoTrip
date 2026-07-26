import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/map_pin.dart';

/// The wire format is where a map feature breaks quietly: a category that does
/// not round-trip means a pin comes back as "other" and nobody notices until
/// the icons are all the same.
void main() {
  group('PinCategory', () {
    test('every category survives a round trip', () {
      for (final category in PinCategory.values) {
        final json = {
          'id': 'p1',
          'trip_id': 't',
          'name': 'X',
          'description': null,
          'latitude': 41.15,
          'longitude': -8.62,
          'category': category.wire,
          'created_by': 'u1',
          'created_at': '2026-07-26T10:00:00Z',
        };
        expect(MapPin.fromJson(json).category, category);
      }
    });

    test('the multi-word one is snake_case on the wire', () {
      // The only value where the Dart name and the API name differ.
      expect(PinCategory.meetingPoint.wire, 'meeting_point');
    });
  });

  group('MemberLocation', () {
    MemberLocation at(DateTime updatedAt) => MemberLocation(
      userId: 'u1',
      latitude: 38.72,
      longitude: -9.13,
      updatedAt: updatedAt,
      expiresAt: updatedAt.add(const Duration(minutes: 30)),
    );

    test('a fresh position is not stale', () {
      expect(at(DateTime.now()).isStale, isFalse);
    });

    test('older than two minutes is stale', () {
      /// Past that, the marker is faded and the sheet says when it was: showing
      /// it as current would be a claim the data does not support.
      expect(
        at(DateTime.now().subtract(const Duration(minutes: 3))).isStale,
        isTrue,
      );
    });
  });
}
