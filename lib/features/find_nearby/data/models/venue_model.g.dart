// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VenueModel _$VenueModelFromJson(Map<String, dynamic> json) => _VenueModel(
  id: json[r'$id'] as String,
  name: json['name'] as String,
  address: json['address'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  geohash: json['geohash'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$VenueModelToJson(_VenueModel instance) =>
    <String, dynamic>{
      r'$id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geohash': instance.geohash,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
