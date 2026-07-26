import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

enum ItemType {
  @JsonValue('event')
  event,
  @JsonValue('task')
  task,
}

/// A calendar entry or a to-do, discriminated by [type].
///
/// One class for both because the server keeps them in one table: an event is
/// an item with a time, a task is an item with assignees and a completion.
@freezed
abstract class Item with _$Item {
  const factory Item({
    required String id,
    required String tripId,
    required ItemType type,
    required String title,
    String? description,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    // A list, not a single id: shared chores routinely belong to more than one
    // person, and the join table on the server allows exactly that.
    @Default(<String>[]) List<String> assignees,
    DateTime? completedAt,
    String? completedBy,
    required String createdBy,
    required DateTime createdAt,
  }) = _Item;

  const Item._();

  bool get isDone => completedAt != null;
  bool get isTask => type == ItemType.task;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}
