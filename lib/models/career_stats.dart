/// Career statistics for a player, calculated from match events.
class CareerStats {
  final int goals;
  final int assists;
  final int appearances;
  final int wins;
  final int draws;
  final int losses;
  final double avgRating;
  final int yellowCards;
  final int redCards;
  final int cleanSheets;
  final int hatTricks;
  final int motmAwards;
  final String primaryPosition;
  final String? secondaryPosition;
  final String? teamName;

  const CareerStats({
    this.goals = 0,
    this.assists = 0,
    this.appearances = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.avgRating = 6.0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.cleanSheets = 0,
    this.hatTricks = 0,
    this.motmAwards = 0,
    this.primaryPosition = '',
    this.secondaryPosition,
    this.teamName,
  });

  /// Win rate percentage.
  double get winRate => appearances > 0 ? (wins / appearances) * 100 : 0;

  /// Loss rate percentage.
  double get lossRate => appearances > 0 ? (losses / appearances) * 100 : 0;

  /// Total goal contributions.
  int get totalContributions => goals + assists;

  /// Goals per game average.
  double get goalsPerGame => appearances > 0 ? goals / appearances : 0;

  /// Assists per game average.
  double get assistsPerGame => appearances > 0 ? assists / appearances : 0;

  /// Goals per 90 minutes (assuming 90 min matches).
  double get goalsPer90 => goalsPerGame;

  /// Cards ratio.
  double get cardsPerGame => appearances > 0 ? (yellowCards + redCards) / appearances : 0;

  factory CareerStats.fromJson(Map<String, dynamic> json) {
    return CareerStats(
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      appearances: json['appearances'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      avgRating: json['avgRating'] != null
          ? (json['avgRating'] as num).toDouble()
          : 6.0,
      yellowCards: json['yellowCards'] ?? 0,
      redCards: json['redCards'] ?? 0,
      cleanSheets: json['cleanSheets'] ?? 0,
      hatTricks: json['hatTricks'] ?? 0,
      motmAwards: json['motmAwards'] ?? 0,
      primaryPosition: json['primaryPosition'] ?? '',
      secondaryPosition: json['secondaryPosition'],
      teamName: json['teamName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'assists': assists,
      'appearances': appearances,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'avgRating': avgRating,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'cleanSheets': cleanSheets,
      'hatTricks': hatTricks,
      'motmAwards': motmAwards,
      'primaryPosition': primaryPosition,
      'secondaryPosition': secondaryPosition,
      'teamName': teamName,
    };
  }

  /// Alias for toJson — used by badge award logic.
  Map<String, dynamic> toMap() => toJson();

  CareerStats copyWith({
    int? goals,
    int? assists,
    int? appearances,
    int? wins,
    int? draws,
    int? losses,
    double? avgRating,
    int? yellowCards,
    int? redCards,
    int? cleanSheets,
    int? hatTricks,
    int? motmAwards,
    String? primaryPosition,
    String? secondaryPosition,
    String? teamName,
  }) {
    return CareerStats(
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      appearances: appearances ?? this.appearances,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      avgRating: avgRating ?? this.avgRating,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      cleanSheets: cleanSheets ?? this.cleanSheets,
      hatTricks: hatTricks ?? this.hatTricks,
      motmAwards: motmAwards ?? this.motmAwards,
      primaryPosition: primaryPosition ?? this.primaryPosition,
      secondaryPosition: secondaryPosition ?? this.secondaryPosition,
      teamName: teamName ?? this.teamName,
    );
  }

  /// Merge with another CareerStats (for aggregating across seasons).
  CareerStats merge(CareerStats other) {
    final totalAppearances = appearances + other.appearances;
    return CareerStats(
      goals: goals + other.goals,
      assists: assists + other.assists,
      appearances: totalAppearances,
      wins: wins + other.wins,
      draws: draws + other.draws,
      losses: losses + other.losses,
      avgRating: totalAppearances > 0
          ? (avgRating * appearances + other.avgRating * other.appearances) / totalAppearances
          : 6.0,
      yellowCards: yellowCards + other.yellowCards,
      redCards: redCards + other.redCards,
      cleanSheets: cleanSheets + other.cleanSheets,
      hatTricks: hatTricks + other.hatTricks,
      motmAwards: motmAwards + other.motmAwards,
      primaryPosition: primaryPosition,
      secondaryPosition: secondaryPosition,
      teamName: teamName,
    );
  }
}