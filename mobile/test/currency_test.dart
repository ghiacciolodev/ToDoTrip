import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todotrip/core/currency.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the list the picker offers', () {
    test('every common code is one the server accepts', () {
      // The two lists live in different languages and cannot be checked by the
      // compiler. Offering a code the server rejects turns a tap into a 422.
      for (final code in commonCurrencies) {
        expect(supportedCurrencies, contains(code), reason: code);
      }
    });

    test('no code is offered twice', () {
      expect(supportedCurrencies.toSet().length, supportedCurrencies.length);
    });

    test('every code is three upper-case letters', () {
      for (final code in supportedCurrencies) {
        expect(code, matches(RegExp(r'^[A-Z]{3}$')), reason: code);
      }
    });

    test('the accounting units are kept out', () {
      // XAU is gold and XXX is "no currency". Both are three letters, both
      // pass a length check, and neither is money anybody splits a dinner in.
      expect(supportedCurrencies, isNot(contains('XAU')));
      expect(supportedCurrencies, isNot(contains('XXX')));
      expect(supportedCurrencies, isNot(contains('XDR')));
    });

    test('the francs people actually carry are kept in', () {
      expect(supportedCurrencies, contains('XOF'));
      expect(supportedCurrencies, contains('XPF'));
    });
  });

  group('the label', () {
    test('shows the code and its symbol', () {
      expect(currencyLabel('EUR'), contains('EUR'));
      expect(currencyLabel('EUR'), contains('€'));
    });

    test('does not repeat itself when the symbol is the code', () {
      // Several currencies have no distinct symbol, and "MGA · MGA" reads as
      // a bug.
      final label = currencyLabel('MGA');
      expect(label.split('·').length, lessThanOrEqualTo(2));
    });
  });

  group('the stored preference', () {
    test('starts at euro', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(defaultCurrencyProvider.future), 'EUR');
    });

    test('remembers what was chosen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(defaultCurrencyProvider.future);

      await container.read(defaultCurrencyProvider.notifier).select('JPY');

      expect(container.read(defaultCurrencyProvider).value, 'JPY');
      expect(
        SharedPreferences.getInstance().then(
          (p) => p.getString('default_currency'),
        ),
        completion('JPY'),
      );
    });

    test('refuses a code the server would reject', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(defaultCurrencyProvider.future);

      await container.read(defaultCurrencyProvider.notifier).select('ABC');

      expect(container.read(defaultCurrencyProvider).value, 'EUR');
    });

    test('a stored code that is no longer offered falls back', () async {
      // A currency withdrawn between releases must not be sent to a server
      // that has stopped accepting it.
      SharedPreferences.setMockInitialValues({'default_currency': 'HRK'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(defaultCurrencyProvider.future), 'EUR');
    });
  });
}
