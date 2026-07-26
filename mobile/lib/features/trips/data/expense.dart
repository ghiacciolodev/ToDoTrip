import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
abstract class ExpenseShare with _$ExpenseShare {
  const factory ExpenseShare({
    required String userId,
    required int shareCents,
  }) = _ExpenseShare;

  factory ExpenseShare.fromJson(Map<String, dynamic> json) =>
      _$ExpenseShareFromJson(json);
}

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String tripId,
    required String description,
    required int amountCents,
    required String currency,
    required String paidBy,
    required DateTime spentAt,
    required String createdBy,
    required DateTime createdAt,
    required List<ExpenseShare> shares,
  }) = _Expense;

  const Expense._();

  /// What this expense costs [userId], or null when they took no part in it.
  ///
  /// Distinguishing "your share is zero" from "you weren't involved" matters:
  /// the list shows the two differently.
  int? shareFor(String userId) {
    for (final share in shares) {
      if (share.userId == userId) return share.shareCents;
    }
    return null;
  }

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

@freezed
abstract class BalanceEntry with _$BalanceEntry {
  const factory BalanceEntry({
    required String userId,
    required int balanceCents,
  }) = _BalanceEntry;

  factory BalanceEntry.fromJson(Map<String, dynamic> json) =>
      _$BalanceEntryFromJson(json);
}

@freezed
abstract class TransferSuggestion with _$TransferSuggestion {
  const factory TransferSuggestion({
    required String fromUserId,
    required String toUserId,
    required int amountCents,
  }) = _TransferSuggestion;

  factory TransferSuggestion.fromJson(Map<String, dynamic> json) =>
      _$TransferSuggestionFromJson(json);
}

@freezed
abstract class BalanceReport with _$BalanceReport {
  const factory BalanceReport({
    required List<BalanceEntry> balances,
    required List<TransferSuggestion> suggestedTransfers,
    required int totalSpentCents,
  }) = _BalanceReport;

  const BalanceReport._();

  int balanceFor(String userId) {
    for (final entry in balances) {
      if (entry.userId == userId) return entry.balanceCents;
    }
    return 0;
  }

  factory BalanceReport.fromJson(Map<String, dynamic> json) =>
      _$BalanceReportFromJson(json);
}
