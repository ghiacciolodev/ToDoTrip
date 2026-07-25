import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/item.dart';
import '../../data/trip_member.dart';
import '../../providers.dart';

/// Calendar and to-dos.
///
/// One list, filtered two ways: events and tasks are the same table on the
/// server, discriminated by type, and the segmented control mirrors that rather
/// than inventing a split the data does not have.
///
/// The selected view is owned by the shell so the floating action button can
/// create whichever kind is on screen.
class PlanTab extends ConsumerWidget {
  const PlanTab({
    super.key,
    required this.tripId,
    required this.view,
    required this.onViewChanged,
  });

  final String tripId;
  final ItemType view;
  final ValueChanged<ItemType> onViewChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(tripId));
    final list = items.value;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(itemsProvider(tripId)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ItemType>(
                segments: const [
                  ButtonSegment(
                    value: ItemType.event,
                    label: Text('Calendar'),
                    icon: Icon(Icons.event_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ItemType.task,
                    label: Text('To-do'),
                    icon: Icon(Icons.checklist_outlined, size: 18),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (s) => onViewChanged(s.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          Expanded(
            child: switch ((list, items.hasError)) {
              (null, true) => _ErrorState(
                message: '${items.error}',
                onRetry: () => ref.invalidate(itemsProvider(tripId)),
              ),
              (null, _) =>
              const Center(child: CircularProgressIndicator.adaptive()),
              (final all?, _) => view == ItemType.event
                  ? _CalendarView(tripId: tripId, items: all)
                  : _TaskView(tripId: tripId, items: all),
            },
          ),
        ],
      ),
    );
  }
}

/// A flat agenda: each card carries its own date, so no day headers are needed
/// and the list stays one uninterrupted column.
class _CalendarView extends ConsumerWidget {
  const _CalendarView({required this.tripId, required this.items});

  final String tripId;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.every((i) => i.type != ItemType.event)) {
      return const _EmptyState(
        icon: Icons.event_outlined,
        title: 'Nothing planned yet',
        subtitle: 'Add flights, check-ins and\nanything with a time on it.',
      );
    }

    // Newest first. Swap the operands to put upcoming events at the top:
    //   a.startsAt!.compareTo(b.startsAt!)
    final events = items.where((i) => i.type == ItemType.event).toList()
      ..sort((a, b) => b.startsAt!.compareTo(a.startsAt!));

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _EventCard(tripId: tripId, item: events[index]),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.tripId, required this.item});

  final String tripId;
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = item.startsAt!.toLocal();
    final past = item.startsAt!.isBefore(DateTime.now());

    // Muted colours chosen explicitly instead of wrapping the card in Opacity:
    // opacity fades text and background together and drops contrast below the
    // readable threshold. primaryDark on primaryTint sits at 6.4:1.
    final blockColour = past ? AppColors.background : AppColors.primaryTint;
    final blockText = past ? AppColors.inkMuted : AppColors.primaryDark;
    final titleColour = past ? AppColors.inkMuted : AppColors.ink;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () => confirmDeleteItem(context, ref, tripId, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and time together, so each card stands on its own and the
              // list needs no sticky headers to be readable.
              Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: blockColour,
                  borderRadius: BorderRadius.circular(12),
                  border: past ? Border.all(color: AppColors.border) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(local).toUpperCase(),
                      style: TextStyle(
                        color: blockText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${local.day}',
                      style: TextStyle(
                        color: blockText,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(local),
                      style: TextStyle(
                        color: blockText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(local),
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: titleColour,
                      ),
                    ),
                    if (item.location != null && item.location!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: AppColors.inkMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskView extends ConsumerWidget {
  const _TaskView({required this.tripId, required this.items});

  final String tripId;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = items.where((i) => i.isTask).toList();

    if (tasks.isEmpty) {
      return const _EmptyState(
        icon: Icons.checklist_outlined,
        title: 'Nothing to do yet',
        subtitle: 'Book the hostel, buy sunscreen,\nsplit the driving.',
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
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskRow(tripId: tripId, item: task),
          ),
        // Completed work collapses out of the way rather than disappearing:
        // seeing it ticked off is half the point of a shared list.
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                '${done.length} completed',
                style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                for (final task in done)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskRow(tripId: tripId, item: task),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  const _TaskRow({required this.tripId, required this.item});

  final String tripId;
  final Item item;

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
  late bool _done = widget.item.isDone;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    // Flipped locally first: a checkbox that waits for a round trip feels
    // broken. Reverted below if the call fails.
    setState(() {
      _done = !_done;
      _busy = true;
    });

    try {
      await ref.read(itemRepositoryProvider).setCompleted(
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
          ..showSnackBar(SnackBar(content: Text(e.message)));
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _toggle,
        onLongPress: () => confirmDeleteItem(context, ref, widget.tripId, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: _done,
                onChanged: (_) => _toggle(),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          decoration: _done ? TextDecoration.lineThrough : null,
                          color: _done ? AppColors.inkMuted : AppColors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.startsAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMM, HH:mm')
                              .format(item.startsAt!.toLocal()),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (assignees.isNotEmpty) ...[
                const SizedBox(width: 8),
                _AvatarStack(members: assignees),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlapping avatars, capped at three plus a count.
///
/// Overlap rather than a row: a shared chore should read as "these people" at a
/// glance without stretching the row wider than the title.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<TripMember> members;

  static const _max = 3;
  static const _size = 28.0;
  static const _overlap = 9.0;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(_max).toList();
    final extra = members.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);

    return SizedBox(
      height: _size,
      width: _size + (count - 1) * (_size - _overlap),
      child: Stack(
        children: [
          for (final (index, member) in shown.indexed)
            Positioned(
              left: index * (_size - _overlap),
              child: _Bubble(
                label: initialsFor(member.user.displayName),
                colour: avatarColorFor(member.user.id),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (_size - _overlap),
              child: _Bubble(label: '+$extra', colour: AppColors.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _AvatarStack._size,
      width: _AvatarStack._size,
      decoration: BoxDecoration(
        color: colour,
        shape: BoxShape.circle,
        // A ring in the card colour separates overlapping bubbles.
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Long-press to delete, for both events and tasks.
///
/// Any member can delete: a shared list nobody is allowed to tidy stops being
/// useful, and the API takes the same view.
Future<void> confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    Item item,
    ) async {
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text('Delete "${item.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.terracotta),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(itemRepositoryProvider).delete(tripId, item.id);
    ref.invalidate(itemsProvider(tripId));
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Scrollable even when empty, so pull-to-refresh still works here.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            // Slightly above centre: dead centre of the available space reads
            // as low, because the eye places the optical centre higher.
            alignment: const Alignment(0, -0.25),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppColors.inkMuted),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.inkMuted),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ],
    );
  }
}