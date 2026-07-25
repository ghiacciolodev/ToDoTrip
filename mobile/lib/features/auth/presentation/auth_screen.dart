import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/colors.dart';

/// Turns an API failure into copy a user can act on.
///
/// The backend answers "Invalid credentials" for both a wrong password and an
/// unknown email, deliberately, so that responses cannot be used to discover
/// which addresses are registered. The wording here preserves that ambiguity.
String _friendlyError(Object error) {
  if (error is! ApiException) return 'Something went wrong. Please try again.';

  return switch (error.statusCode) {
    401 => 'Incorrect email or password',
    409 => 'This email is already registered',
    422 => error.fieldErrors?.values.firstOrNull ?? 'Please check the details you entered',
    _ => error.message,
  };
}

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
      if (mounted) setState(() => _error = _friendlyError(error));
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
                      _isRegistering ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Plan trips together with your friends',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 32),

                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _displayName,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Name'),
                        onChanged: (_) => _clearError(),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      // Cleared on edit: the banner refers to the previous
                      // attempt, and stale errors read as broken UI.
                      onChanged: (_) => _clearError(),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your email';
                        if (!value.contains('@')) return 'Enter a valid email';
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
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your password';
                        // Mirrors the backend's minimum, so a rejection never
                        // costs a round trip.
                        if (_isRegistering && v.length < 8) {
                          return 'At least 8 characters';
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
                          : Text(_isRegistering ? 'Sign up' : 'Sign in'),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _busy ? null : _toggleMode,
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Sign up",
                        style: const TextStyle(color: AppColors.primaryDark),
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
          const Icon(Icons.error_outline, size: 20, color: AppColors.terracotta),
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.luggage_outlined, color: Colors.white, size: 38),
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