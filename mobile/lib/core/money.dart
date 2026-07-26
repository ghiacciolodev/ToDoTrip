import 'package:intl/intl.dart';

/// Amounts, always as integer cents.
///
/// Mirrors the backend, where money is BigInteger cents and never a float:
/// 0.01 has no exact binary representation, so a few splits are enough for the
/// rounding error to become visible. Doubles are not allowed to exist between
/// the API and the widget — only this type crosses that distance.
///
/// Formatting follows [Intl.defaultLocale], which the app sets from the active
/// language on every build. Italian, French, German and Spanish all write
/// "32,50", and showing "32.50" to them reads as a bug even when the number is
/// right. Going through intl's own global rather than threading a locale through
/// every call site also means every bare `DateFormat` in the app becomes
/// localised by the same switch, instead of forty places each having to
/// remember.
extension type const Money(int cents) {
  /// Rebuilt when the language changes, cached while it does not: formatting a
  /// list of expenses builds one of these per row on every repaint.
  static String? _cachedFor;
  static NumberFormat? _currency;
  static NumberFormat? _plain;

  static void _ensure() {
    final locale = Intl.getCurrentLocale();
    if (_cachedFor == locale && _currency != null) return;
    _cachedFor = locale;
    _currency = NumberFormat.currency(locale: locale, symbol: '€');
    _plain = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
  }

  /// "€32.50" in English, "32,50 €" in Italian.
  String get formatted {
    _ensure();
    return _currency!.format(cents / 100);
  }

  /// "32.50" — for text fields, where the symbol is part of the decoration.
  String get plain {
    _ensure();
    return _plain!.format(cents / 100);
  }

  /// "+€32.50" / "−€18.00", using a real minus sign rather than a hyphen.
  String get signed {
    _ensure();
    if (cents == 0) return _currency!.format(0);
    final sign = cents > 0 ? '+' : '−';
    return '$sign${_currency!.format(cents.abs() / 100)}';
  }

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  Money get abs => Money(cents.abs());

  /// Parses user input, accepting both "12,50" and "12.50": the keyboard a
  /// user gets depends on their device locale, not on ours.
  static Money? tryParse(String input) {
    final cleaned = input.trim().replaceAll('€', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    final normalised = cleaned.replaceAll(',', '.');
    final value = double.tryParse(normalised);
    if (value == null || value.isNaN || value.isInfinite) return null;

    // round(), not truncate: 12.345 should become 1235, not 1234.
    return Money((value * 100).round());
  }
}
