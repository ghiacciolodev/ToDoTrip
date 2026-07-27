import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/colors.dart';
import '../../data/expense.dart';
import '../../data/settlement.dart';
import '../../providers.dart';
import '../widgets/delete_actions.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/settle_up_sheet.dart';
import '../widgets/settlement_sheet.dart';
import '../../../auth/data/user.dart';

class ExpensesTab extends ConsumerWidget {
  const ExpensesTab({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authProvider).value?.id;
    if (myId == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => invalidateMoney(ref, tripId),
      child: _buildBody(context, ref, myId),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, String myId) {
    final expenses = ref.watch(expensesProvider(tripId));
    final settlements = ref.watch(settlementsProvider(tripId));
    final balance = ref.watch(balanceProvider(tripId));
    final list = expenses.value;

    // Only the very first load blanks the screen. Once there is data, a refresh
    // updates it in place: replacing a populated list with a spinner every time
    // the tab regains focus reads as the app losing its state.
    if (list == null) {
      if (expenses.hasError) {
        return _ErrorState(
          message: '${expenses.error}',
          onRetry: () => invalidateMoney(ref, tripId),
        );
      }
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // Expenses and repayments in one column: both move the balances, and a
    // repayment shown nowhere is a figure that changes for no visible reason —
    // most sharply after the expense it was made against has been deleted.
    final entries = <_Entry>[
      for (final expense in list) _ExpenseEntry(expense),
      for (final settlement in settlements.value ?? const <Settlement>[])
        _SettlementEntry(settlement),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _BalanceCard(
              tripId: tripId,
              report: balance.value,
              myId: myId,
            ),
          ),
        ),
        if (entries.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else
          ..._buildGroupedList(context, ref, entries, myId),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  /// Groups by day with a sticky header, which is how people recall spending:
  /// "what did we pay for on Tuesday", not "expense number 14".
  List<Widget> _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<_Entry> entries,
    String myId,
  ) {
    final byDay = <DateTime, List<_Entry>>{};
    for (final entry in entries) {
      final local = entry.at.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(entry);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final day in days)
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _DayHeaderDelegate(label: _dayLabel(context, day)),
            ),
            SliverList.builder(
              itemCount: byDay[day]!.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: switch (byDay[day]![index]) {
                  _ExpenseEntry(:final expense) => _ExpenseRow(
                    tripId: tripId,
                    expense: expense,
                    myId: myId,
                  ),
                  _SettlementEntry(:final settlement) => _SettlementRow(
                    tripId: tripId,
                    settlement: settlement,
                    myId: myId,
                  ),
                },
              ),
            ),
          ],
        ),
    ];
  }

  static String _dayLabel(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return l10n.moneyToday;
    if (difference == 1) return l10n.moneyYesterday;
    return DateFormat('EEEE d MMMM').format(day);
  }
}

/// One line of the money tab: something the trip spent, or money moved between
/// two members to square up.
sealed class _Entry {
  const _Entry();

  /// When it happened, which is what the single list is ordered by.
  DateTime get at;
}

class _ExpenseEntry extends _Entry {
  const _ExpenseEntry(this.expense);

  final Expense expense;

  @override
  DateTime get at => expense.spentAt;
}

class _SettlementEntry extends _Entry {
  const _SettlementEntry(this.settlement);

  final Settlement settlement;

  @override
  DateTime get at => settlement.settledAt;
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({
    required this.tripId,
    required this.report,
    required this.myId,
  });

  final String tripId;
  final BalanceReport? report;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (report == null) {
      return const Card(
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    }

    final mine = Money(report!.balanceFor(myId));
    final total = Money(report!.totalSpentCents);
    final hasDebts = report!.suggestedTransfers.isNotEmpty;

    // Wording plus sign plus colour: red and green alone carry no meaning for
    // roughly 8% of men.
    final l10n = AppLocalizations.of(context);
    final (label, colour) = switch (mine.cents) {
      0 => (l10n.moneyAllSettled, AppColors.inkMuted),
      > 0 => (
        l10n.moneyYouAreOwed,
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      _ => (l10n.moneyYouOwe, AppColors.terracotta),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            Text(
              mine.isZero ? '—' : mine.abs.formatted,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: colour,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.moneyTripTotal(total.formatted),
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            if (hasDebts) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => showSettleUpSheet(context, tripId),
                child: Text(l10n.moneySettleUp),
              ),
            ],
            if (report!.balances.length > 1) ...[
              const SizedBox(height: 4),
              _EveryoneBalance(tripId: tripId, report: report!, myId: myId),
            ],
          ],
        ),
      ),
    );
  }
}

/// Secondary information, collapsed by default: the question people open this
/// screen with is "how do I stand", not "how does everyone stand".
class _EveryoneBalance extends ConsumerWidget {
  const _EveryoneBalance({
    required this.tripId,
    required this.report,
    required this.myId,
  });

  final String tripId;
  final BalanceReport report;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(memberLookupProvider(tripId));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          AppLocalizations.of(context).moneyEveryonesBalance,
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final entry in report.balances)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.userId == myId
                          ? AppLocalizations.of(context).commonYou
                          : lookup[entry.userId]?.user.nameOrNull ??
                                AppLocalizations.of(context).commonUnknown,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    Money(entry.balanceCents).signed,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: switch (entry.balanceCents) {
                        0 => AppColors.inkMuted,
                        > 0 => Theme.of(context).colorScheme.onPrimaryContainer,
                        _ => AppColors.terracotta,
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  const _ExpenseRow({
    required this.tripId,
    required this.expense,
    required this.myId,
  });

  final String tripId;
  final Expense expense;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(memberLookupProvider(tripId));
    final l10n = AppLocalizations.of(context);
    final payer = expense.paidBy == myId
        ? l10n.commonYou
        : lookup[expense.paidBy]?.user.nameOrNull ?? l10n.commonSomeone;
    final myShare = expense.shareFor(myId);

    return SwipeToDelete(
      id: expense.id,
      onDelete: () => confirmDeleteExpense(context, ref, tripId, expense),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showExpenseDetailSheet(context, tripId, expense),
          onLongPress: () =>
              confirmDeleteExpense(context, ref, tripId, expense),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(expense.description),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.moneyPaidBy(payer),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money(expense.amountCents).formatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // "What it cost" and "what it costs me" are different
                    // questions, and the second is the one people care about.
                    Text(
                      myShare == null
                          ? l10n.moneyNotInvolved
                          : l10n.moneyYourShare(Money(myShare).formatted),
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crude keyword match, but it makes a long list scannable at a glance.
  static IconData _iconFor(String description) {
    final text = description.toLowerCase();
    bool has(List<String> words) => words.any(text.contains);

    if (has(['dinner', 'lunch', 'restaurant', 'food', 'breakfast', 'pizza'])) {
      return Icons.restaurant;
    }
    if (has(['grocer', 'supermarket', 'market'])) return Icons.shopping_basket;
    if (has(['taxi', 'uber', 'fuel', 'petrol', 'gas', 'car'])) {
      return Icons.local_taxi;
    }
    if (has(['hotel', 'airbnb', 'hostel', 'room'])) return Icons.hotel;
    if (has(['flight', 'plane', 'airport'])) return Icons.flight;
    if (has(['train', 'bus', 'metro', 'ticket'])) {
      return Icons.directions_transit;
    }
    if (has(['bar', 'drink', 'beer', 'coffee', 'wine'])) return Icons.local_bar;
    if (has(['museum', 'tour', 'entry'])) return Icons.local_activity;
    return Icons.receipt_long;
  }
}

/// A repayment, deliberately quieter than an expense.
///
/// No tinted icon and no bold amount: this is not something the trip spent, and
/// reading it as a cost is exactly the confusion that makes the balances look
/// wrong. Tapping opens the detail, where its sender — and only its sender — can
/// undo it.
class _SettlementRow extends ConsumerWidget {
  const _SettlementRow({
    required this.tripId,
    required this.settlement,
    required this.myId,
  });

  final String tripId;
  final Settlement settlement;
  final String myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(memberLookupProvider(tripId));

    final l10n = AppLocalizations.of(context);

    String name(String id, {required bool subject}) {
      if (id == myId) return subject ? l10n.commonYou : l10n.commonYouLower;
      return lookup[id]?.user.nameOrNull ?? l10n.commonSomeone;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSettlementSheet(context, tripId, settlement),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.inkMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.moneyPaidSomeone(
                        name(settlement.fromUserId, subject: true),
                        name(settlement.toUserId, subject: false),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.moneyRepayment,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Money(settlement.amountCents).formatted,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DayHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add the first one and we\u2019ll keep\ntrack of who owes what.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, height: 1.4),
          ),
        ],
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
    // A list, not a Column: the pull-to-refresh above needs something
    // scrollable even when the screen has nothing on it.
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
              OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).commonTryAgain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
