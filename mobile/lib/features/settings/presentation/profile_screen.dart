import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/providers.dart';
import '../../../core/theme/avatar_color.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// Profile and account security, in the order these things get used: the name
/// people see, then the password, then the way out.
///
/// The email is shown and not editable. Repointing an account at a different
/// address has to prove that address belongs to the person asking, or it becomes
/// a way to take over an account; that needs a mail round trip the app has no
/// sender for yet, so it is honest to show the address rather than offer an edit
/// that would have to be refused.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.authNameEmpty);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).updateProfile(name);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox.shrink();

    // Seeded once. Reassigning on every rebuild would fight the keyboard and
    // move the cursor while someone is typing.
    if (!_loaded) {
      _name.text = user.displayName;
      _email.text = user.email;
      _loaded = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: avatarColorFor(user.email),
              child: Text(
                initialsFor(user.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _save(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(labelText: l10n.authNameLabel),
          ),
          const SizedBox(height: 16),

          TextField(
            enabled: false,
            controller: _email,
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              helperText: l10n.profileEmailLocked,
              helperMaxLines: 2,
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: _error!),
          ],

          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.commonSave),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profileChangePassword),
            subtitle: Text(l10n.profileChangePasswordBody),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.inkMuted,
            ),
            onTap: () => showChangePasswordSheet(context),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _busy ? null : () => _confirmDelete(context),
            icon: const Icon(Icons.person_off_outlined, size: 20),
            label: Text(l10n.profileDeleteAccount),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.profileDeleteConfirm,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      // The router redirects on the next frame; this widget goes with it.
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          // The server answers 409 with "still_owns_trips" and the ids. The
          // reader does not need the ids, they need to know which action
          // unblocks this.
          _error = e.code == 'still_owns_trips'
              ? l10n.profileDeleteOwnsTrips
              : friendlyError(context, e);
        });
      }
    }
  }
}

/// Changing a password ends every session the account has.
///
/// A sheet rather than a screen, and three fields rather than two: the
/// confirmation catches a typo that would otherwise lock someone out of their
/// own account with no way back in.
Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ChangePasswordForm(),
  );
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm();

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _current = TextEditingController();
  final _replacement = TextEditingController();
  final _confirmation = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _replacement.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_replacement.text.length < 8) {
      setState(() => _error = l10n.authPasswordTooShort);
      return;
    }
    if (_replacement.text != _confirmation.text) {
      setState(() => _error = l10n.profilePasswordMismatch);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(_current.text, _replacement.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.profilePasswordChanged)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          // 401 here means one thing only, and naming it saves a reader from
          // wondering whether their session died.
          () => _error = e.statusCode == 401
              ? l10n.profileWrongPassword
              : friendlyError(context, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileChangePassword,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileChangePasswordWarning,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _current,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.profileCurrentPassword,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _replacement,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.profileNewPassword,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmation,
                  obscureText: true,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.profileRepeatPassword,
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _InlineError(message: _error!),
                ],

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon plus text, not colour alone, so the message still reads for
/// colour-blind users.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.terracotta,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
