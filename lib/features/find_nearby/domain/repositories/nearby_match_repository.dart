import '../entities/nearby_match.dart';
import '../entities/playing_position.dart';

/// Filters for discovering nearby matches.
class NearbyMatchFilters {
  final List<String>? formats;
  final String? skillLevel;
  final DateTime? minDate;
  final DateTime? maxDate;
  final double? maxRadiusKm;
  final List<PlayingPosition>? positions;

  const NearbyMatchFilters({
    this.formats,
    this.skillLevel,
    this.minDate,
    this.maxDate,
    this.maxRadiusKm,
    this.positions,
  });
}

/// Repository for discovering and managing open matches.
abstract class NearbyMatchRepository {
  /// Find open matches whose geohash prefix overlaps the given prefixes.
  Future<List<NearbyMatch>> findByGeohashPrefixes(
    List<String> prefixes, {
    NearbyMatchFilters? filters,
  });

  /// Get a single match by ID.
  Future<NearbyMatch?> getById(String id);

  /// Update match fields (e.g., slotsRemaining, openToNearby).
  Future<NearbyMatch> update(String id, Map<String, dynamic> data);
}
