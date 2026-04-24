/// Default pitch slot positions keyed by standard position label.
/// Maps a position like 'GK', 'CB', 'CM' → (xPercent, yPercent) on the pitch.
const Map<String, List<double>> kPositionDefaults = {
  'GK': [0.5, 0.92],
  'SW': [0.5, 0.84],
  'CB': [0.34, 0.80],
  'LCB': [0.28, 0.80],
  'RCB': [0.40, 0.80],
  'RB': [0.82, 0.72],
  'LB': [0.18, 0.72],
  'RWB': [0.85, 0.72],
  'LWB': [0.15, 0.72],
  'CDM': [0.5, 0.64],
  'RDM': [0.72, 0.64],
  'LDM': [0.28, 0.64],
  'CM': [0.5, 0.52],
  'LCM': [0.35, 0.52],
  'RCM': [0.65, 0.52],
  'RM': [0.80, 0.44],
  'LM': [0.20, 0.44],
  'CAM': [0.5, 0.38],
  'RAM': [0.72, 0.38],
  'LAM': [0.28, 0.38],
  'RW': [0.82, 0.28],
  'LW': [0.18, 0.28],
  'RF': [0.65, 0.22],
  'LF': [0.35, 0.22],
  'ST': [0.5, 0.18],
  'CF': [0.5, 0.18],
};

/// Resolve x/y for a roster entry: use saved coords if available, otherwise fall back
/// to kPositionDefaults lookup by position label, then center-mid fallback.
List<double> rosterEntryPosition(MatchRosterEntry entry) {
  // If entry ever gets xPercent/yPercent stored, check here.
  final label = entry.position.trim().toUpperCase();
  return kPositionDefaults[label] ?? [0.5, 0.52];
}

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
  final bool isCaptain;

  const MatchRosterEntry({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.playerEmail,
    this.position = '',
    this.isRegistered = false,
    this.team,
    this.isCaptain = false,
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
      isCaptain: json['isCaptain'] ?? false,
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
      'isCaptain': isCaptain,
    };
  }

  MatchRosterEntry copyWith({
    String? id,
    String? matchId,
    String? playerId,
    String? playerName,
    String? playerEmail,
    String? position,
    bool? isRegistered,
    String? team,
    bool? isCaptain,
  }) {
    return MatchRosterEntry(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerEmail: playerEmail ?? this.playerEmail,
      position: position ?? this.position,
      isRegistered: isRegistered ?? this.isRegistered,
      team: team ?? this.team,
      isCaptain: isCaptain ?? this.isCaptain,
    );
  }
}