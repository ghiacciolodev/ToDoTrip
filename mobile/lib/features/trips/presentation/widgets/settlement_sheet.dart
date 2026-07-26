import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/colors.dart';
import '../../data/settlement.dart';
import '../../providers.dart';

/// One recorded repayment, with the way to take it back.
///
/// Recording a repayment used to be one-way: a "Mark as paid" tapped by mistake
/// stayed in the balances for good, and after the matching expense was deleted it
/// became a figure with nothing on screen behind it.
Future<void> showSettlementSheet(
    BuildContext context,
    String tripId,
    Settlement settlement,
    ) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => _SettlementSheet(tripId: tripId, settlement: settlement),
  );
}

class _SettlementSheet extends ConsumerStatefulWidget {
  const _SettlementSheet({required this.tripId, required this.settlement});

  final String tripId;
  final Settlement settlement;

  @override
  ConsumerState<_SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends ConsumerState<_SettlementSheet> {
  bool _busy = false;

  Future<void> _undo() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Undo this repayment?'),
        content: const Text(
          "Everyone's balance goes back to what it was before it was recorded.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Undo', style: TextStyle(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .deleteSettlement(widget.tripId, widget.settlement.id);
      invalidateMoney(ref, widget.tripId);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final lookup = ref.watch(memberLookupProvider(widget.tripId));
    final myId = ref.watch(authProvider).value?.id;

    String name(String id) => id == myId
        ? 'You'
        : lookup[id]?.user.displayName ?? 'Someone';

    return SafeArea(
      child: Padding
        (
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Repayment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE d MMMM, HH:mm').format(settlement.settledAt.toLocal()),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                Money(settlement.amountCents).formatted,
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
                '${name(settlement.fromUserId)} → ${name(settlement.toUserId)}',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ),
            if (settlement.note != null && settlement.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  settlement.note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Only the sender: undoing is a statement about their own money, and
            // the API rejects anyone else with 403.
            if (settlement.fromUserId == myId)
              OutlinedButton.icon(
                onPressed: _busy ? null : _undo,
                icon: const Icon(Icons.undo, size: 20),
                label: Text(_busy ? 'Undoing…' : 'Undo this repayment'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.terracotta,
                  side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              )
            else
              Text(
                'Only ${name(settlement.fromUserId).toLowerCase()} can undo this.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
