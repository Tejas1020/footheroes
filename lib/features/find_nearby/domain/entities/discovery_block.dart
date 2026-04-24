/// Blocks a player from seeing a creator's matches in discovery.
class DiscoveryBlock {
  final String id;
  final String creatorUid;
  final String playerUid;
  final DateTime createdAt;

  const DiscoveryBlock({
    required this.id,
    required this.creatorUid,
    required this.playerUid,
    required this.createdAt,
  });
}
