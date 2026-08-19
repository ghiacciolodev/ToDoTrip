import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// What kind of thing happened. The wire values are the server's enum.
///
/// [unknown] is the fallback for a kind a later API added: an older build has
/// to keep showing the rest of the feed rather than failing to parse it.
enum NotificationKind {
  @JsonValue('expense_added')
  expenseAdded,
  @JsonValue('expense_deleted')
  expenseDeleted,
  @JsonValue('settlement_received')
  settlementReceived,
  @JsonValue('task_assigned')
  taskAssigned,
  @JsonValue('event_added')
  eventAdded,
  @JsonValue('member_joined')
  memberJoined,
  unknown;

  /// Which tab of the trip answers this notification.
  ///
  /// The point of the whole feature: tapping "Luca added an expense" and landing
  /// on the trip's calendar would leave the reader to go looking for the thing
  /// they were just told about.
  int get tab => switch (this) {
    NotificationKind.eventAdded => 0,
    NotificationKind.taskAssigned => 1,
    NotificationKind.expenseAdded ||
    NotificationKind.expenseDeleted ||
    NotificationKind.settlementReceived => 2,
    NotificationKind.memberJoined => 4,
    NotificationKind.unknown => 0,
  };
}

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String tripId,
    @JsonKey(unknownEnumValue: NotificationKind.unknown)
    required NotificationKind kind,
    String? actorId,
    String? entityId,
    // Raw facts frozen when it happened — a name, an amount, a title. The
    // sentence is built here, from the app's own translations, so switching
    // language does not leave the history written in the previous one.
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _AppNotification;

  const AppNotification._();

  bool get isUnread => readAt == null;

  String? get actorName => payload['actor_name'] as String?;
  String? get tripName => payload['trip_name'] as String?;
  String? get title => payload['title'] as String?;
  String? get description => payload['description'] as String?;
  int? get amountCents => (payload['amount_cents'] as num?)?.toInt();

  /// Frozen with the amount rather than read from the trip: the trip may have
  /// been renamed, re-denominated or deleted since, and the row still has to
  /// read as the sentence it was written as.
  String get currency => payload['currency'] as String? ?? 'EUR';

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

/// One page of the feed, and the cursor for the next.
///
/// The cursor is opaque on purpose: the client hands it back untouched, so the
/// server can change how pages are cut without a client release.
@freezed
abstract class NotificationPage with _$NotificationPage {
  const factory NotificationPage({
    required List<AppNotification> items,
    String? nextCursor,
  }) = _NotificationPage;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageFromJson(json);
}
