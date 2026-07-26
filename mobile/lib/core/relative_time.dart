import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// How long ago something happened, in the words people use for it.
///
/// Past a week the count stops carrying information — "twelve days ago" is read
/// as "a while back" — so it becomes the date, which at least answers a
/// different question precisely.
String relativeTime(AppLocalizations l10n, DateTime when) {
  // Absolute difference, so a UTC timestamp from the server and a local clock
  // still subtract correctly.
  final elapsed = DateTime.now().difference(when);

  // A phone running a minute behind the server would otherwise land on a
  // negative duration, which has no wording here.
  if (elapsed.inMinutes < 1) return l10n.commonJustNow;
  if (elapsed.inHours < 1) return l10n.commonMinutesAgo(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.commonHoursAgo(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.commonDaysAgo(elapsed.inDays);
  return DateFormat.yMMMd().format(when.toLocal());
}
