import 'package:flutter/material.dart';
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
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Sign out?'),
        content: const Text("You'll need your email and password to get back in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.terracotta)),
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
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (user != null) _ProfileCard(name: user.displayName, email: user.email),
          const SizedBox(height: 24),

          const _SectionLabel('Notifications'),
          _SettingsGroup(
            children: [
              SwitchListTile.adaptive(
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
                title: const Text('Push notifications'),
                subtitle: const Text('Trip updates and new tasks'),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(),
              SwitchListTile.adaptive(
                value: _expenseAlerts,
                onChanged: (v) => setState(() => _expenseAlerts = v),
                title: const Text('Expense alerts'),
                subtitle: const Text('When someone adds an expense'),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionLabel('Preferences'),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                trailing: const Text('English',
                    style: TextStyle(color: AppColors.inkMuted)),
                onTap: () => _showComingSoon(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.euro_outlined),
                title: const Text('Default currency'),
                trailing:
                const Text('EUR', style: TextStyle(color: AppColors.inkMuted)),
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _SectionLabel('About'),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: const Text('0.1.0',
                    style: TextStyle(color: AppColors.inkMuted)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.terracotta,
              side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
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
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
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