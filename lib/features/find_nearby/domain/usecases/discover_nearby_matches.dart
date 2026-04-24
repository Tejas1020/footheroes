import '../../../../core/utils/geohash_utils.dart';
import '../entities/nearby_match.dart';
import '../entities/playing_position.dart';
import '../repositories/discovery_block_repository.dart';
import '../repositories/nearby_match_repository.dart';

/// Input parameters for discovering nearby matches.
class DiscoverNearbyMatchesParams {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? playerPosition;
  final String? playerUid;

  const DiscoverNearbyMatchesParams({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.playerPosition,
    this.playerUid,
  });
}

/// Discover open matches near a given location.
class DiscoverNearbyMatches {
  final NearbyMatchRepository _matchRepo;
  final DiscoveryBlockRepository _blockRepo;

  const DiscoverNearbyMatches(this._matchRepo, this._blockRepo);

  Future<List<NearbyMatch>> call(DiscoverNearbyMatchesParams params) async {
    // 1. Encode center point to geohash precision 6
    final centerGeohash = GeohashUtils.encode(
      params.latitude,
      params.longitude,
      6,
    );

    // 2. Get center + 8 neighbor prefixes
    final prefixes = GeohashUtils.getNeighborPrefixes(centerGeohash).toList();

    // 3. Query Appwrite for matches in those prefixes
    var matches = await _matchRepo.findByGeohashPrefixes(prefixes);

    // 4. Client-side exact distance filter
    matches = matches.where((m) {
      if (m.latitude == null || m.longitude == null) return false;
      final distance = GeohashUtils.haversineDistanceKm(
        params.latitude,
        params.longitude,
        m.latitude!,
        m.longitude!,
      );
      return distance <= params.radiusKm;
    }).toList();

    // 5. Filter by player position compatibility
    if (params.playerPosition != null && params.playerPosition!.isNotEmpty) {
      matches = matches.where((m) {
        if (m.requiredPositions.isEmpty) return true;
        final pos = PlayingPositionX.fromString(params.playerPosition!);
        return m.requiredPositions.contains(PlayingPosition.any) ||
            m.requiredPositions.contains(pos);
      }).toList();
    }

    // 6. Filter out blocked creators
    if (params.playerUid != null) {
      final filtered = <NearbyMatch>[];
      for (final match in matches) {
        final blocked = await _blockRepo.isBlocked(
          match.createdBy,
          params.playerUid!,
        );
        if (!blocked) filtered.add(match);
      }
      matches = filtered;
    }

    // 7. Sort by distance
    matches.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });

    return matches;
  }
}
