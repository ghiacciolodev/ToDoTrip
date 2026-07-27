import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

/// One member of a trip, reduced to what an avatar needs.
///
/// Comes inside the trips list so a card can draw its faces without a request
/// of its own.
@freezed
abstract class MemberPreview with _$MemberPreview {
  const factory MemberPreview({
    required String id,
    required String displayName,
  }) = _MemberPreview;

  factory MemberPreview.fromJson(Map<String, dynamic> json) =>
      _$MemberPreviewFromJson(json);
}

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required String baseCurrency,
    // Symbolic keys chosen at creation, or null when the user skipped that
    // step; the client turns them into an icon and a colour, and derives both
    // from the id when they are absent.
    String? icon,
    String? color,
    // Set once the trip has been put away: still fully readable, but nothing
    // can be added to it any more. The server enforces that, not the app.
    DateTime? archivedAt,
    required String createdBy,
    required DateTime createdAt,
    // Present only in the list response: the detail endpoint has no reason to
    // compute them, and the screens using it already hold the members.
    @Default(0) int memberCount,
    @Default(<MemberPreview>[]) List<MemberPreview> memberPreview,
    int? myBalanceCents,
    DateTime? lastActivityAt,
    // The other way round: only the detail response carries these, because only
    // the settings screen shows them.
    @Default(0) int expenseCount,
    @Default(0) int itemCount,
    @Default(0) int totalSpentCents,
    String? createdByName,
  }) = _Trip;

  const Trip._();

  bool get isArchived => archivedAt != null;

  /// Where the trip stands relative to today, which is what someone scanning
  /// the list is looking for — more than the dates themselves.
  TripStage get stage {
    final start = startDate;
    final end = endDate;
    if (start == null && end == null) return TripStage.undated;

    if (end != null && _today.isAfter(_dayOf(end))) return TripStage.ended;
    if (start != null && _today.isBefore(_dayOf(start))) {
      return TripStage.upcoming;
    }
    return TripStage.running;
  }

  /// Whole days until it starts. Only meaningful while [stage] is upcoming.
  int get daysUntilStart => _dayOf(startDate!).difference(_today).inDays;

  /// Which day of the trip today is, counting from one.
  int get dayOfTrip => _today.difference(_dayOf(startDate!)).inDays + 1;

  /// How long the trip lasts, both ends included.
  int get totalDays =>
      _dayOf(endDate!).difference(_dayOf(startDate!)).inDays + 1;

  /// Days are compared at day precision: a trip that starts this evening starts
  /// today, not "in 1 day".
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

/// Coarse on purpose: four states cover every trip, and each gets its own
/// sentence on the card.
enum TripStage { upcoming, running, ended, undated }
