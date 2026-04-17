/// Match event model matching the Appwrite matchEvents collection.
class MatchEventModel {
  final String id;
  final String eventId;
  final String matchId;
  final String type;
  final String playerId;
  final String playerName;
  final int minute;
  final String? details;
  final String team; // 'home' or 'away'

  const MatchEventModel({
    required this.id,
    required this.eventId,
    required this.matchId,
    required this.type,
    required this.playerId,
    required this.playerName,
    required this.minute,
    this.details,
    this.team = 'home',
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      id: json['\$id'] ?? '',
      eventId: json['eventId'] ?? '',
      matchId: json['matchId'] ?? '',
      type: json['type'] ?? '',
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      minute: json['minute'] ?? 0,
      details: json['details'],
      team: json['team'] ?? 'home',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'matchId': matchId,
      'type': type,
      'playerId': playerId,
      'playerName': playerName,
      'minute': minute,
      'details': details,
      'team': team,
    };
  }

  MatchEventModel copyWith({
    String? id,
    String? eventId,
    String? matchId,
    String? type,
    String? playerId,
    String? playerName,
    int? minute,
    String? details,
    String? team,
  }) {
    return MatchEventModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      matchId: matchId ?? this.matchId,
      type: type ?? this.type,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      minute: minute ?? this.minute,
      details: details ?? this.details,
      team: team ?? this.team,
    );
  }

  bool get isGoal => type == 'goal';
  bool get isAssist => type == 'assist';
  bool get isYellowCard => type == 'yellowCard';
  bool get isRedCard => type == 'redCard';
  bool get isSubOn => type == 'subOn';
  bool get isSubOff => type == 'subOff';

  String get displayShort => switch (type) {
    'goal' => 'G',
    'assist' => 'A',
    'yellowCard' => 'YC',
    'redCard' => 'RC',
    'subOn' => 'SO',
    'subOff' => 'SF',
    _ => type,
  };

  String get displayFull => switch (type) {
    'goal' => 'Goal',
    'assist' => 'Assist',
    'yellowCard' => 'Yellow Card',
    'redCard' => 'Red Card',
    'subOn' => 'Sub On',
    'subOff' => 'Sub Off',
    _ => type,
  };
}