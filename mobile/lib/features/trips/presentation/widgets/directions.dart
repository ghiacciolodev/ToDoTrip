import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/colors.dart';

/// Hands a destination to whatever the phone uses for navigation.
///
/// The universal Google Maps URL opens the installed app when there is one and
/// the browser otherwise, on both platforms, without writing two code paths.
/// On iOS Apple Maps is offered as well, because for many people it is the
/// default and the one that knows their car.
Future<void> openDirections(
  BuildContext context, {
  required double latitude,
  required double longitude,
  required String label,
}) async {
  final google = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
  );

  if (!Platform.isIOS) {
    await _launch(context, google);
    return;
  }

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map_outlined, color: AppColors.inkMuted),
            title: Text(AppLocalizations.of(context).mapAppleMaps),
            onTap: () => Navigator.of(context).pop('apple'),
          ),
          ListTile(
            leading: const Icon(
              Icons.navigation_outlined,
              color: AppColors.inkMuted,
            ),
            title: Text(AppLocalizations.of(context).mapGoogleMaps),
            onTap: () => Navigator.of(context).pop('google'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  await _launch(
    context,
    choice == 'apple'
        ? Uri.parse(
            'https://maps.apple.com/?daddr=$latitude,$longitude&q=$label',
          )
        : google,
  );
}

Future<void> _launch(BuildContext context, Uri url) async {
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorNoMapsApp)),
      );
  }
}
