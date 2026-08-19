import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/colors.dart';
import '../../data/expense.dart';
import '../../providers.dart';
import '../../../auth/data/user.dart';

Future<void> showSettleUpSheet(BuildContext context, String tripId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettleUpSheet(tripId: tripId),
  );
}

/// Where the backend's debt simplification becomes visible.
///
/// The API already reduces a web of crossed expenses to the fewest payments
/// that clear everything; this screen's job is to make that reduction legible.
class _SettleUpSheet extends ConsumerStatefulWidget {
  const _SettleUpSheet({required this.tripId});

  final String tripId;

  @override
  ConsumerState<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<_SettleUpSheet> {
  String? _settling;

  Future<void> _markPaid(TransferSuggestion transfer) async {
    setState(() => _settling = transfer.toUserId);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .settle(
            tripId: widget.tripId,
            toUserId: transfer.toUserId,
            amountCents: transfer.amountCents,
          );
      invalidateMoney(ref, widget.tripId);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _settling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(balanceProvider(widget.tripId)).value;
    final lookup = ref.watch(memberLookupProvider(widget.tripId));
    final currency = ref.watch(tripCurrencyProvider(widget.tripId));
    final myId = ref.watch(authProvider).value?.id;

    final transfers =
        report?.suggestedTransfers ?? const <TransferSuggestion>[];
    // The trip's count, not the loaded one: only the first page is in memory,
    // and "settle 3 expenses" on a trip with forty would be a lie.
    ref.watch(expensesProvider(widget.tripId));
    final expenseCount = ref
        .read(expensesProvider(widget.tripId).notifier)
        .total;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settleTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settleBody,
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),

              if (transfers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.settleAllSquare,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
                )
              else ...[
                for (final transfer in transfers) ...[
                  _TransferRow(
                    currency: currency,
                    from: transfer.fromUserId == myId
                        ? l10n.commonYou
                        : lookup[transfer.fromUserId]?.user.nameOrNull ??
                              l10n.commonSomeone,
                    to: transfer.toUserId == myId
                        ? l10n.commonYouLower
                        : lookup[transfer.toUserId]?.user.nameOrNull ??
                              l10n.commonSomeoneLower,
                    amount: Money(transfer.amountCents),
                    // Only the sender can record a repayment: the API takes the
                    // payer from the token, so nobody can settle on someone
                    // else's behalf.
                    onMarkPaid: transfer.fromUserId == myId
                        ? () => _markPaid(transfer)
                        : null,
                    busy: _settling == transfer.toUserId,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                // The plain-language version of what the algorithm just did.
                if (expenseCount > transfers.length)
                  Text(
                    l10n.settleSummary(transfers.length, expenseCount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.from,
    required this.to,
    required this.amount,
    required this.onMarkPaid,
    required this.busy,
    required this.currency,
  });

  final String from;
  final String to;
  final Money amount;
  final VoidCallback? onMarkPaid;
  final bool busy;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        from,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        to,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount.formattedIn(currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (onMarkPaid != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : onMarkPaid,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.settleMarkAsPaid),
            ),
          ],
        ],
      ),
    );
  }
}
