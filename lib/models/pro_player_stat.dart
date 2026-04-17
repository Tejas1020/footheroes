/// Pro player statistics from football-data.org API.
/// Used for comparison feature and cached in Appwrite.
class ProPlayerStat {
  final int id;
  final String name;
  final String position;
  final String teamName;
  final String? teamCode;
  final String nationality;
  final int goals;
  final int assists;
  final double? shotConversionRate;
  final int appearances;
  final int? minutesPlayed;
  final String? photoUrl;
  final String competitionCode;
  final DateTime fetchedAt;

  const ProPlayerStat({
    required this.id,
    required this.name,
    required this.position,
    required this.teamName,
    this.teamCode,
    required this.nationality,
    required this.goals,
    required this.assists,
    this.shotConversionRate,
    required this.appearances,
    this.minutesPlayed,
    this.photoUrl,
    required this.competitionCode,
    required this.fetchedAt,
  });

  /// Goals per game average.
  double get goalsPerGame => appearances > 0 ? goals / appearances : 0;

  /// Assists per game average.
  double get assistsPerGame => appearances > 0 ? assists / appearances : 0;

  /// Total goal contributions (goals + assists).
  int get totalContributions => goals + assists;

  /// Position group (attacker, midfielder, defender, goalkeeper).
  String get positionGroup {
    if (position.contains('ST') || position.contains('CF') || position.contains('LW') || position.contains('RW')) {
      return 'attacker';
    }
    if (position.contains('CM') || position.contains('CDM') || position.contains('CAM') || position.contains('LM') || position.contains('RM')) {
      return 'midfielder';
    }
    if (position.contains('CB') || position.contains('LB') || position.contains('RB') || position.contains('WB')) {
      return 'defender';
    }
    if (position.contains('GK')) {
      return 'goalkeeper';
    }
    return 'midfielder';
  }

  factory ProPlayerStat.fromJson(Map<String, dynamic> json) {
    return ProPlayerStat(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      teamName: json['teamName'] ?? '',
      teamCode: json['teamCode'],
      nationality: json['nationality'] ?? '',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      shotConversionRate: json['shotConversionRate'] != null
          ? (json['shotConversionRate'] as num).toDouble()
          : null,
      appearances: json['appearances'] ?? 0,
      minutesPlayed: json['minutesPlayed'],
      photoUrl: json['photoUrl'],
      competitionCode: json['competitionCode'] ?? 'PL',
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'teamName': teamName,
      'teamCode': teamCode,
      'nationality': nationality,
      'goals': goals,
      'assists': assists,
      'shotConversionRate': shotConversionRate,
      'appearances': appearances,
      'minutesPlayed': minutesPlayed,
      'photoUrl': photoUrl,
      'competitionCode': competitionCode,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  ProPlayerStat copyWith({
    int? id,
    String? name,
    String? position,
    String? teamName,
    String? teamCode,
    String? nationality,
    int? goals,
    int? assists,
    double? shotConversionRate,
    int? appearances,
    int? minutesPlayed,
    String? photoUrl,
    String? competitionCode,
    DateTime? fetchedAt,
  }) {
    return ProPlayerStat(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      teamName: teamName ?? this.teamName,
      teamCode: teamCode ?? this.teamCode,
      nationality: nationality ?? this.nationality,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      shotConversionRate: shotConversionRate ?? this.shotConversionRate,
      appearances: appearances ?? this.appearances,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      photoUrl: photoUrl ?? this.photoUrl,
      competitionCode: competitionCode ?? this.competitionCode,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}