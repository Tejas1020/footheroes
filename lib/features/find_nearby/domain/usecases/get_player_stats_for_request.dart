class PlayerStatsForRequest {
  final String playerId;
  final String playerName;
  final String primaryPosition;
  final int appearances;
  final double avgRating;
  final int goals;
  final int assists;

  const PlayerStatsForRequest({
    required this.playerId,
    required this.playerName,
    required this.primaryPosition,
    required this.appearances,
    required this.avgRating,
    required this.goals,
    required this.assists,
  });
}

class GetPlayerStatsForRequest {
  Future<PlayerStatsForRequest?> call(String playerId) async {
    // Fetch from player_stats_provider or API
    // Placeholder implementation
    return null;
  }
}
