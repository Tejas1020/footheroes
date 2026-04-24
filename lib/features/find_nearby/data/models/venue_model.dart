import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/venue.dart';

part 'venue_model.freezed.dart';
part 'venue_model.g.dart';

@freezed
abstract class VenueModel with _$VenueModel {
  const factory VenueModel({
    @JsonKey(name: '\$id') required String id,
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required String geohash,
    required String createdBy,
    required DateTime createdAt,
  }) = _VenueModel;

  factory VenueModel.fromJson(Map<String, dynamic> json) =>
      _$VenueModelFromJson(json);
}

extension VenueModelX on VenueModel {
  Venue toEntity() => Venue(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}
