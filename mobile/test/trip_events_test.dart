import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/features/trips/data/trip_events.dart';

void main() {
  group('what a closed socket means', () {
    test('4403 stops for good', () {
      // Removed from the trip. Reconnecting would only be rejected again, and
      // a client that keeps trying is a client that never tells the user.
      expect(closureFor(4403), SocketClosure.stop);
    });

    test('4401 rotates the token first', () {
      // The server now rechecks the token on an open socket, so this arrives
      // roughly every time an access token ages out mid-screen. Reconnecting
      // with the same token would be refused again, all the way up the backoff.
      expect(closureFor(4401), SocketClosure.refreshToken);
    });

    test('a dropped connection just retries', () {
      for (final code in [null, 1000, 1001, 1006, 1011]) {
        expect(closureFor(code), SocketClosure.retry, reason: 'code $code');
      }
    });

    test('the two rejections are not the same case', () {
      // The bug this guards: treating 4401 like 4403 leaves the screen dead
      // until it is reopened, and treating it like a plain drop reconnects
      // with the token that was just refused.
      expect(closureFor(4401), isNot(closureFor(4403)));
      expect(closureFor(4401), isNot(closureFor(1006)));
    });
  });
}
