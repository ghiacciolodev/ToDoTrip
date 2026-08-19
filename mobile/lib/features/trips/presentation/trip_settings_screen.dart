import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/theme/avatar_color.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/trip.dart';
import '../data/trip_identity.dart';
import '../data/trip_member.dart';
import '../providers.dart';
import 'widgets/member_actions.dart';
import 'widgets/trip_card.dart';
import 'widgets/trip_pickers.dart';

/// The trip as an object, as opposed to what is inside it. Members stay in the
/// Group tab; this is the trip itself.
///
/// Laid out by who may do what, because that is the load-bearing rule here. The
/// edit fields are visible to everyone and editable only by the owner — knowing
/// the trip's currency is everybody's business, changing it is not — while the
/// destructive actions are not rendered at all for anyone else. A button that
/// can only ever produce a 403 is worse than no button.
class TripSettingsScreen extends ConsumerStatefulWidget {
  const TripSettingsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripSettingsScreen> createState() => _TripSettingsScreenState();
}

class _TripSettingsScreenState extends ConsumerState<TripSettingsScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _currency = TextEditingController();

  DateTimeRange? _dates;
  String? _icon;
  String? _color;

  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _seed(Trip trip) {
    _name.text = trip.name;
    _description.text = trip.description ?? '';
    _currency.text = trip.baseCurrency;
    _icon = trip.icon;
    _color = trip.color;
    _dates = (trip.startDate != null && trip.endDate != null)
        ? DateTimeRange(start: trip.startDate!, end: trip.endDate!)
        : null;
    _loaded = true;
  }

  /// True when something on the form differs from what the server holds.
  ///
  /// Saving on every keystroke would mean one PATCH per letter typed, so the
  /// button is explicit — and it stays disabled until there is something to
  /// save, which is also how you can tell the save worked.
  bool _dirty(Trip trip) {
    final dates = (trip.startDate != null && trip.endDate != null)
        ? DateTimeRange(start: trip.startDate!, end: trip.endDate!)
        : null;
    return _name.text.trim() != trip.name ||
        _description.text.trim() != (trip.description ?? '') ||
        _currency.text.trim().toUpperCase() != trip.baseCurrency ||
        _icon != trip.icon ||
        _color != trip.color ||
        _dates?.start != dates?.start ||
        _dates?.end != dates?.end;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = ref.watch(tripProvider(widget.tripId)).value;
    final me = ref.watch(myMembershipProvider(widget.tripId));
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_loaded) _seed(trip);

    final isOwner = me?.role == MemberRole.owner;
    final unsaved = isOwner && _dirty(trip);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripSettingsTitle)),
      // Pinned to the bottom and present only while there is something to save.
      //
      // A button sitting in the middle of a long scrolling list, greyed out
      // because nothing has changed yet, is easy to scroll past and easy to
      // mistake for decoration. This way there is nothing to miss when there is
      // nothing to do, and when there is, it cannot scroll away.
      bottomNavigationBar: unsaved
          ? _SaveBar(busy: _busy, error: _error, onSave: () => _save(trip))
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // The card as the list will draw it, updated as the form is edited:
          // it is the only way to see what a colour or an icon actually does
          // without saving and going back.
          TripCard(
            trip: trip.copyWith(
              name: _name.text.trim().isEmpty
                  ? l10n.tripFallbackName
                  : _name.text.trim(),
              description: _description.text.trim(),
              icon: _icon,
              color: _color,
              startDate: _dates?.start,
              endDate: _dates?.end,
            ),
          ),
          if (trip.isArchived) ...[
            const SizedBox(height: 12),
            _ArchivedBanner(),
          ],
          const SizedBox(height: 28),

          _SectionLabel(l10n.tripSettingsEdit),
          _Group(
            children: [
              if (isOwner)
                _EditFields(
                  name: _name,
                  description: _description,
                  currency: _currency,
                  dates: _dates,
                  icon: _icon,
                  color: _color,
                  onDates: (value) => setState(() => _dates = value),
                  onIcon: (key) =>
                      setState(() => _icon = _icon == key ? null : key),
                  onColor: (key) => setState(() => _color = key),
                  onChanged: () => setState(() {}),
                )
              else
                _ReadOnlyFields(trip: trip),
            ],
          ),

          // Failures from archiving, deleting or exporting: a save failure is
          // shown in the save bar instead, next to the button that caused it.
          if (_error != null && !unsaved) ...[
            const SizedBox(height: 16),
            _InlineError(message: _error!),
          ],
          const SizedBox(height: 32),

          _SectionLabel(l10n.tripSettingsInfo),
          _Group(
            children: [_Facts(trip: trip, onExport: () => _export(trip))],
          ),
          const SizedBox(height: 32),

          _SectionLabel(l10n.tripSettingsPersonal),
          _Group(
            children: [
              _MuteSwitch(tripId: widget.tripId),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.exit_to_app,
                  color: AppColors.terracotta,
                ),
                title: Text(
                  l10n.groupLeaveTrip,
                  style: const TextStyle(color: AppColors.terracotta),
                ),
                onTap: () => confirmLeaveTrip(
                  context,
                  ref,
                  trip: trip,
                  memberCount: trip.memberCount,
                ),
              ),
            ],
          ),

          if (isOwner) ...[
            const SizedBox(height: 48),
            _SectionLabel(l10n.tripSettingsDanger, danger: true),
            _Group(
              children: [
                ListTile(
                  leading: Icon(
                    trip.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  title: Text(
                    trip.isArchived ? l10n.tripUnarchive : l10n.tripArchive,
                  ),
                  subtitle: trip.isArchived ? null : Text(l10n.tripArchiveBody),
                  isThreeLine: !trip.isArchived,
                  onTap: _busy ? null : () => _toggleArchive(trip),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.terracotta,
                  ),
                  title: Text(
                    l10n.groupDeleteTrip,
                    style: const TextStyle(color: AppColors.terracotta),
                  ),
                  onTap: _busy ? null : () => _confirmDelete(trip),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.tripNameEmpty);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tripRepositoryProvider)
          .update(
            widget.tripId,
            name: name,
            description: _description.text.trim(),
            baseCurrency: _currency.text.trim().toUpperCase(),
            icon: _icon,
            color: _color,
            startDate: _dates?.start,
            endDate: _dates?.end,
          );
      ref.invalidate(tripsProvider);
      // Awaited, and the form is deliberately not re-seeded. `invalidate` keeps
      // the previous value in `.value` while the refetch is in flight, so
      // re-seeding here would fill the fields with what the trip looked like
      // before the save — the edit would appear to have been undone.
      // Awaited so the provider holds the saved trip before this returns, and
      // the form stops reading as unsaved.
      ref.invalidate(tripProvider(widget.tripId));
      await ref.read(tripProvider(widget.tripId).future);
      if (mounted) _toast(l10n.tripSaved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleArchive(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    if (!trip.isArchived) {
      final confirmed = await showAdaptiveDialog<bool>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: Text(l10n.tripArchiveTitle),
          content: Text(l10n.tripArchiveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.tripArchive),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .update(widget.tripId, archived: !trip.isArchived);
      ref.invalidate(tripProvider(widget.tripId));
      ref.invalidate(tripsProvider);
      ref.invalidate(archivedTripsProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    // Two taps for an irreversible action on other people's records: a dialog,
    // then the confirmation inside it. Typing the trip name would be an
    // enterprise-tool pattern and out of scale here.
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.tripDeleteTitle(trip.name)),
        // Names what is lost and for whom: the owner is destroying other
        // people's accounting history, not only their own.
        content: Text(l10n.tripDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(tripRepositoryProvider).delete(widget.tripId);
      ref.invalidate(tripsProvider);
      if (mounted) context.go('/trips');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = friendlyError(context, e);
        });
      }
    }
  }

  Future<void> _export(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    if (trip.expenseCount == 0) {
      _toast(l10n.tripExportEmpty);
      return;
    }

    setState(() => _busy = true);
    try {
      final file = await ref
          .read(tripRepositoryProvider)
          .exportCsv(widget.tripId);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          // Straight from memory: writing it to disk first would leave a copy
          // of the group's ledger in a cache directory nobody cleans.
          files: [
            XFile.fromData(
              Uint8List.fromList(file.bytes),
              mimeType: 'text/csv',
              name: file.filename,
            ),
          ],
          fileNameOverrides: [file.filename],
          text: l10n.tripExportShareText(trip.name),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _toast(friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Silences this trip, for the caller and nobody else.
///
/// Its own little widget with its own state so a slow request cannot make the
/// switch stutter: it flips first and asks after, and puts itself back if the
/// server disagrees.
class _MuteSwitch extends ConsumerStatefulWidget {
  const _MuteSwitch({required this.tripId});

  final String tripId;

  @override
  ConsumerState<_MuteSwitch> createState() => _MuteSwitchState();
}

class _MuteSwitchState extends ConsumerState<_MuteSwitch> {
  bool? _muted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final muted = await ref
          .read(tripRepositoryProvider)
          .isMuted(widget.tripId);
      if (mounted) setState(() => _muted = muted);
    } on ApiException {
      // Leave the switch out rather than showing a guess.
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _muted = value);
    try {
      await ref.read(tripRepositoryProvider).setMuted(widget.tripId, value);
    } on ApiException {
      if (mounted) setState(() => _muted = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = _muted;
    // Nothing at all until it is known: a switch that starts off and jumps on
    // a moment later has already told the reader something false.
    if (muted == null) return const SizedBox.shrink();

    return SwitchListTile.adaptive(
      value: muted,
      onChanged: _toggle,
      title: Text(l10n.settingsMuteTrip),
      subtitle: Text(l10n.settingsMuteTripBody),
      secondary: Icon(
        muted ? Icons.notifications_off_outlined : Icons.notifications_none,
      ),
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// The bar that appears the moment something is edited.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.busy,
    required this.error,
    required this.onSave,
  });

  final bool busy;
  final String? error;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      // A hairline, not a shadow: it has to read as the edge of the page, not
      // as a card floating over it.
      shape: const Border(top: BorderSide(color: AppColors.border)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                _InlineError(message: error!),
                const SizedBox(height: 12),
              ] else ...[
                // Says why the bar turned up, so it does not read as a button
                // that was always there.
                Text(
                  l10n.tripUnsavedChanges,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: busy ? null : onSave,
                child: busy
                    ? const _ButtonSpinner()
                    : Text(l10n.tripSaveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The owner's version of the form.
class _EditFields extends StatelessWidget {
  const _EditFields({
    required this.name,
    required this.description,
    required this.currency,
    required this.dates,
    required this.icon,
    required this.color,
    required this.onDates,
    required this.onIcon,
    required this.onColor,
    required this.onChanged,
  });

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController currency;
  final DateTimeRange? dates;
  final String? icon;
  final String? color;
  final ValueChanged<DateTimeRange?> onDates;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onColor;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(labelText: l10n.tripNameLabel),
          ),
          const SizedBox(height: 18),

          PickerLabel(l10n.tripIconLabel),
          const SizedBox(height: 8),
          IconPicker(
            selected: icon,
            colour: tripColors[color] ?? Theme.of(context).colorScheme.primary,
            onPick: onIcon,
          ),
          const SizedBox(height: 18),

          PickerLabel(l10n.tripColorLabel),
          const SizedBox(height: 8),
          ColorPicker(selected: color, onPick: onColor),
          const SizedBox(height: 18),

          // A trip can lose its dates as easily as it can gain them.
          OutlinedButton.icon(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
                initialDateRange: dates,
              );
              if (picked != null) onDates(picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              dates == null
                  ? l10n.tripAddDates
                  : '${DateFormat.yMMMd().format(dates!.start)} – '
                        '${DateFormat.yMMMd().format(dates!.end)}',
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
          if (dates != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onDates(null),
                child: Text(
                  l10n.tripClearDates,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ),
            ),
          const SizedBox(height: 12),

          TextField(
            controller: description,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            maxLength: 2000,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: l10n.tripDescriptionLabel,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: currency,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: l10n.tripCurrencyLabel,
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          // Spelled out, not an asterisk. Amounts are stored as integer cents
          // with no exchange rate: 5000 stays 5000 whether it is called euros
          // or dollars. Someone switching currency after thirty expenses,
          // expecting a conversion, ends up with wrong accounts and no way to
          // notice.
          _Warning(text: l10n.tripCurrencyWarning),
        ],
      ),
    );
  }
}

/// What everybody else sees: the same facts, without a field around them.
class _ReadOnlyFields extends StatelessWidget {
  const _ReadOnlyFields({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _Fact(label: l10n.tripNameLabel, value: trip.name),
        if (trip.description?.trim().isNotEmpty ?? false)
          _Fact(
            label: l10n.tripDescriptionLabel,
            value: trip.description!.trim(),
          ),
        _Fact(
          label: l10n.tripCurrencyLabel,
          // Knowing which currency the trip counts in matters to everyone;
          // only changing it is the owner's business.
          value: trip.baseCurrency,
        ),
      ],
    );
  }
}

class _Facts extends ConsumerWidget {
  const _Facts({required this.trip, required this.onExport});

  final Trip trip;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final author = trip.createdByName ?? l10n.commonUnknown;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: avatarColorFor(trip.createdBy),
            child: Text(
              initialsFor(author),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            l10n.tripCreatedByOn(
              author,
              DateFormat.yMMMd().format(trip.createdAt.toLocal()),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${trip.memberCount}',
                  label: l10n.tripStatMembers(trip.memberCount),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: '${trip.expenseCount}',
                  label: l10n.tripStatExpenses(trip.expenseCount),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: '${trip.itemCount}',
                  label: l10n.tripStatItems(trip.itemCount),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          title: Text(l10n.tripTotalSpent),
          trailing: Text(
            Money(trip.totalSpentCents).formattedIn(trip.baseCurrency),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: Text(l10n.tripExportCsv),
          onTap: onExport,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: AppColors.ink, fontSize: 15),
      ),
    );
  }
}

class _ArchivedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Warning(text: AppLocalizations.of(context).tripArchivedBanner);
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.terracotta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: danger ? AppColors.terracotta : AppColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

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
