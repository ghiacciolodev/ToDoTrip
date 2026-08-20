import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_messages.dart';
import '../../../core/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/privacy_screen.dart';

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

  /// Consent, and the server checks it too.
  ///
  /// Starts false and is never pre-ticked: a box already checked when the
  /// screen opens is not consent, it is a decoration.
  bool _acceptedPrivacy = false;

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
      // Cleared on the way out, so coming back to the form never finds consent
      // already given by a previous visit.
      _acceptedPrivacy = false;
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

                    if (_isRegistering) ...[
                      const SizedBox(height: 8),
                      _PrivacyConsent(
                        value: _acceptedPrivacy,
                        onChanged: (value) => setState(() {
                          _acceptedPrivacy = value;
                          _clearError();
                        }),
                      ),
                    ],

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

/// One line of the consent sentence, in logical pixels.
///
/// Shared by the sentence and the box beside it: they have to be the same
/// height or the row reads as crooked.
const _consentLineHeight = 20.0;
const _consentFontSize = 13.5;

/// The consent tick, with the policy one tap away.
///
/// A [FormField] rather than a bare [Checkbox] so it fails validation in the
/// same place and the same style as the email and password fields, instead of
/// the form submitting and the server answering with a 422.
///
/// The policy opens in a page rather than a dialog: it is long, and a consent
/// nobody can comfortably read is not much of a consent.
class _PrivacyConsent extends StatelessWidget {
  const _PrivacyConsent({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FormField<bool>(
      initialValue: value,
      validator: (_) => value ? null : l10n.authPrivacyRequired,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              onChanged(!value);
              state.didChange(!value);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exactly one line of the sentence tall, so the box centres
                  // against the first line instead of against the paragraph.
                  // Start-aligning a 24-high box next to a 20-high line is what
                  // made this row look crooked.
                  SizedBox(
                    height: _consentLineHeight,
                    width: 22,
                    child: Checkbox(
                      value: value,
                      // Handled by the row: two tap targets stacked on each
                      // other would toggle twice on the checkbox itself.
                      onChanged: (checked) {
                        onChanged(checked ?? false);
                        state.didChange(checked ?? false);
                      },
                      activeColor: theme.colorScheme.primary,
                      side: const BorderSide(
                        color: AppColors.inkMuted,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _ConsentSentence()),
                ],
              ),
            ),
          ),
          if (state.hasError)
            Padding(
              // Under the sentence, not under the box.
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                state.errorText!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// "I have read and accept the privacy policy", with the last words tappable.
///
/// Built by finding the link text inside the translated sentence rather than
/// gluing two strings together, because the order of the words is not the same
/// in every language.
class _ConsentSentence extends StatefulWidget {
  @override
  State<_ConsentSentence> createState() => _ConsentSentenceState();
}

class _ConsentSentenceState extends State<_ConsentSentence> {
  final _recognizer = TapGestureRecognizer();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final link = l10n.authPrivacyPolicyLink;
    final sentence = l10n.authPrivacyAccept(link);
    final at = sentence.indexOf(link);

    _recognizer.onTap = () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()));

    final base = TextStyle(
      fontSize: _consentFontSize,
      height: _consentLineHeight / _consentFontSize,
      color: AppColors.ink,
    );
    // A translation that dropped the placeholder would otherwise lose the link
    // entirely; plain text is a worse outcome than a broken one is a crash.
    if (at < 0) return Text(sentence, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: sentence.substring(0, at)),
          TextSpan(
            text: link,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
            recognizer: _recognizer,
          ),
          TextSpan(text: sentence.substring(at + link.length)),
        ],
      ),
    );
  }
}
