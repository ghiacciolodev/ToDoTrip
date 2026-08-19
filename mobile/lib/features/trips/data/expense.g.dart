// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseShare _$ExpenseShareFromJson(Map<String, dynamic> json) =>
    _ExpenseShare(
      userId: json['user_id'] as String,
      shareCents: (json['share_cents'] as num).toInt(),
    );

Map<String, dynamic> _$ExpenseShareToJson(_ExpenseShare instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'share_cents': instance.shareCents,
    };

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  description: json['description'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  paidBy: json['paid_by'] as String,
  spentAt: DateTime.parse(json['spent_at'] as String),
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  shares: (json['shares'] as List<dynamic>)
      .map((e) => ExpenseShare.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'description': instance.description,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'paid_by': instance.paidBy,
  'spent_at': instance.spentAt.toIso8601String(),
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'shares': instance.shares,
};

_BalanceEntry _$BalanceEntryFromJson(Map<String, dynamic> json) =>
    _BalanceEntry(
      userId: json['user_id'] as String,
      balanceCents: (json['balance_cents'] as num).toInt(),
    );

Map<String, dynamic> _$BalanceEntryToJson(_BalanceEntry instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'balance_cents': instance.balanceCents,
    };

_TransferSuggestion _$TransferSuggestionFromJson(Map<String, dynamic> json) =>
    _TransferSuggestion(
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
    );

Map<String, dynamic> _$TransferSuggestionToJson(_TransferSuggestion instance) =>
    <String, dynamic>{
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'amount_cents': instance.amountCents,
    };

_BalanceReport _$BalanceReportFromJson(Map<String, dynamic> json) =>
    _BalanceReport(
      balances: (json['balances'] as List<dynamic>)
          .map((e) => BalanceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestedTransfers: (json['suggested_transfers'] as List<dynamic>)
          .map((e) => TransferSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSpentCents: (json['total_spent_cents'] as num).toInt(),
    );

Map<String, dynamic> _$BalanceReportToJson(_BalanceReport instance) =>
    <String, dynamic>{
      'balances': instance.balances,
      'suggested_transfers': instance.suggestedTransfers,
      'total_spent_cents': instance.totalSpentCents,
    };

_ExpensePage _$ExpensePageFromJson(Map<String, dynamic> json) => _ExpensePage(
  items: (json['items'] as List<dynamic>)
      .map((e) => Expense.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$ExpensePageToJson(_ExpensePage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'next_cursor': instance.nextCursor,
      'total': instance.total,
    };
