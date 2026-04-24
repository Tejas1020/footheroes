import '../entities/discovery_block.dart';

/// Repository for discovery blocks (mutual quiet filter).
abstract class DiscoveryBlockRepository {
  /// Check if a player is blocked from seeing a creator's matches.
  Future<bool> isBlocked(String creatorUid, String playerUid);

  /// Create a block record.
  Future<DiscoveryBlock> block(String creatorUid, String playerUid);
}
