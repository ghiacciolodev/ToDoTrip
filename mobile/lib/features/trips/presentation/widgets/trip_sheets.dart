import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../data/trip_identity.dart';
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
  final _description = TextEditingController();

  DateTimeRange? _dates;
  String? _icon;
  late String _color;
  bool _details = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A colour is drawn rather than left blank so the preview is honest about
    // what the card will look like, and so a list of trips stays varied for
    // people who skip this step. The icon can stay unset: the skyline it falls
    // back to is a neutral statement, while a random glyph would claim the trip
    // is about mountains or sailing when nobody said so.
    _color = tripColors.keys.elementAt(Random().nextInt(tripColors.length));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
            description: _description.text.trim(),
            startDate: _dates?.start,
            endDate: _dates?.end,
            icon: _icon,
            color: _color,
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
          const SizedBox(height: 16),

          // The card the trip will appear as, drawn while it is being filled
          // in: picking an icon out of a grid means nothing until you see it in
          // the shape it will actually take.
          _Preview(
            name: _name,
            icon: _icon,
            color: _color,
            description: _description,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _busy ? null : _submit(),
            decoration: InputDecoration(labelText: l10n.tripNameLabel),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.tripNameEmpty : null,
          ),
          const SizedBox(height: 16),

          _PickerLabel(l10n.tripIconLabel),
          const SizedBox(height: 8),
          _IconPicker(
            selected: _icon,
            colour: tripColors[_color]!,
            // Tapping the chosen one again clears it: the step stays skippable
            // after the fact, not only before.
            onPick: (key) => setState(() => _icon = _icon == key ? null : key),
          ),
          const SizedBox(height: 16),

          _PickerLabel(l10n.tripColorLabel),
          const SizedBox(height: 8),
          _ColorPicker(
            selected: _color,
            onPick: (key) => setState(() => _color = key),
          ),
          const SizedBox(height: 16),

          if (_details)
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: l10n.tripDescriptionLabel,
                counterText: '',
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _details = true),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.tripAddDescription),
              ),
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

/// The head of the card this trip is about to become.
///
/// Listens to the controllers directly rather than rebuilding the whole form on
/// every keystroke: the name has to appear as it is typed, and the sheet holds
/// two text fields, a date picker and twenty swatches.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final TextEditingController name;
  final TextEditingController description;
  final String? icon;
  final String color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final identity = TripIdentity.of(tripId: '', icon: icon, color: color);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: identity.colour.withValues(alpha: 0.10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: identity.colour,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  identity.icon,
                  key: ValueKey(identity.icon.codePoint),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([name, description]),
                builder: (context, _) {
                  final typed = name.text.trim();
                  final blurb = description.text.trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        typed.isEmpty ? l10n.tripFallbackName : typed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          // Greyed while it is still a placeholder, so nobody
                          // reads "Trip" as a name they have already given.
                          color: typed.isEmpty
                              ? AppColors.inkMuted
                              : AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (blurb.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          blurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// One scrolling row rather than a grid: twelve icons in a grid would push the
/// name field and the button off a small screen.
class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.colour,
    required this.onPick,
  });

  final String? selected;
  final Color colour;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tripIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = tripIcons.entries.elementAt(index);
          final chosen = entry.key == selected;
          return Semantics(
            selected: chosen,
            button: true,
            child: InkWell(
              onTap: () => onPick(entry.key),
              customBorder: const CircleBorder(),
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: chosen
                      ? colour.withValues(alpha: 0.14)
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chosen ? colour : AppColors.border,
                    width: chosen ? 2 : 1,
                  ),
                ),
                child: Icon(
                  entry.value,
                  size: 22,
                  color: chosen ? colour : AppColors.inkMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The eight palette colours. Always one selected: unlike the icon there is no
/// neutral colour to fall back to, so the choice is only ever changed.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onPick});

  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in tripColors.entries)
          Semantics(
            selected: entry.key == selected,
            button: true,
            child: InkWell(
              onTap: () => onPick(entry.key),
              customBorder: const CircleBorder(),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  // A ring set off the swatch rather than a tick drawn on it:
                  // a white tick disappears on the two lightest colours.
                  border: Border.all(
                    color: entry.key == selected
                        ? AppColors.ink
                        : Colors.transparent,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
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
