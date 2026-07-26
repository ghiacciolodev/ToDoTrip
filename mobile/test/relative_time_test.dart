import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/core/relative_time.dart';
import 'package:todotrip/l10n/app_localizations.dart';

/// The boundaries are where this can only be wrong: a minute either side of
/// each threshold, and the point where counting days stops meaning anything.
void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String ago(Duration elapsed) =>
      relativeTime(l10n, DateTime.now().subtract(elapsed));

  test('under a minute is just now', () {
    expect(ago(const Duration(seconds: 20)), 'Just now');
  });

  test('a clock running behind the server does not go negative', () {
    /// Phone clocks drift; "in 30 seconds" has no wording here and would read
    /// as a bug.
    expect(
      relativeTime(l10n, DateTime.now().add(const Duration(seconds: 30))),
      'Just now',
    );
  });

  test('minutes, then hours, then days', () {
    expect(ago(const Duration(minutes: 1)), '1 minute ago');
    expect(ago(const Duration(minutes: 59)), '59 minutes ago');
    expect(ago(const Duration(hours: 1)), '1 hour ago');
    expect(ago(const Duration(hours: 23)), '23 hours ago');
    expect(ago(const Duration(days: 1)), '1 day ago');
    expect(ago(const Duration(days: 6)), '6 days ago');
  });

  test('past a week it becomes a date', () {
    /// "Twelve days ago" is read as "a while": the date at least answers a
    /// different question precisely.
    final when = DateTime.now().subtract(const Duration(days: 40));
    final text = ago(const Duration(days: 40));
    expect(text, contains('${when.year}'));
    expect(text, isNot(contains('ago')));
  });
}
