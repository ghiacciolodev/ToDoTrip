import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/item.dart';
import '../../providers.dart';

/// What the sheet is being opened to create.
///
/// Lists are not items on the server, but they are created the same way and from
/// the same button, so they share this form rather than a second one that would
/// drift from it.
enum AddKind { event, task, list }

/// Creates an event, a task or a list. The kind is fixed by the caller: the user
/// picked it by choosing a tab and a view, so asking again would be a redundant
/// decision.
Future<void> showAddItemSheet(
  BuildContext context,
  String tripId,
  AddKind kind,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddItemSheet(tripId: tripId, kind: kind),
  );
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({required this.tripId, required this.kind});

  final String tripId;
  final AddKind kind;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();

  DateTime? _startsAt;
  // A set, not a single id: two people can share one chore.
  final _assignedTo = <String>{};
  bool _busy = false;
  String? _error;

  bool get _isEvent => widget.kind == AddKind.event;
  bool get _isList => widget.kind == AddKind.list;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  /// Events must have a time — the API rejects one without it, since an undated
  /// event could never appear on a calendar.
  bool get _canSave =>
      _title.text.trim().isNotEmpty && (!_isEvent || _startsAt != null);

  Future<void> _pickDateTime() async {
    // Dismiss the keyboard first: a picker over a raised sheet with the
    // keyboard up leaves almost no usable height.
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isList) {
        await ref
            .read(checklistRepositoryProvider)
            .create(tripId: widget.tripId, name: _title.text.trim());
        ref.invalidate(checklistsProvider(widget.tripId));
      } else {
        await ref
            .read(itemRepositoryProvider)
            .create(
              tripId: widget.tripId,
              type: _isEvent ? ItemType.event : ItemType.task,
              title: _title.text.trim(),
              location: _isEvent ? _location.text.trim() : null,
              startsAt: _startsAt,
              assignedTo: _isEvent ? const [] : _assignedTo.toList(),
            );
        ref.invalidate(itemsProvider(widget.tripId));
      }
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
                  switch (widget.kind) {
                    AddKind.event => l10n.itemNewEvent,
                    AddKind.task => l10n.itemNewTask,
                    AddKind.list => l10n.itemNewList,
                  },
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  // A list is one field, so the keyboard can submit it.
                  textInputAction: _isList
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onSubmitted: _isList ? (_) => _save() : null,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    labelText: switch (widget.kind) {
                      AddKind.event => l10n.itemEventLabel,
                      AddKind.task => l10n.itemTaskLabel,
                      AddKind.list => l10n.itemListLabel,
                    },
                    hintText: _isList ? l10n.itemListHint : null,
                  ),
                ),
                if (!_isList) const SizedBox(height: 12),

                if (_isEvent) ...[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickDateTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _startsAt == null
                          ? l10n.itemPickDateTime
                          : DateFormat('EEE d MMM, HH:mm').format(_startsAt!),
                    ),
                    style: _outlinedStyle(active: _startsAt != null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _location,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.itemWhereOptional,
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                ] else if (!_isList) ...[
                  // Optional deadline: most trip chores just need doing at some
                  // point, and forcing a date would make the form heavier for
                  // no gain.
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickDateTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _startsAt == null
                          ? l10n.itemAddDeadline
                          : DateFormat('EEE d MMM, HH:mm').format(_startsAt!),
                    ),
                    style: _outlinedStyle(active: _startsAt != null),
                  ),
                  if (_startsAt != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _startsAt = null),
                        child: Text(
                          l10n.commonClear,
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.itemAssignTo,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (_assignedTo.isNotEmpty)
                        Text(
                          '${_assignedTo.length} selected',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // FilterChip rather than ChoiceChip: these are independent
                  // toggles, not one exclusive pick.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final member in members)
                        FilterChip(
                          avatar: CircleAvatar(
                            backgroundColor: avatarColorFor(member.user.id),
                            child: Text(
                              initialsFor(member.user.displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          label: Text(member.user.displayName),
                          selected: _assignedTo.contains(member.user.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _assignedTo.add(member.user.id);
                            } else {
                              _assignedTo.remove(member.user.id);
                            }
                          }),
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          side: const BorderSide(color: AppColors.border),
                        ),
                    ],
                  ),
                  if (_assignedTo.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.itemAssignHint,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ],
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
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

                const SizedBox(height: 20),
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
                      : Text(switch (widget.kind) {
                          AddKind.event => l10n.itemAddEvent,
                          AddKind.task => l10n.itemAddTask,
                          AddKind.list => l10n.itemAddList,
                        }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle({required bool active}) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: active
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : AppColors.ink,
      side: BorderSide(
        color: active
            ? Theme.of(context).colorScheme.primary
            : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
