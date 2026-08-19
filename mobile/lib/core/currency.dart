import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'money.dart';

/// The currency codes the server will accept.
///
/// Mirrors `backend/app/core/currency.py`: ISO 4217, restricted to money that
/// actually circulates — no precious metals, no fund or accounting units. The
/// two lists have to be changed together, and the server is the one that
/// enforces it; this copy exists so the picker cannot offer a code that would
/// come back as a 422.
const supportedCurrencies = [
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', //
  'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL',
  'BSD', 'BTN', 'BWP', 'BYN', 'BZD',
  'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 'COP', 'CRC', 'CUP', 'CVE', 'CZK',
  'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB', 'EUR',
  'FJD', 'FKP', 'GBP', 'GEL', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD',
  'HKD', 'HNL', 'HTG', 'HUF', 'IDR', 'ILS', 'INR', 'IQD', 'IRR', 'ISK',
  'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF', 'KPW', 'KRW', 'KWD',
  'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD',
  'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRU', 'MUR', 'MVR',
  'MWK', 'MXN', 'MYR', 'MZN',
  'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR',
  'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON', 'RSD',
  'RUB', 'RWF',
  'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLE', 'SOS', 'SRD',
  'SSP', 'STN', 'SVC', 'SYP', 'SZL',
  'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TWD', 'TZS',
  'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VED', 'VES', 'VND', 'VUV', 'WST',
  'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWG',
];

/// Offered first in the picker.
///
/// Not a judgement about which money matters: scrolling 156 codes to reach the
/// one you almost certainly want is a worse list than a short one with the rest
/// underneath it.
const commonCurrencies = [
  'EUR',
  'USD',
  'GBP',
  'CHF',
  'JPY',
  'CAD',
  'AUD',
  'SEK',
  'NOK',
  'DKK',
  'PLN',
  'CZK',
];

/// "EUR · €", or just the code when the two would be the same.
String currencyLabel(String code) {
  final symbol = Money.symbolFor(code);
  return symbol == code ? code : '$code · $symbol';
}

/// The currency new trips are created in.
///
/// A local preference, not a server setting: it is a default for a form, and
/// each trip carries its own currency once created. Changing it never touches
/// a trip that already exists — which is the same promise the trip settings
/// screen makes about its own currency field.
class DefaultCurrency extends AsyncNotifier<String> {
  static const _key = 'default_currency';
  static const fallback = 'EUR';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    // A code that is no longer offered falls back rather than being sent to a
    // server that would reject it.
    if (stored == null || !supportedCurrencies.contains(stored)) {
      return fallback;
    }
    return stored;
  }

  Future<void> select(String code) async {
    if (!supportedCurrencies.contains(code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    state = AsyncData(code);
  }
}

final defaultCurrencyProvider = AsyncNotifierProvider<DefaultCurrency, String>(
  DefaultCurrency.new,
);
