import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'expense.dart';
import 'settlement.dart';

class ExpenseRepository {
  ExpenseRepository({required this.dio});

  final Dio dio;

  Future<List<Expense>> list(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/expenses');
      return (response.data as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<BalanceReport> balance(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/balance');
      return BalanceReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// [shares] null means an even split across [participants]; the server does
  /// the rounding so that shares always add back up to the total.
  Future<Expense> create({
    required String tripId,
    required String description,
    required int amountCents,
    required String paidBy,
    required List<String> participants,
    Map<String, int>? shares,
    DateTime? spentAt,
  }) async {
    try {
      final response = await dio.post(
        '/trips/$tripId/expenses',
        data: {
          'description': description,
          'amount_cents': amountCents,
          'paid_by': paidBy,
          if (spentAt != null) 'spent_at': spentAt.toUtc().toIso8601String(),
          if (shares == null)
            'participants': participants
          else
            'shares': [
              for (final entry in shares.entries)
                {'user_id': entry.key, 'share_cents': entry.value},
            ],
        },
      );
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String tripId, String expenseId) async {
    try {
      await dio.delete('/trips/$tripId/expenses/$expenseId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The sender is always the caller: the API takes it from the token, so
  /// nobody can mark someone else's debt as repaid.
  Future<void> settle({
    required String tripId,
    required String toUserId,
    required int amountCents,
    String? note,
  }) async {
    try {
      await dio.post(
        '/trips/$tripId/settlements',
        data: {
          'to_user_id': toUserId,
          'amount_cents': amountCents,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Settlement>> listSettlements(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/settlements');
      return (response.data as List)
          .map((json) => Settlement.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Only the member who recorded the repayment may undo it: the API answers 403
  /// to everyone else.
  Future<void> deleteSettlement(String tripId, String settlementId) async {
    try {
      await dio.delete('/trips/$tripId/settlements/$settlementId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}