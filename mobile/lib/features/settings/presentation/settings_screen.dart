import 'package:flutter/material.dart';
import '../../../core/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/avatar_color.dart';
import '../../../core/theme/colors.dart';

/// Settings.
///
/// Most rows are placeholders for now: they render the final shape of the
/// screen without pretending to persist anything. Sign out is real.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local-only: not persisted, not wired to anything yet.
  bool _pushNotifications = true;
  bool _expenseAlerts = true;

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.settingsSignOutTitle),
        content: Text(l10n.settingsSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.settingsSignOut,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final selected = ref.watch(localeProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (user != null)
            _ProfileCard(name: user.displayName, email: user.email),
          const SizedBox(height: 24),

          _SectionLabel(l10n.settingsNotifications),
          _SettingsGroup(
            children: [
              SwitchListTile.adaptive(
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
                title: Text(l10n.settingsPushNotifications),
                subtitle: Text(l10n.settingsPushNotificationsBody),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(),
              SwitchListTile.adaptive(
                value: _expenseAlerts,
                onChanged: (v) => setState(() => _expenseAlerts = v),
                title: Text(l10n.settingsExpenseAlerts),
                subtitle: Text(l10n.settingsExpenseAlertsBody),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SectionLabel(l10n.settingsPreferences),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.settingsLanguage),
                trailing: Text(
                  selected == null
                      ? l10n.settingsLanguageSystem
                      : languageName(selected.languageCode),
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                onTap: _pickLanguage,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.euro_outlined),
                title: Text(l10n.settingsDefaultCurrency),
                trailing: const Text(
                  'EUR',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SectionLabel(l10n.settingsAbout),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsVersion),
                trailing: const Text(
                  '0.1.0',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.inkMuted,
                ),
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, size: 20),
            label: Text(l10n.settingsSignOut),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.terracotta,
              side: BorderSide(
                color: AppColors.terracotta.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lets the reader pick a language, or hand the choice back to the system.
  ///
  /// "System" is the default and stays first: a phone set to Italian should open
  /// in Italian without anyone choosing. The override is for people whose device
  /// language is not the one they read comfortably, which is common on shared or
  /// second-hand phones.
  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(localeProvider).value;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current?.languageCode ?? 'system',
          onChanged: (value) => Navigator.of(context).pop(value),
          child: ListView(
            shrinkWrap: true,
            children: [
              RadioListTile<String>(
                value: 'system',
                title: Text(l10n.settingsLanguageSystem),
                activeColor: AppColors.primary,
              ),
              for (final code in supportedLanguages)
                RadioListTile<String>(
                  value: code,
                  // Each language names itself: someone looking for their own
                  // language recognises "Deutsch", not "German".
                  title: Text(languageName(code)),
                  activeColor: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    await ref
        .read(localeProvider.notifier)
        .select(choice == 'system' ? null : Locale(choice));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonComingSoon)),
      );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColorFor(email),
              child: Text(
                initialsFor(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
