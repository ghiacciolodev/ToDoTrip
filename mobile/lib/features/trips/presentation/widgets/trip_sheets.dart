import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../providers.dart';

/// Bottom sheets rather than dialogs: they read as native on both platforms,
/// and leave room for a keyboard without the content jumping.
///
/// Both resolve to `true` when something was actually created or joined, so the
/// caller can navigate to the trips tab instead of leaving the user staring at
/// the screen they just acted on.
Future<bool?> showCreateTripSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SheetShell(child: _CreateTripForm()),
  );
}

Future<bool?> showJoinTripSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SheetShell(child: _JoinTripForm()),
  );
}

/// Keyboard-safe container for sheet content.
///
/// No field inside autofocuses: the keyboard would start rising while the sheet
/// is still animating in, and the two competing animations make the content
/// jump. The user taps a field when they are ready, and the sheet is settled by
/// then.
///
/// Scrollable because the keyboard can leave less room than the form needs;
/// scrolling is always better than an overflow.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        // Matches the platform keyboard animation, so the content follows it
        // smoothly instead of snapping.
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CreateTripForm extends ConsumerStatefulWidget {
  const _CreateTripForm();

  @override
  ConsumerState<_CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends ConsumerState<_CreateTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  DateTimeRange? _dates;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    // Dismiss the keyboard first: the date picker over a raised sheet with the
    // keyboard still up leaves almost no usable height.
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dates,
    );
    if (picked != null && mounted) setState(() => _dates = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(tripRepositoryProvider)
          .create(
            name: _name.text.trim(),
            startDate: _dates?.start,
            endDate: _dates?.end,
          );
      // Marks the list stale so it refetches; no manual cache surgery.
      ref.invalidate(tripsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tripNewTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _busy ? null : _submit(),
            decoration: InputDecoration(labelText: l10n.tripNameLabel),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.tripNameEmpty : null,
          ),
          const SizedBox(height: 12),

          // Dates are optional on purpose: a trip is usually created before
          // anyone has agreed on when it happens.
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickDates,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              _dates == null ? l10n.tripAddDates : _formatRange(_dates!),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          if (_dates != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : () => setState(() => _dates = null),
                child: Text(
                  l10n.tripClearDates,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: _error!),
          ],

          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const _ButtonSpinner() : Text(l10n.tripCreate),
          ),
        ],
      ),
    );
  }

  static String _formatRange(DateTimeRange range) =>
      '${range.start.day}/${range.start.month} – ${range.end.day}/${range.end.month}';
}

class _JoinTripForm extends ConsumerStatefulWidget {
  const _JoinTripForm();

  @override
  ConsumerState<_JoinTripForm> createState() => _JoinTripFormState();
}

class _JoinTripFormState extends ConsumerState<_JoinTripForm> {
  final _code = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = l10n.tripJoinCodeEmpty);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(tripRepositoryProvider).joinByCode(code);
      ref.invalidate(tripsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        // The API answers 400 for unknown, revoked, expired and exhausted
        // codes alike; the user can act on all four the same way.
        setState(
          () => _error = e.statusCode == 400
              ? l10n.errorInvalidCode
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tripJoinTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(l10n.tripJoinBody, style: TextStyle(color: AppColors.inkMuted)),
        const SizedBox(height: 20),

        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 8,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _busy ? null : _submit(),
          // Codes get dictated out loud, so they are shown large and spaced.
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: l10n.inviteCodeHint,
            counterText: '',
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: _error!),
        ],

        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const _ButtonSpinner() : Text(l10n.tripJoin),
        ),
      ],
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

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
    );
  }
}
