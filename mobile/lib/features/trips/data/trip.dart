import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required String baseCurrency,
    required String createdBy,
    required DateTime createdAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}