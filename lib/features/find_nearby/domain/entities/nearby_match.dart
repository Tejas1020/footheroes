import 'playing_position.dart';

/// An open match discoverable by nearby players.
class NearbyMatch {
  final String id;
  final String? venueId;
  final String? venueName;
  final double? latitude;
  final double? longitude;
  final String? geohashPrefix;
  final String format;
  final DateTime startTime;
  final bool openToNearby;
  final int slotsNeeded;
  final int slotsRemaining;
  final List<PlayingPosition> requiredPositions;
  final DateTime? requestsCloseAt;
  final String createdBy;
  final double? distanceKm;

  const NearbyMatch({
    required this.id,
    this.venueId,
    this.venueName,
    this.latitude,
    this.longitude,
    this.geohashPrefix,
    required this.format,
    required this.startTime,
    required this.openToNearby,
    required this.slotsNeeded,
    required this.slotsRemaining,
    required this.requiredPositions,
    this.requestsCloseAt,
    required this.createdBy,
    this.distanceKm,
  });
}
