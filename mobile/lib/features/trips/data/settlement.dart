import 'package:freezed_annotation/freezed_annotation.dart';

part 'settlement.freezed.dart';
part 'settlement.g.dart';

/// A repayment made between two members, outside the app.
///
/// Not an expense: it moves money between people without adding to what the
/// trip cost. It also outlives the expense it was made against — deleting that
/// expense leaves the repayment standing — which is why these have to be visible
/// rather than only felt through the balances.
@freezed
abstract class Settlement with _$Settlement {
  const factory Settlement({
    required String id,
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required int amountCents,
    String? note,
    required DateTime settledAt,
  }) = _Settlement;

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);
}
