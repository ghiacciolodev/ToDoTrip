import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import 'widgets/trip_sheets.dart';

/// The middle tab: the two ways a trip enters the app.
///
/// Both actions return to the trips tab on success, so the user ends up
/// looking at the thing they just created rather than at this screen again.
class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final created = await showCreateTripSheet(context);
    if (created == true && context.mounted) context.go('/trips');
  }

  Future<void> _join(BuildContext context) async {
    final joined = await showJoinTripSheet(context);
    if (joined == true && context.mounted) context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).addTripTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionCard(
                    icon: Icons.add_location_alt_outlined,
                    title: AppLocalizations.of(context).addTripCreate,
                    subtitle: AppLocalizations.of(context).addTripCreateBody,
                    onTap: () => _create(context),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.qr_code_2_outlined,
                    title: AppLocalizations.of(context).addTripJoin,
                    subtitle: AppLocalizations.of(context).addTripJoinBody,
                    onTap: () => _join(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
