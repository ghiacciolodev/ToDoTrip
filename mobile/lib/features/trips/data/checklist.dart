import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist.freezed.dart';
part 'checklist.g.dart';

/// One line of a checklist.
///
/// Deliberately thin next to [Item]: these are picked up in the moment, by
/// whoever is holding the phone in the shop, so the only state worth keeping is
/// whether someone has already got it.
@freezed
abstract class ChecklistEntry with _$ChecklistEntry {
  const factory ChecklistEntry({
    required String id,
    required String checklistId,
    required String text,
    DateTime? checkedAt,
    String? checkedBy,
    required DateTime createdAt,
  }) = _ChecklistEntry;

  const ChecklistEntry._();

  bool get isChecked => checkedAt != null;

  factory ChecklistEntry.fromJson(Map<String, dynamic> json) =>
      _$ChecklistEntryFromJson(json);
}

/// A named container of short things to tick off, e.g. the groceries.
@freezed
abstract class Checklist with _$Checklist {
  const factory Checklist({
    required String id,
    required String tripId,
    required String name,
    required String createdBy,
    required DateTime createdAt,
    // The API inlines them, so a card can show how far along it is without a
    // request per list.
    @Default(<ChecklistEntry>[]) List<ChecklistEntry> entries,
  }) = _Checklist;

  const Checklist._();

  int get checkedCount => entries.where((e) => e.isChecked).length;

  /// Empty reads as "not started", never as done.
  double get progress =>
      entries.isEmpty ? 0 : checkedCount / entries.length;

  factory Checklist.fromJson(Map<String, dynamic> json) =>
      _$ChecklistFromJson(json);
}
