// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_pin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapPin _$MapPinFromJson(Map<String, dynamic> json) => _MapPin(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  category: $enumDecode(_$PinCategoryEnumMap, json['category']),
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MapPinToJson(_MapPin instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'name': instance.name,
  'description': instance.description,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'category': _$PinCategoryEnumMap[instance.category]!,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$PinCategoryEnumMap = {
  PinCategory.lodging: 'lodging',
  PinCategory.food: 'food',
  PinCategory.meetingPoint: 'meeting_point',
  PinCategory.parking: 'parking',
  PinCategory.sight: 'sight',
  PinCategory.other: 'other',
};

_MemberLocation _$MemberLocationFromJson(Map<String, dynamic> json) =>
    _MemberLocation(
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$MemberLocationToJson(_MemberLocation instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy_m': instance.accuracyM,
      'updated_at': instance.updatedAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };
