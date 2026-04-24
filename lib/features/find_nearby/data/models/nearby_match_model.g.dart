// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NearbyMatchModel _$NearbyMatchModelFromJson(Map<String, dynamic> json) =>
    _NearbyMatchModel(
      id: json[r'$id'] as String,
      venueId: json['venueId'] as String?,
      venueName: json['venueName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geohashPrefix: json['geohashPrefix'] as String?,
      format: json['format'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      openToNearby: json['openToNearby'] as bool? ?? false,
      slotsNeeded: (json['slotsNeeded'] as num?)?.toInt() ?? 0,
      slotsRemaining: (json['slotsRemaining'] as num?)?.toInt() ?? 0,
      requiredPositions: json['requiredPositions'] as String?,
      requestsCloseAt: json['requestsCloseAt'] == null
          ? null
          : DateTime.parse(json['requestsCloseAt'] as String),
      createdBy: json['createdBy'] as String,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$NearbyMatchModelToJson(_NearbyMatchModel instance) =>
    <String, dynamic>{
      r'$id': instance.id,
      'venueId': instance.venueId,
      'venueName': instance.venueName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geohashPrefix': instance.geohashPrefix,
      'format': instance.format,
      'startTime': instance.startTime.toIso8601String(),
      'openToNearby': instance.openToNearby,
      'slotsNeeded': instance.slotsNeeded,
      'slotsRemaining': instance.slotsRemaining,
      'requiredPositions': instance.requiredPositions,
      'requestsCloseAt': instance.requestsCloseAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'distanceKm': instance.distanceKm,
    };
