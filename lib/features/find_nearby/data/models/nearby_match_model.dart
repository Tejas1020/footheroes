import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';

part 'nearby_match_model.freezed.dart';
part 'nearby_match_model.g.dart';

@freezed
abstract class NearbyMatchModel with _$NearbyMatchModel {
  const factory NearbyMatchModel({
    @JsonKey(name: '\$id') required String id,
    String? venueId,
    String? venueName,
    double? latitude,
    double? longitude,
    String? geohashPrefix,
    required String format,
    required DateTime startTime,
    @Default(false) bool openToNearby,
    @Default(0) int slotsNeeded,
    @Default(0) int slotsRemaining,
    String? requiredPositions,
    DateTime? requestsCloseAt,
    required String createdBy,
    double? distanceKm,
  }) = _NearbyMatchModel;

  factory NearbyMatchModel.fromJson(Map<String, dynamic> json) =>
      _$NearbyMatchModelFromJson(json);
}

extension NearbyMatchModelX on NearbyMatchModel {
  NearbyMatch toEntity() => NearbyMatch(
        id: id,
        venueId: venueId,
        venueName: venueName,
        latitude: latitude,
        longitude: longitude,
        geohashPrefix: geohashPrefix,
        format: format,
        startTime: startTime,
        openToNearby: openToNearby,
        slotsNeeded: slotsNeeded,
        slotsRemaining: slotsRemaining,
        requiredPositions: _parsePositions(requiredPositions),
        requestsCloseAt: requestsCloseAt,
        createdBy: createdBy,
        distanceKm: distanceKm,
      );

  static List<PlayingPosition> _parsePositions(String? value) {
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((s) => PlayingPositionX.fromString(s.trim()))
        .toList();
  }
}

extension NearbyMatchModelFromEntity on NearbyMatch {
  Map<String, dynamic> toModelJson() => {
        'venueId': venueId,
        'venueName': venueName,
        'latitude': latitude,
        'longitude': longitude,
        'geohashPrefix': geohashPrefix,
        'format': format,
        'startTime': startTime.toIso8601String(),
        'openToNearby': openToNearby,
        'slotsNeeded': slotsNeeded,
        'slotsRemaining': slotsRemaining,
        'requiredPositions': requiredPositions.map((p) => p.value).join(','),
        'requestsCloseAt': requestsCloseAt?.toIso8601String(),
        'createdBy': createdBy,
      };
}
