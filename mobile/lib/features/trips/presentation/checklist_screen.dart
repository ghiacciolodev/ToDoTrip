import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/refresh_on_resume.dart';
import '../../../core/theme/colors.dart';
import '../data/checklist.dart';
import '../providers.dart';
import 'widgets/delete_actions.dart';
import 'widgets/tab_states.dart';

/// One list, full screen.
///
/// Built around the field at the bottom: the list gets filled in a shop, in a
/// hurry, often while someone dictates, so writing a line and starting the next
/// one must cost a single tap.
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({
    super.key,
    required this.tripId,
    required this.checklistId,
  });

  final String tripId;
  final String checklistId;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(checklistsProvider(widget.tripId));

  Future<void> _add() async {
    final text = _text.text.trim();
    if (text.isEmpty || _busy) return;

    // Cleared straight away: the next line is usually already being dictated,
    // and re-typing it because the field was still busy is worse than a line
    // that has to be removed if the request fails.
    _text.clear();
    setState(() => _busy = true);

    try {
      await ref
          .read(checklistRepositoryProvider)
          .addEntry(
            tripId: widget.tripId,
            checklistId: widget.checklistId,
            text: text,
          );
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        _text.text = text;
        _toast(friendlyError(context, e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        // The keyboard stays up for the next item.
        _focus.requestFocus();
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(checklistsProvider(widget.tripId));
    final checklist = ref.watch(
      checklistProvider((
        tripId: widget.tripId,
        checklistId: widget.checklistId,
      )),
    );

    // Null with data loaded means someone else deleted the list while it was
    // open; null while loading is just the first fetch.
    if (checklist == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.listTitle)),
        body: lists.hasValue
            ? EmptyState(
                icon: Icons.playlist_remove,
                title: l10n.listGoneTitle,
                subtitle: l10n.listGoneBody,
              )
            : const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(checklist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              checklist.entries.isEmpty
                  ? l10n.listEmpty
                  : l10n.listProgress(
                      checklist.checkedCount,
                      checklist.entries.length,
                    ),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: RefreshOnResume(
        onResume: _refresh,
        child: Column(
          children: [
            Expanded(child: _Entries(widget.tripId, checklist)),
            _Composer(
              controller: _text,
              focusNode: _focus,
              busy: _busy,
              onSubmit: _add,
            ),
          ],
        ),
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries(this.tripId, this.checklist);

  final String tripId;
  final Checklist checklist;

  @override
  Widget build(BuildContext context) {
    if (checklist.entries.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.check_box_outlined,
        title: l10n.listEntriesEmptyTitle,
        subtitle: l10n.listEntriesEmptyBody,
      );
    }

    // Taken lines sink to the bottom, so what is still missing is always at the
    // top of the screen where a thumb can reach it.
    final open = checklist.entries.where((e) => !e.isChecked).toList();
    final taken = checklist.entries.where((e) => e.isChecked).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final entry in [...open, ...taken])
          _EntryRow(key: ValueKey(entry.id), tripId: tripId, entry: entry),
      ],
    );
  }
}

class _EntryRow extends ConsumerStatefulWidget {
  const _EntryRow({super.key, required this.tripId, required this.entry});

  final String tripId;
  final ChecklistEntry entry;

  @override
  ConsumerState<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends ConsumerState<_EntryRow> {
  late bool _checked = widget.entry.isChecked;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _EntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Someone else ticked it: follow the server, unless our own request is
    // still in flight and would be overwritten by data that predates it.
    if (!_busy && widget.entry.isChecked != _checked) {
      _checked = widget.entry.isChecked;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    // Flipped locally first: a checkbox that waits for a round trip feels
    // broken. Reverted below if the call fails.
    setState(() {
      _checked = !_checked;
      _busy = true;
    });

    try {
      await ref
          .read(checklistRepositoryProvider)
          .setChecked(
            tripId: widget.tripId,
            checklistId: widget.entry.checklistId,
            entryId: widget.entry.id,
            checked: _checked,
          );
      ref.invalidate(checklistsProvider(widget.tripId));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _checked = !_checked);
        _toast(context, friendlyError(context, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() =>
      confirmDeleteEntry(context, ref, widget.tripId, widget.entry);

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SwipeToDelete(
      id: widget.entry.id,
      onDelete: _delete,
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: _toggle,
          onLongPress: _delete,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: (_) => _toggle(),
                  activeColor: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.entry.text,
                      style: TextStyle(
                        fontSize: 15,
                        decoration: _checked
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.inkMuted,
                        color: _checked ? AppColors.inkMuted : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The always-ready field at the bottom of the screen.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  // Submitting from the keyboard adds the line too, so a
                  // dictated list never needs the screen to be touched.
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).listAddItem,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: busy ? null : onSubmit,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.square(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
