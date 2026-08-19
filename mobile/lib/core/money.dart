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
  /// One formatter per language and currency, kept between repaints: a list of
  /// expenses would otherwise build one per row on every frame.
  ///
  /// Keyed by both because both change the output — "32,50 €" in Italian,
  /// "€32.50" in English, "¥3,250" with no decimals at all.
  static final _currencies = <String, NumberFormat>{};
  static String? _plainFor;
  static NumberFormat? _plain;

  static NumberFormat _formatter(String currency) {
    final locale = Intl.getCurrentLocale();
    return _currencies.putIfAbsent(
      '$locale/$currency',
      () => NumberFormat.simpleCurrency(locale: locale, name: currency),
    );
  }

  static void _ensurePlain() {
    final locale = Intl.getCurrentLocale();
    if (_plainFor == locale && _plain != null) return;
    _plainFor = locale;
    _plain = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
  }

  /// "€32.50" in English, "32,50 €" in Italian, "¥3,250" for a trip in yen.
  ///
  /// The currency is passed in rather than assumed. It used to be a hardcoded
  /// euro sign, which made the promise on the trip settings screen — that
  /// changing the currency changes the symbol — simply untrue.
  String formattedIn(String currency) =>
      _formatter(currency).format(cents / 100);

  /// "32.50" — for text fields, where the symbol is part of the decoration.
  String get plain {
    _ensurePlain();
    return _plain!.format(cents / 100);
  }

  /// "+€32.50" / "−€18.00", using a real minus sign rather than a hyphen.
  String signedIn(String currency) {
    final format = _formatter(currency);
    if (cents == 0) return format.format(0);
    final sign = cents > 0 ? '+' : '−';
    return '$sign${format.format(cents.abs() / 100)}';
  }

  /// The bare symbol, for labels and text-field decorations.
  static String symbolFor(String currency) =>
      _formatter(currency).currencySymbol;

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  Money get abs => Money(cents.abs());

  /// Parses user input, accepting both "12,50" and "12.50": the keyboard a
  /// user gets depends on their device locale, not on ours.
  static Money? tryParse(String input) {
    // Any currency symbol the user may have typed or pasted along with the
    // number, not just the euro sign this once assumed.
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    final normalised = cleaned.replaceAll(',', '.');
    final value = double.tryParse(normalised);
    if (value == null || value.isNaN || value.isInfinite) return null;

    // round(), not truncate: 12.345 should become 1235, not 1234.
    return Money((value * 100).round());
  }
}
