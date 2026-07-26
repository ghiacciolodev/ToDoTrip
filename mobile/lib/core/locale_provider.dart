import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The five languages the app ships in. English is the development language and
/// the template every other file is translated from.
const supportedLanguages = ['en', 'it', 'fr', 'de', 'es'];

/// Which language the app speaks: the system's, or one the user picked.
///
/// Null means "follow the system", which is the default and the right one — a
/// phone set to Italian should open in Italian without anyone choosing. The
/// override exists for people whose device language is not the one they read
/// comfortably, which is common on shared or second-hand phones.
class LocaleController extends AsyncNotifier<Locale?> {
  static const _key = 'locale';

  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null || !supportedLanguages.contains(code)) return null;
    return Locale(code);
  }

  /// Null restores "follow the system".
  Future<void> select(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Each language named in itself.
///
/// Not translated: someone hunting for their own language scans for "Deutsch",
/// not for "German" written in a language they may not read.
String languageName(String code) => switch (code) {
  'it' => 'Italiano',
  'fr' => 'Français',
  'de' => 'Deutsch',
  'es' => 'Español',
  _ => 'English',
};
