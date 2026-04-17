import 'dart:convert';

/// Leaderboard model matching the Appwrite leaderboards collection.
class LeaderboardModel {
  final String id;
  final String area;
  final String position;
  final String timeframe;
  final List<RankingEntry> rankings;
  final DateTime updatedAt;

  const LeaderboardModel({
    required this.id,
    required this.area,
    required this.position,
    required this.timeframe,
    required this.rankings,
    required this.updatedAt,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    List<RankingEntry> rankingsList = [];
    if (json['rankings'] != null) {
      final rankingsData = jsonDecode(json['rankings']) as List;
      rankingsList = rankingsData
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return LeaderboardModel(
      id: json['\$id'] ?? '',
      area: json['area'] ?? '',
      position: json['position'] ?? '',
      timeframe: json['timeframe'] ?? 'monthly',
      rankings: rankingsList,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'position': position,
      'timeframe': timeframe,
      'rankings': jsonEncode(rankings.map((e) => e.toJson()).toList()),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// A single ranking entry in the leaderboard.
class RankingEntry {
  final int rank;
  final String userId;
  final String name;
  final String location;
  final String? teamName;
  final String position;
  final int goals;
  final int assists;
  final double avgRating;
  final int? trendValue;
  final bool? trendUp;

  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.location,
    this.teamName,
    this.position = '',
    required this.goals,
    this.assists = 0,
    this.avgRating = 6.0,
    this.trendValue,
    this.trendUp,
  });

  /// Total goal contributions (goals + assists).
  int get totalContributions => goals + assists;

  /// Primary stat for display (goals for attackers, clean sheets for GK/DEF).
  String get primaryStat {
    if (position.contains('GK') || position.contains('CB') || position.contains('LB') || position.contains('RB')) {
      return 'CS'; // Clean sheets for defenders/GK
    }
    return '$goals⚽';
  }

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      teamName: json['teamName'],
      position: json['position'] ?? '',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      avgRating: json['avgRating'] != null
          ? (json['avgRating'] as num).toDouble()
          : 6.0,
      trendValue: json['trendValue'],
      trendUp: json['trendUp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'name': name,
      'location': location,
      'teamName': teamName,
      'position': position,
      'goals': goals,
      'assists': assists,
      'avgRating': avgRating,
      'trendValue': trendValue,
      'trendUp': trendUp,
    };
  }
}