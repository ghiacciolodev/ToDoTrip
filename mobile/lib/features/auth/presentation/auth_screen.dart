import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_messages.dart';
import '../../../core/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// Sign in and sign up on one screen.
///
/// A single toggle rather than two routes: fewer screens, and switching mode
/// keeps whatever the user already typed.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  bool _isRegistering = false;
  bool _obscure = true;

  // Submission state is local, not read from authProvider: a rejected password
  // is a fact about this form, not about the session, and routing it through a
  // global provider would make the router react to it.
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final notifier = ref.read(authProvider.notifier);
      if (_isRegistering) {
        await notifier.register(
          _email.text.trim(),
          _password.text,
          _displayName.text.trim(),
        );
      } else {
        await notifier.login(_email.text.trim(), _password.text);
      }
      // On success the router redirects and this widget is disposed.
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _error = null;
    });
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              // Keeps the form readable on tablets and foldables.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 40),
                    Text(
                      _isRegistering
                          ? l10n.authCreateAccount
                          : l10n.authWelcomeBack,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.authTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 32),

                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _displayName,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.authNameLabel,
                        ),
                        onChanged: (_) => _clearError(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.authNameEmpty
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.authEmailLabel,
                      ),
                      // Cleared on edit: the banner refers to the previous
                      // attempt, and stale errors read as broken UI.
                      onChanged: (_) => _clearError(),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.authEmailEmpty;
                        if (!value.contains('@')) return l10n.authEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      onChanged: (_) => _clearError(),
                      decoration: InputDecoration(
                        labelText: l10n.authPasswordLabel,
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.authShowPassword
                              : l10n.authHidePassword,
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.authPasswordEmpty;
                        }
                        // Mirrors the backend's minimum, so a rejection never
                        // costs a round trip.
                        if (_isRegistering && v.length < 8) {
                          return l10n.authPasswordTooShort;
                        }
                        return null;
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      _ErrorBanner(message: _error!),
                    ],

                    const SizedBox(height: 28),

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
                          : Text(
                              _isRegistering
                                  ? l10n.authSignUp
                                  : l10n.authSignIn,
                            ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _busy ? null : _toggleMode,
                      child: Text(
                        _isRegistering
                            ? l10n.authSwitchToSignIn
                            : l10n.authSwitchToSignUp,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline failure notice.
///
/// Sits in the layout instead of floating away like a snack bar: the user is
/// mid-correction and needs to read it while retyping. Icon plus text, not
/// colour alone, so it still reads for colour-blind users.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.terracotta,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          // The same mark as the launcher icon, on the colour the user picked
          // in settings. Drawn from the wordmark's own T rather than a stock
          // glyph, so the app and its logo say the same thing.
          child: Image.asset(
            'assets/brand/mark.png',
            height: 38,
            color: Colors.white,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'TodoTrip',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
