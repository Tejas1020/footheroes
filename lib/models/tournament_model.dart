import 'dart:convert';

/// Tournament model matching the Appwrite tournaments collection.
class TournamentModel {
  final String id;
  final String tournamentId;
  final String name;
  final String format;           // '5v5', '7v7', '9v9', '11v11'
  final String type;             // 'knockout', 'league', 'group_knockout'
  final int maxTeams;            // 4, 8, 16, 32
  final List<String> teamIds;
  final String createdBy;        // userId of organizer
  final String status;           // 'draft','registration','active','completed'
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venue;
  final String? description;
  final bool isPaid;             // true if organizer paid for tournament
  final String? sponsorName;    // optional sponsor branding
  final String? sponsorLogoUrl;
  final Map<String, dynamic>? settings; // flexible settings
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.format,
    this.type = 'knockout',
    this.maxTeams = 8,
    this.teamIds = const [],
    required this.createdBy,
    this.status = 'draft',
    this.startDate,
    this.endDate,
    this.venue,
    this.description,
    this.isPaid = false,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.settings,
    required this.createdAt,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['\$id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      name: json['name'] ?? '',
      format: json['format'] ?? '5v5',
      type: json['type'] ?? 'knockout',
      maxTeams: json['maxTeams'] ?? 8,
      teamIds: json['teams'] != null ? List<String>.from(json['teams']) : (json['teamIds'] != null ? List<String>.from(json['teamIds']) : []),
      createdBy: json['createdBy'] ?? '',
      status: json['status'] ?? 'draft',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      venue: json['venue'],
      description: json['description'],
      isPaid: json['isPaid'] ?? false,
      sponsorName: json['sponsorName'],
      sponsorLogoUrl: json['sponsorLogoUrl'],
      settings: json['settings'] != null
          ? jsonDecode(json['settings']) as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'format': format,
      'type': type,
      'maxTeams': maxTeams,
      'teams': teamIds,
      'createdBy': createdBy,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'venue': venue,
      'description': description,
      'isPaid': isPaid,
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'settings': settings != null ? jsonEncode(settings) : null,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TournamentModel copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? format,
    String? type,
    int? maxTeams,
    List<String>? teamIds,
    String? createdBy,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    String? description,
    bool? isPaid,
    String? sponsorName,
    String? sponsorLogoUrl,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      format: format ?? this.format,
      type: type ?? this.type,
      maxTeams: maxTeams ?? this.maxTeams,
      teamIds: teamIds ?? this.teamIds,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      isPaid: isPaid ?? this.isPaid,
      sponsorName: sponsorName ?? this.sponsorName,
      sponsorLogoUrl: sponsorLogoUrl ?? this.sponsorLogoUrl,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getters
  bool get isDraft => status == 'draft';
  bool get isRegistration => status == 'registration';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  int get teamsRegistered => teamIds.length;
  int get spotsRemaining => maxTeams - teamIds.length;
  bool get isFull => teamIds.length >= maxTeams;
  bool get canStart => teamIds.length >= 2 && (isDraft || isRegistration);

  // Round count for knockout
  int get roundCount {
    if (type != 'knockout' && type != 'group_knockout') return 0;
    int teams = maxTeams;
    int rounds = 0;
    while (teams > 1) {
      teams ~/= 2;
      rounds++;
    }
    return rounds;
  }

  // Get round name for a given round number (1-indexed from final)
  String getRoundName(int roundFromFinal) {
    switch (roundFromFinal) {
      case 1: return 'Final';
      case 2: return 'Semi-Final';
      case 3: return 'Quarter-Final';
      case 4: return 'Round of 16';
      case 5: return 'Round of 32';
      default: return 'Round $roundFromFinal';
    }
  }
}

/// Bracket model for knockout tournaments.
class BracketModel {
  final String id;
  final String tournamentId;
  final List<BracketRound> rounds;
  final String? winnerId;        // teamId of tournament winner
  final String? winnerName;
  final DateTime updatedAt;

  const BracketModel({
    required this.id,
    required this.tournamentId,
    required this.rounds,
    this.winnerId,
    this.winnerName,
    required this.updatedAt,
  });

  factory BracketModel.fromJson(Map<String, dynamic> json) {
    final roundsData = json['rounds'] as List? ?? [];
    return BracketModel(
      id: json['\$id'] ?? json['id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      rounds: roundsData
          .map((r) => BracketRound.fromJson(r as Map<String, dynamic>))
          .toList(),
      winnerId: json['winnerId'],
      winnerName: json['winnerName'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'winnerId': winnerId,
      'winnerName': winnerName,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BracketModel copyWith({
    String? id,
    String? tournamentId,
    List<BracketRound>? rounds,
    String? winnerId,
    String? winnerName,
    DateTime? updatedAt,
  }) {
    return BracketModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      rounds: rounds ?? this.rounds,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasWinner => winnerId != null;
  int get totalMatches => rounds.fold(0, (sum, r) => sum + r.matches.length);
  int get completedMatches => rounds.fold(
    0, (sum, r) => sum + r.matches.where((m) => m.isCompleted).length
  );
}

/// A single round in the bracket.
class BracketRound {
  final int roundNumber;
  final String roundName;        // 'Quarter Final', 'Semi Final', 'Final'
  final List<TournamentMatchModel> matches;

  const BracketRound({
    required this.roundNumber,
    required this.roundName,
    required this.matches,
  });

  factory BracketRound.fromJson(Map<String, dynamic> json) {
    final matchesData = json['matches'] as List? ?? [];
    return BracketRound(
      roundNumber: json['roundNumber'] ?? 0,
      roundName: json['roundName'] ?? '',
      matches: matchesData
          .map((m) => TournamentMatchModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'roundName': roundName,
      'matches': matches.map((m) => m.toJson()).toList(),
    };
  }

  BracketRound copyWith({
    int? roundNumber,
    String? roundName,
    List<TournamentMatchModel>? matches,
  }) {
    return BracketRound(
      roundNumber: roundNumber ?? this.roundNumber,
      roundName: roundName ?? this.roundName,
      matches: matches ?? this.matches,
    );
  }
}

/// Tournament match model.
class TournamentMatchModel {
  final String id;
  final String matchId;
  final String tournamentId;
  final String? homeTeamId;
  final String? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final String status;           // 'scheduled','live','completed','bye'
  final int roundNumber;
  final int matchNumber;
  final DateTime? scheduledTime;
  final String? winnerId;
  final String? winnerName;

  const TournamentMatchModel({
    required this.id,
    required this.matchId,
    required this.tournamentId,
    this.homeTeamId,
    this.awayTeamId,
    this.homeTeamName,
    this.awayTeamName,
    this.homeScore,
    this.awayScore,
    this.status = 'scheduled',
    required this.roundNumber,
    required this.matchNumber,
    this.scheduledTime,
    this.winnerId,
    this.winnerName,
  });

  bool get isCompleted => status == 'completed';
  bool get isLive => status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isBye => status == 'bye';
  bool get hasTeams => homeTeamId != null && awayTeamId != null;
  bool get hasWinner => winnerId != null;

  factory TournamentMatchModel.fromJson(Map<String, dynamic> json) {
    return TournamentMatchModel(
      id: json['\$id'] ?? json['id'] ?? '',
      matchId: json['matchId'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      homeTeamId: json['homeTeamId'],
      awayTeamId: json['awayTeamId'],
      homeTeamName: json['homeTeamName'],
      awayTeamName: json['awayTeamName'],
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      status: json['status'] ?? 'scheduled',
      roundNumber: json['roundNumber'] ?? 0,
      matchNumber: json['matchNumber'] ?? 0,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      winnerId: json['winnerId'],
      winnerName: json['winnerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
      'roundNumber': roundNumber,
      'matchNumber': matchNumber,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'winnerId': winnerId,
      'winnerName': winnerName,
    };
  }

  TournamentMatchModel copyWith({
    String? id,
    String? matchId,
    String? tournamentId,
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    int? homeScore,
    int? awayScore,
    String? status,
    int? roundNumber,
    int? matchNumber,
    DateTime? scheduledTime,
    String? winnerId,
    String? winnerName,
  }) {
    return TournamentMatchModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      tournamentId: tournamentId ?? this.tournamentId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      roundNumber: roundNumber ?? this.roundNumber,
      matchNumber: matchNumber ?? this.matchNumber,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
    );
  }
}

/// Tournament team model for standings.
class TournamentTeamModel {
  final String id;
  final String tournamentId;
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const TournamentTeamModel({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  factory TournamentTeamModel.fromJson(Map<String, dynamic> json) {
    return TournamentTeamModel(
      id: json['\$id'] ?? json['id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      played: json['played'] ?? 0,
      won: json['won'] ?? 0,
      drawn: json['drawn'] ?? 0,
      lost: json['lost'] ?? 0,
      goalsFor: json['goalsFor'] ?? 0,
      goalsAgainst: json['goalsAgainst'] ?? 0,
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'points': points,
    };
  }

  TournamentTeamModel copyWith({
    String? id,
    String? tournamentId,
    String? teamId,
    String? teamName,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
  }) {
    return TournamentTeamModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
    );
  }

  /// Record a win.
  TournamentTeamModel recordWin(int goalsScored, int goalsConceded) {
    return copyWith(
      played: played + 1,
      won: won + 1,
      goalsFor: goalsFor + goalsScored,
      goalsAgainst: goalsAgainst + goalsConceded,
      points: points + 3,
    );
  }

  /// Record a draw.
  TournamentTeamModel recordDraw(int goalsScored, int goalsConceded) {
    return copyWith(
      played: played + 1,
      drawn: drawn + 1,
      goalsFor: goalsFor + goalsScored,
      goalsAgainst: goalsAgainst + goalsConceded,
      points: points + 1,
    );
  }

  /// Record a loss.
  TournamentTeamModel recordLoss(int goalsScored, int goalsConceded) {
    return copyWith(
      played: played + 1,
      lost: lost + 1,
      goalsFor: goalsFor + goalsScored,
      goalsAgainst: goalsAgainst + goalsConceded,
    );
  }
}