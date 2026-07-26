
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/avatar_color.dart';
import '../../../../core/theme/colors.dart';
import '../../data/expense.dart';
import '../../providers.dart';
import 'delete_actions.dart';

Future<void> showExpenseDetailSheet(
    BuildContext context,
    String tripId,
    Expense expense,
    ) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExpenseDetailSheet(tripId: tripId, expense: expense),
  );
}

class _ExpenseDetailSheet extends ConsumerStatefulWidget {
  const _ExpenseDetailSheet({required this.tripId, required this.expense});

  final String tripId;
  final Expense expense;

  @override
  ConsumerState<_ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends ConsumerState<_ExpenseDetailSheet> {
  bool _deleting = false;

  /// Same confirmation as the swipe and the long press on the row behind this
  /// sheet, so a delete reads identically wherever it is started from.
  Future<void> _delete() async {
    setState(() => _deleting = true);
    final deleted =
    await confirmDeleteExpense(context, ref, widget.tripId, widget.expense);
    if (!mounted) return;
    // Nothing left to show once it is gone.
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final lookup = ref.watch(memberLookupProvider(widget.tripId));
    final myId = ref.watch(authProvider).value?.id;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                expense.description,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE d MMMM, HH:mm').format(expense.spentAt.toLocal()),
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  Money(expense.amountCents).formatted,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Paid by ${expense.paidBy == myId ? 'you' : lookup[expense.paidBy]?.user.displayName ?? 'someone'}',
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'SPLIT',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              for (final share in expense.shares)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: avatarColorFor(share.userId),
                        child: Text(
                          initialsFor(
                            lookup[share.userId]?.user.displayName ?? '?',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          share.userId == myId
                              ? 'You'
                              : lookup[share.userId]?.user.displayName ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Money(share.shareCents).formatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // Any member can delete: in a shared ledger, a mistake anyone can
              // see should be fixable by anyone.
              OutlinedButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: Text(_deleting ? 'Deleting…' : 'Delete expense'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.terracotta,
                  side: BorderSide(
                      color: AppColors.terracotta.withValues(alpha: 0.4)),
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}