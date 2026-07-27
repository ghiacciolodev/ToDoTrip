import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/providers.dart';
import '../../../core/theme/avatar_color.dart';
import '../../../core/theme/colors.dart';
import '../providers.dart';

/// Adding an expense.
///
/// A full screen rather than a sheet: there are five decisions to make, and a
/// sheet with the keyboard up leaves no room for any of them.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  /// Custom amounts keyed by user id. Only populated in custom mode.
  final _customShares = <String, TextEditingController>{};

  String? _paidBy;
  Set<String> _participants = {};
  bool _customSplit = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defaults that are right most of the time: you paid, everyone shares.
    final myId = ref.read(authProvider).value?.id;
    final members = ref.read(activeMembersProvider(widget.tripId));
    _paidBy = myId;
    _participants = {for (final m in members) m.user.id};
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    for (final controller in _customShares.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Money get _total => Money.tryParse(_amount.text) ?? const Money(0);

  /// Even split computed locally so the per-person figure updates as you type.
  /// The server recomputes it on save; this is preview only.
  Map<String, int> get _evenShares {
    final ids = _participants.toList();
    if (ids.isEmpty || _total.isZero) return {};

    final base = _total.cents ~/ ids.length;
    final remainder = _total.cents % ids.length;
    // Leftover cents go to the payer first, mirroring the backend's rule.
    ids.sort((a, b) => (a == _paidBy ? 0 : 1).compareTo(b == _paidBy ? 0 : 1));
    return {
      for (final (index, id) in ids.indexed)
        id: base + (index < remainder ? 1 : 0),
    };
  }

  Map<String, int> get _customSharesCents => {
    for (final id in _participants)
      id: Money.tryParse(_customShares[id]?.text ?? '')?.cents ?? 0,
  };

  /// How far the custom split is from the total. Zero means it can be saved.
  int get _remainingCents =>
      _total.cents - _customSharesCents.values.fold(0, (a, b) => a + b);

  bool get _canSave {
    if (_total.cents <= 0) return false;
    if (_description.text.trim().isEmpty) return false;
    if (_participants.isEmpty) return false;
    if (_customSplit && _remainingCents != 0) return false;
    return true;
  }

  void _toggleParticipant(String userId) {
    setState(() {
      if (_participants.contains(userId)) {
        _participants.remove(userId);
        _customShares.remove(userId)?.dispose();
      } else {
        _participants.add(userId);
      }
      _error = null;
    });
  }

  void _enterCustomMode() {
    // Seed the fields with the even split, so switching does not wipe the work.
    final even = _evenShares;
    for (final id in _participants) {
      _customShares[id] ??= TextEditingController(
        text: even[id] == null ? '' : Money(even[id]!).plain,
      );
    }
    setState(() => _customSplit = true);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(expenseRepositoryProvider)
          .create(
            tripId: widget.tripId,
            description: _description.text.trim(),
            amountCents: _total.cents,
            paidBy: _paidBy!,
            participants: _participants.toList(),
            shares: _customSplit ? _customSharesCents : null,
          );
      invalidateMoney(ref, widget.tripId);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(activeMembersProvider(widget.tripId));
    final myId = ref.watch(authProvider).value?.id;
    final even = _evenShares;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseNewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Amount first and large: it is the only thing the user came here
            // to type, and everything below is a refinement of it.
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() => _error = null),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '€ ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(labelText: l10n.expenseWhatFor),
            ),
            const SizedBox(height: 10),

            // One tap instead of ten letters, for the handful of things groups
            // actually spend on.
            Wrap(
              spacing: 8,
              children: [
                for (final suggestion in [
                  l10n.expenseSuggestionExamples,
                  l10n.expenseSuggestionGroceries,
                  l10n.expenseSuggestionTaxi,
                  l10n.expenseSuggestionHotel,
                  l10n.expenseSuggestionDrinks,
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _description.text = suggestion;
                      setState(() {});
                    },
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            _Label(l10n.expensePaidBy),
            // RadioGroup owns the selection now; the tiles below only declare
            // their value.
            RadioGroup<String>(
              groupValue: _paidBy,
              onChanged: (v) => setState(() => _paidBy = v),
              child: Card(
                child: Column(
                  children: [
                    for (final (index, member) in members.indexed) ...[
                      if (index > 0) const Divider(height: 1),
                      RadioListTile<String>(
                        value: member.user.id,
                        dense: true,
                        activeColor: Theme.of(context).colorScheme.primary,
                        title: Text(
                          member.user.id == myId
                              ? 'You'
                              : member.user.displayName,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _Label(l10n.expenseSplitBetween)),
                TextButton(
                  onPressed: () {
                    if (_customSplit) {
                      setState(() => _customSplit = false);
                    } else {
                      _enterCustomMode();
                    }
                  },
                  child: Text(
                    _customSplit
                        ? l10n.expenseSplitEqually
                        : l10n.expenseCustomAmounts,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            Card(
              child: Column(
                children: [
                  for (final (index, member) in members.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _ParticipantRow(
                      name: member.user.id == myId
                          ? 'You'
                          : member.user.displayName,
                      userId: member.user.id,
                      selected: _participants.contains(member.user.id),
                      onToggle: () => _toggleParticipant(member.user.id),
                      customSplit: _customSplit,
                      controller: _customShares[member.user.id],
                      evenShare: even[member.user.id],
                      onCustomChanged: () => setState(() => _error = null),
                    ),
                  ],
                ],
              ),
            ),

            // The visual counterpart of the backend's invariant: shares must
            // add up to the total. Shown live, so the rejection never happens.
            if (_customSplit) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.expenseRemaining,
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                  Text(
                    Money(_remainingCents).formatted,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _remainingCents == 0
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.terracotta,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
            FilledButton(
              onPressed: (_canSave && !_busy) ? _save : null,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.expenseSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.name,
    required this.userId,
    required this.selected,
    required this.onToggle,
    required this.customSplit,
    required this.controller,
    required this.evenShare,
    required this.onCustomChanged,
  });

  final String name;
  final String userId;
  final bool selected;
  final VoidCallback onToggle;
  final bool customSplit;
  final TextEditingController? controller;
  final int? evenShare;
  final VoidCallback onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: customSplit ? null : onToggle,
      leading: Checkbox(
        value: selected,
        onChanged: (_) => onToggle(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: selected
                ? avatarColorFor(userId)
                : AppColors.border,
            child: Text(
              initialsFor(name),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.inkMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: 96,
        child: !selected
            ? null
            : customSplit
            ? TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => onCustomChanged(),
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixText: '€',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              )
            : Text(
                evenShare == null ? '—' : Money(evenShare!).formatted,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
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
