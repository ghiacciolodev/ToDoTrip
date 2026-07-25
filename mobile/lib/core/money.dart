import 'package:intl/intl.dart';

/// Amounts, always as integer cents.
///
/// Mirrors the backend, where money is BigInteger cents and never a float:
/// 0.01 has no exact binary representation, so a few splits are enough for the
/// rounding error to become visible. Doubles are not allowed to exist between
/// the API and the widget — only this type crosses that distance.
extension type const Money(int cents) {
  /// Single place to change if the app ever ships in another locale.
  static const _locale = 'en_IE';

  static final _formatter = NumberFormat.currency(locale: _locale, symbol: '€');
  static final _plain = NumberFormat.decimalPatternDigits(
    locale: _locale,
    decimalDigits: 2,
  );

  /// "€32.50"
  String get formatted => _formatter.format(cents / 100);

  /// "32.50" — for text fields, where the symbol is part of the decoration.
  String get plain => _plain.format(cents / 100);

  /// "+€32.50" / "−€18.00", using a real minus sign rather than a hyphen.
  String get signed {
    if (cents == 0) return _formatter.format(0);
    final sign = cents > 0 ? '+' : '−';
    return '$sign${_formatter.format(cents.abs() / 100)}';
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