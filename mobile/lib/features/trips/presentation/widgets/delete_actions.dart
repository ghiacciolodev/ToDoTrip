import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/colors.dart';
import '../../data/checklist.dart';
import '../../data/expense.dart';
import '../../data/item.dart';
import '../../providers.dart';

/// Deleting, for everything a trip contains.
///
/// Two gestures for one action: a swipe, which is where people look first, and
/// a long press, which still works for anyone who never tries swiping. Both end
/// at the same confirmation, so the wording of a destructive step is written
/// once.
///
/// Any member can delete anything: a shared plan nobody is allowed to tidy
/// stops being useful, and the API takes the same view.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.id,
    required this.onDelete,
    required this.child,
  });

  /// Identifies the row being swiped, so the gesture follows the right one when
  /// the list reorders underneath it.
  final String id;

  /// Asks for confirmation and deletes. Called by the swipe and, by the caller,
  /// on long press.
  final Future<void> Function() onDelete;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      // One direction only, so a horizontal scroll or a stray thumb cannot
      // trigger it, and always right to left, as everywhere else on both
      // platforms.
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      // Never dismissed by the gesture itself: the row is removed when the list
      // refreshes after a successful delete, which also means a cancelled
      // confirmation or a failed request simply leaves it in place.
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      child: child,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.terracotta),
    );
  }
}

/// Shared confirmation dialog. Returns true only on an explicit confirm.
Future<bool> _confirm(
    BuildContext context, {
      required String title,
      String? message,
      String action = 'Delete',
    }) async {
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            action,
            style: const TextStyle(color: AppColors.terracotta),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// An event or a to-do.
Future<void> confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    Item item,
    ) async {
  if (!await _confirm(context, title: 'Delete "${item.title}"?')) return;

  try {
    await ref.read(itemRepositoryProvider).delete(tripId, item.id);
    ref.invalidate(itemsProvider(tripId));
  } on ApiException catch (e) {
    if (context.mounted) _toast(context, e.message);
  }
}

/// A list, entries included.
Future<void> confirmDeleteChecklist(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    Checklist checklist,
    ) async {
  final count = checklist.entries.length;
  final confirmed = await _confirm(
    context,
    title: 'Delete "${checklist.name}"?',
    // Names what is lost and for whom: this removes other people's lines too.
    message: count == 0
        ? 'The list is removed for everyone.'
        : 'Its $count ${count == 1 ? 'item' : 'items'} go with it, for everyone.',
  );
  if (!confirmed) return;

  try {
    await ref.read(checklistRepositoryProvider).delete(tripId, checklist.id);
    ref.invalidate(checklistsProvider(tripId));
  } on ApiException catch (e) {
    if (context.mounted) _toast(context, e.message);
  }
}

/// One line of a list.
Future<void> confirmDeleteEntry(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    ChecklistEntry entry,
    ) async {
  final confirmed = await _confirm(
    context,
    title: 'Remove "${entry.text}"?',
    action: 'Remove',
  );
  if (!confirmed) return;

  try {
    await ref.read(checklistRepositoryProvider).deleteEntry(
      tripId: tripId,
      checklistId: entry.checklistId,
      entryId: entry.id,
    );
    ref.invalidate(checklistsProvider(tripId));
  } on ApiException catch (e) {
    if (context.mounted) _toast(context, e.message);
  }
}

/// An expense. Resolves to true when it was actually deleted, so a detail sheet
/// showing it can close itself.
Future<bool> confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    String tripId,
    Expense expense,
    ) async {
  final confirmed = await _confirm(
    context,
    title: 'Delete "${expense.description}"?',
    message: "Everyone's balance will be recalculated.",
  );
  if (!confirmed) return false;

  try {
    await ref.read(expenseRepositoryProvider).delete(tripId, expense.id);
    invalidateMoney(ref, tripId);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) _toast(context, e.message);
    return false;
  }
}
