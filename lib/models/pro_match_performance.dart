/// Pro player performance in a specific match.
/// Used for "Weekend Standouts" feature.
class ProMatchPerformance {
  final String playerName;
  final String teamName;
  final String? teamCode;
  final String position;
  final int goals;
  final int assists;
  final String matchDescription;
  final DateTime matchDate;
  final String competitionCode;
  final double? rating;

  const ProMatchPerformance({
    required this.playerName,
    required this.teamName,
    this.teamCode,
    required this.position,
    required this.goals,
    required this.assists,
    required this.matchDescription,
    required this.matchDate,
    required this.competitionCode,
    this.rating,
  });

  /// Total contributions in this match.
  int get totalContributions => goals + assists;

  /// Whether this was an outstanding performance (2+ goals or 3+ contributions).
  bool get isOutstanding => goals >= 2 || totalContributions >= 3;

  factory ProMatchPerformance.fromJson(Map<String, dynamic> json) {
    return ProMatchPerformance(
      playerName: json['playerName'] ?? '',
      teamName: json['teamName'] ?? '',
      teamCode: json['teamCode'],
      position: json['position'] ?? '',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      matchDescription: json['matchDescription'] ?? '',
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'])
          : DateTime.now(),
      competitionCode: json['competitionCode'] ?? 'PL',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'teamName': teamName,
      'teamCode': teamCode,
      'position': position,
      'goals': goals,
      'assists': assists,
      'matchDescription': matchDescription,
      'matchDate': matchDate.toIso8601String(),
      'competitionCode': competitionCode,
      'rating': rating,
    };
  }
}