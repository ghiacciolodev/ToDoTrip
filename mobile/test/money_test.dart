import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:todotrip/core/money.dart';

void main() {
  setUp(() => Intl.defaultLocale = 'en');

  group('the symbol follows the currency', () {
    test('a trip in euro shows euro', () {
      expect(const Money(3250).formattedIn('EUR'), contains('€'));
    });

    test('a trip in yen does not show euro', () {
      // The bug this covers: the symbol was written into money.dart, so every
      // amount in the app read as euro whatever the trip was kept in — while
      // the settings screen promised that changing the currency changes the
      // symbol.
      final yen = const Money(325000).formattedIn('JPY');
      expect(yen, isNot(contains('€')));
      expect(yen, contains('¥'));
    });

    test('pounds and dollars are told apart', () {
      expect(const Money(1000).formattedIn('GBP'), contains('£'));
      expect(const Money(1000).formattedIn('USD'), contains(r'$'));
    });

    test('a code with no symbol falls back to the code itself', () {
      // Rather than throwing or printing an empty prefix.
      expect(const Money(1000).formattedIn('MGA'), isNotEmpty);
    });
  });

  group('signed amounts', () {
    test('a credit is prefixed with a plus', () {
      expect(const Money(500).signedIn('EUR'), startsWith('+'));
    });

    test('a debt uses a real minus sign, not a hyphen', () {
      final owed = const Money(-500).signedIn('EUR');
      expect(owed, startsWith('−'));
      expect(owed, isNot(startsWith('-')));
    });

    test('zero is neither', () {
      final settled = const Money(0).signedIn('EUR');
      expect(settled, isNot(startsWith('+')));
      expect(settled, isNot(startsWith('−')));
    });

    test('the sign survives a change of currency', () {
      expect(const Money(-500).signedIn('JPY'), startsWith('−'));
    });
  });

  group('the language still decides the separators', () {
    test('italian writes a comma', () {
      Intl.defaultLocale = 'it';
      expect(const Money(3250).formattedIn('EUR'), contains('32,50'));
    });

    test('english writes a full stop', () {
      Intl.defaultLocale = 'en';
      expect(const Money(3250).formattedIn('EUR'), contains('32.50'));
    });

    test('the two are cached apart', () {
      // One formatter per language *and* currency: caching on either alone
      // would serve the wrong one after a switch.
      Intl.defaultLocale = 'it';
      final italian = const Money(3250).formattedIn('EUR');
      Intl.defaultLocale = 'en';
      final english = const Money(3250).formattedIn('EUR');
      expect(italian, isNot(english));
    });
  });

  group('reading what the user typed', () {
    test('both decimal separators are accepted', () {
      expect(Money.tryParse('12,50'), const Money(1250));
      expect(Money.tryParse('12.50'), const Money(1250));
    });

    test('a pasted symbol is ignored, whichever it is', () {
      // It used to strip the euro sign only, so pasting "¥3250" from anywhere
      // gave null and the field silently refused the number.
      expect(Money.tryParse('€12,50'), const Money(1250));
      expect(Money.tryParse('£12.50'), const Money(1250));
      expect(Money.tryParse(r'$12.50'), const Money(1250));
    });

    test('nonsense is refused rather than guessed at', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('abc'), isNull);
    });

    test('a third decimal is rounded, not dropped', () {
      expect(Money.tryParse('12.345'), const Money(1235));
    });
  });
}
