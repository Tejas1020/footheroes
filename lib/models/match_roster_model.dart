/// Model for a player in a match roster, persisted in Appwrite.
class MatchRosterEntry {
  final String id;
  final String matchId;
  final String playerId;
  final String playerName;
  final String? playerEmail;
  final String position;
  final bool isRegistered;
  final String? team; // 'home' or 'away'

  const MatchRosterEntry({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.playerEmail,
    this.position = '',
    this.isRegistered = false,
    this.team,
  });

  factory MatchRosterEntry.fromJson(Map<String, dynamic> json) {
    return MatchRosterEntry(
      id: json['\$id'] ?? '',
      matchId: json['matchId'] ?? '',
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      playerEmail: json['playerEmail'],
      position: json['position'] ?? '',
      isRegistered: json['isRegistered'] ?? false,
      team: json['team'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'playerId': playerId,
      'playerName': playerName,
      if (playerEmail != null) 'playerEmail': playerEmail,
      'position': position,
      'isRegistered': isRegistered,
      if (team != null) 'team': team,
    };
  }
}