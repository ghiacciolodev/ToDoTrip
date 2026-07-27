import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: TodoTripApp()));
}

class TodoTripApp extends ConsumerWidget {
  const TodoTripApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null while the stored preference is read, and null again when the user
    // wants the system language: both mean "let Flutter resolve it".
    final locale = ref.watch(localeProvider).value;
    // The stored accent, or the brand teal for the frame or two it takes to
    // read it off the disk.
    final brand = ref.watch(brandProvider).value ?? defaultBrand;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(brand),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      // One place tells intl which language it is in, and from here every bare
      // DateFormat and every Money in the app formats itself correctly. Set in
      // the builder because it runs after the locale has been resolved, whether
      // that came from the user's choice or from the system.
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
