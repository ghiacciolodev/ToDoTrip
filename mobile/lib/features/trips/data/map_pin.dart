import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'map_pin.freezed.dart';
part 'map_pin.g.dart';

enum PinCategory {
  @JsonValue('lodging')
  lodging,
  @JsonValue('food')
  food,
  @JsonValue('meeting_point')
  meetingPoint,
  @JsonValue('parking')
  parking,
  @JsonValue('sight')
  sight,
  @JsonValue('other')
  other;

  /// Drawn inside the pin, so a glance at the map answers "what is this".
  IconData get icon => switch (this) {
    PinCategory.lodging => Icons.hotel,
    PinCategory.food => Icons.restaurant,
    PinCategory.meetingPoint => Icons.groups,
    PinCategory.parking => Icons.local_parking,
    PinCategory.sight => Icons.photo_camera,
    PinCategory.other => Icons.place,
  };

  /// What the API calls it. json_serializable decodes with @JsonValue; this is
  /// the other direction, for request bodies built by hand.
  String get wire => switch (this) {
    PinCategory.meetingPoint => 'meeting_point',
    _ => name,
  };

  String get label => switch (this) {
    PinCategory.lodging => 'Lodging',
    PinCategory.food => 'Food',
    PinCategory.meetingPoint => 'Meeting point',
    PinCategory.parking => 'Parking',
    PinCategory.sight => 'Sight',
    PinCategory.other => 'Other',
  };
}

/// A place the group saved. Durable, unlike a member's position.
@freezed
abstract class MapPin with _$MapPin {
  const factory MapPin({
    required String id,
    required String tripId,
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    required PinCategory category,
    required String createdBy,
    required DateTime createdAt,
  }) = _MapPin;

  const MapPin._();

  LatLng get point => LatLng(latitude, longitude);

  factory MapPin.fromJson(Map<String, dynamic> json) => _$MapPinFromJson(json);
}

/// Where a member is right now.
///
/// Never stored beyond its TTL and never accumulated into a trail: the app
/// keeps the latest position per person and nothing else.
@freezed
abstract class MemberLocation with _$MemberLocation {
  const factory MemberLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double? accuracyM,
    required DateTime updatedAt,
    required DateTime expiresAt,
  }) = _MemberLocation;

  const MemberLocation._();

  LatLng get point => LatLng(latitude, longitude);

  /// Old enough that the map should say when it was, rather than imply "now".
  bool get isStale =>
      DateTime.now().difference(updatedAt) > const Duration(minutes: 2);

  factory MemberLocation.fromJson(Map<String, dynamic> json) =>
      _$MemberLocationFromJson(json);
}
