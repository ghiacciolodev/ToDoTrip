import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../data/checklist.dart';
import '../../data/item.dart';
import '../../providers.dart';
import '../checklist_screen.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/delete_actions.dart';
import '../widgets/tab_states.dart';

/// The two kinds of thing left to do.
enum TasksView { todo, lists }

/// To-do and Lists.
///
/// To-do holds the trip's work: one line, assignable, with a deadline. Lists
/// hold the throwaway kind — twenty items to tick off in a supermarket — which
/// would drown the to-dos if the two shared one column.
///
/// The selected view is owned by the shell so the floating action button can
/// create whichever kind is on screen.
class TasksTab extends ConsumerWidget {
  const TasksTab({
    super.key,
    required this.tripId,
    required this.view,
    required this.onViewChanged,
  });

  final String tripId;
  final TasksView view;
  final ValueChanged<TasksView> onViewChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(itemsProvider(tripId));
        ref.invalidate(checklistsProvider(tripId));
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<TasksView>(
                segments: [
                  ButtonSegment(
                    value: TasksView.todo,
                    label: Text(AppLocalizations.of(context).tasksViewTodo),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: TasksView.lists,
                    label: Text(AppLocalizations.of(context).tasksViewLists),
                    icon: const Icon(Icons.playlist_add_check, size: 18),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (s) => onViewChanged(s.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          Expanded(
            child: switch (view) {
              TasksView.todo => _TodoView(tripId: tripId),
              TasksView.lists => _ListsView(tripId: tripId),
            },
          ),
        ],
      ),
    );
  }
}

class _TodoView extends ConsumerWidget {
  const _TodoView({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(tripId));
    final list = items.value;

    if (list == null) {
      return items.hasError
          ? ErrorState(
              message: '${items.error}',
              onRetry: () => ref.invalidate(itemsProvider(tripId)),
            )
          : const Center(child: CircularProgressIndicator.adaptive());
    }

    final tasks = list.where((i) => i.isTask).toList();
    if (tasks.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: l10n.tasksEmptyTitle,
        subtitle: l10n.tasksEmptyBody,
      );
    }

    // Dated tasks first and soonest first; undated ones after. A deadline is
    // the only ordering signal a to-do list has.
    final open = tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) {
        if (a.startsAt == null && b.startsAt == null) return 0;
        if (a.startsAt == null) return 1;
        if (b.startsAt == null) return -1;
        return a.startsAt!.compareTo(b.startsAt!);
      });
    final done = tasks.where((t) => t.isDone).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final task in open)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(tripId: tripId, item: task),
          ),
        // Completed work collapses out of the way rather than disappearing:
        // seeing it ticked off is half the point of a shared list.
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                AppLocalizations.of(context).tasksCompletedCount(done.length),
                style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                for (final task in done)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskCard(tripId: tripId, item: task),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ListsView extends ConsumerWidget {
  const _ListsView({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(checklistsProvider(tripId));
    final value = lists.value;

    if (value == null) {
      return lists.hasError
          ? ErrorState(
              message: '${lists.error}',
              onRetry: () => ref.invalidate(checklistsProvider(tripId)),
            )
          : const Center(child: CircularProgressIndicator.adaptive());
    }

    if (value.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.playlist_add_check,
        title: l10n.listsEmptyTitle,
        subtitle: l10n.listsEmptyBody,
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: value.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) =>
          _ChecklistCard(tripId: tripId, checklist: value[index]),
    );
  }
}

class _ChecklistCard extends ConsumerWidget {
  const _ChecklistCard({required this.tripId, required this.checklist});

  final String tripId;
  final Checklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final total = checklist.entries.length;
    final left = total - checklist.checkedCount;
    final complete = total > 0 && left == 0;

    return SwipeToDelete(
      id: checklist.id,
      onDelete: () => confirmDeleteChecklist(context, ref, tripId, checklist),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ChecklistScreen(tripId: tripId, checklistId: checklist.id),
            ),
          ),
          onLongPress: () =>
              confirmDeleteChecklist(context, ref, tripId, checklist),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: complete
                            ? AppColors.primary
                            : AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        complete ? Icons.check : Icons.playlist_add_check,
                        color: complete ? Colors.white : AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checklist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // The number that matters while shopping is what is
                          // still missing, not what is already in the basket.
                          Text(
                            switch ((total, left)) {
                              (0, _) => l10n.listEmpty,
                              (_, 0) => l10n.listAllDone,
                              (_, final n) => l10n.listLeftOf(n, total),
                            },
                            style: TextStyle(
                              color: complete
                                  ? AppColors.primaryDark
                                  : AppColors.inkMuted,
                              fontSize: 13,
                              fontWeight: complete
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkMuted,
                      size: 20,
                    ),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: checklist.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  const _TaskCard({required this.tripId, required this.item});

  final String tripId;
  final Item item;

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  late bool _done = widget.item.isDone;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Someone else ticked it off: follow the server, unless our own request is
    // still in flight and would be overwritten by data that predates it.
    if (!_busy && widget.item.isDone != _done) {
      _done = widget.item.isDone;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    // Flipped locally first: a checkbox that waits for a round trip feels
    // broken. Reverted below if the call fails.
    setState(() {
      _done = !_done;
      _busy = true;
    });

    try {
      await ref
          .read(itemRepositoryProvider)
          .setCompleted(
            tripId: widget.tripId,
            itemId: widget.item.id,
            done: _done,
          );
      ref.invalidate(itemsProvider(widget.tripId));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _done = !_done);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final lookup = ref.watch(memberLookupProvider(widget.tripId));
    final assignees = [
      for (final id in item.assignees)
        if (lookup[id] case final member?) member,
    ];

    return SwipeToDelete(
      id: item.id,
      onDelete: () => confirmDeleteItem(context, ref, widget.tripId, item),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggle,
          onLongPress: () =>
              confirmDeleteItem(context, ref, widget.tripId, item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                _Tick(done: _done, onTap: _toggle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: _done ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.inkMuted,
                          color: _done ? AppColors.inkMuted : AppColors.ink,
                        ),
                      ),
                      if (item.startsAt != null && !_done) ...[
                        const SizedBox(height: 5),
                        _Deadline(at: item.startsAt!.toLocal()),
                      ],
                    ],
                  ),
                ),
                if (assignees.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  AvatarStack(
                    people: [
                      for (final member in assignees)
                        AvatarPerson(
                          id: member.user.id,
                          name: member.user.displayName,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round tick instead of a Material checkbox.
///
/// Softer next to the rounded cards, and it animates between the two states so
/// the optimistic flip is visible as a change rather than a repaint.
class _Tick extends StatelessWidget {
  const _Tick({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      // Keeps the finger target at the 48dp minimum even though the ring drawn
      // is half that.
      radius: 24,
      containedInkWell: false,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? AppColors.primary : AppColors.inkMuted,
              width: 1.6,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// When a task is due, in the words people actually use.
///
/// Turns terracotta once it is late, with the word "Overdue" next to it: colour
/// alone carries no meaning for roughly 8% of men.
class _Deadline extends StatelessWidget {
  const _Deadline({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final days = day.difference(today).inDays;
    final late = at.isBefore(now);

    final l10n = AppLocalizations.of(context);
    final label = switch (days) {
      _ when late => l10n.tasksOverdue(DateFormat('d MMM').format(at)),
      0 => l10n.tasksDueToday(DateFormat('HH:mm').format(at)),
      1 => l10n.tasksDueTomorrow(DateFormat('HH:mm').format(at)),
      _ => DateFormat('EEE d MMM, HH:mm').format(at),
    };
    final colour = late ? AppColors.terracotta : AppColors.inkMuted;

    return Row(
      children: [
        Icon(
          late ? Icons.error_outline : Icons.schedule,
          size: 13,
          color: colour,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colour,
            fontSize: 12,
            fontWeight: late ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
