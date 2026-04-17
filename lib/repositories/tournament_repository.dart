import 'dart:math';
import 'package:appwrite/appwrite.dart';
import '../environment.dart';
import '../models/tournament_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class TournamentRepository extends BaseRepository<TournamentModel> {
  final TablesDB _tablesDB;

  TournamentRepository(AppwriteService service)
      : _tablesDB = service.tablesDB,
        super(service, Environment.tournamentsCollectionId);

  @override
  TournamentModel fromJson(Map<String, dynamic> json) => TournamentModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(TournamentModel item) => item.toJson();

  // ===========================================================================
  // TOURNAMENT CRUD
  // ===========================================================================

  Future<TournamentModel> createTournament(TournamentModel tournament) async {
    return create(tournament.tournamentId, tournament.toJson());
  }

  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    return update(tournament.id, tournament.toJson());
  }

  Future<TournamentModel?> getTournament(String tournamentId) async {
    return getById(tournamentId);
  }

  Future<List<TournamentModel>> getUserTournaments(String userId) async {
    return getAll(queries: [
      Query.equal('createdBy', [userId]),
      Query.orderDesc('createdAt'),
    ]);
  }

  Future<List<TournamentModel>> getPublicTournaments({String? location}) async {
    return getAll(queries: [
      Query.equal('status', ['registration']),
      Query.orderAsc('startDate'),
    ]);
  }

  Future<TournamentModel?> updateTournamentStatus(String tournamentId, String status) async {
    try {
      return await update(tournamentId, {'status': status});
    } on AppwriteException {
      return null;
    }
  }

  // ===========================================================================
  // TEAMS
  // ===========================================================================

  Future<TournamentModel?> addTeamToTournament(String tournamentId, String teamId) async {
    final tournament = await getById(tournamentId);
    if (tournament == null) return null;
    if (tournament.teamIds.contains(teamId)) return tournament;
    if (tournament.isFull) return null;

    final updatedTeams = [...tournament.teamIds, teamId];
    try {
      return await update(tournamentId, {'teams': updatedTeams});
    } on AppwriteException {
      return null;
    }
  }

  Future<TournamentModel?> removeTeamFromTournament(String tournamentId, String teamId) async {
    final tournament = await getById(tournamentId);
    if (tournament == null) return null;

    final updatedTeams = tournament.teamIds.where((id) => id != teamId).toList();
    try {
      return await update(tournamentId, {'teams': updatedTeams});
    } on AppwriteException {
      return null;
    }
  }

  Future<List<TournamentTeamModel>> getTournamentTeams(String tournamentId) async {
    final result = await _tablesDB.listRows(
      databaseId: databaseId,
      tableId: Environment.tournamentTeamsCollectionId,
      queries: [
        Query.equal('tournamentId', [tournamentId]),
        Query.orderDesc('points'),
      ],
    );
    return result.rows.map((row) => TournamentTeamModel.fromJson(row.data)).toList();
  }

  // ===========================================================================
  // BRACKET GENERATION
  // ===========================================================================

  Future<BracketModel?> generateBracket(
    String tournamentId,
    List<String> teamIds,
    List<String> teamNames,
  ) async {
    final tournament = await getById(tournamentId);
    if (tournament == null) return null;

    BracketModel bracket;

    switch (tournament.type) {
      case 'knockout':
        bracket = _generateKnockoutBracket(tournamentId, teamIds, teamNames, tournament.maxTeams);
        break;
      case 'league':
        bracket = _generateLeagueBracket(tournamentId, teamIds, teamNames);
        break;
      case 'group_knockout':
        bracket = _generateGroupKnockoutBracket(tournamentId, teamIds, teamNames, tournament.maxTeams);
        break;
      default:
        bracket = _generateKnockoutBracket(tournamentId, teamIds, teamNames, tournament.maxTeams);
    }

    // Save bracket to database
    final savedBracket = await _saveBracket(bracket);

    // Update tournament status to active
    await updateTournamentStatus(tournamentId, 'active');

    return savedBracket;
  }

  BracketModel _generateKnockoutBracket(
    String tournamentId,
    List<String> teamIds,
    List<String> teamNames,
    int maxTeams,
  ) {
    // Shuffle teams for random seeding
    final shuffledIndices = List.generate(teamIds.length, (i) => i)..shuffle(Random());

    // Calculate number of rounds
    int rounds = 0;
    int teams = maxTeams;
    while (teams > 1) {
      teams ~/= 2;
      rounds++;
    }

    final bracketRounds = <BracketRound>[];
    int matchNumber = 0;

    // Generate first round matches
    final firstRoundMatches = <TournamentMatchModel>[];
    final byeMatches = maxTeams - teamIds.length;

    for (int i = 0; i < maxTeams ~/ 2; i++) {
      matchNumber++;
      final team1Index = i * 2 < shuffledIndices.length ? shuffledIndices[i * 2] : null;
      final team2Index = i * 2 + 1 < shuffledIndices.length ? shuffledIndices[i * 2 + 1] : null;

      // Handle byes
      if (i < byeMatches && team1Index != null) {
        firstRoundMatches.add(TournamentMatchModel(
          id: 'tm_${tournamentId}_r1_m$matchNumber',
          matchId: 'tm_${tournamentId}_r1_m$matchNumber',
          tournamentId: tournamentId,
          homeTeamId: teamIds[team1Index],
          homeTeamName: teamNames[team1Index],
          awayTeamId: null,
          awayTeamName: null,
          status: 'bye',
          roundNumber: 1,
          matchNumber: matchNumber,
          winnerId: teamIds[team1Index],
          winnerName: teamNames[team1Index],
        ));
      } else {
        firstRoundMatches.add(TournamentMatchModel(
          id: 'tm_${tournamentId}_r1_m$matchNumber',
          matchId: 'tm_${tournamentId}_r1_m$matchNumber',
          tournamentId: tournamentId,
          homeTeamId: team1Index != null ? teamIds[team1Index] : null,
          homeTeamName: team1Index != null ? teamNames[team1Index] : null,
          awayTeamId: team2Index != null ? teamIds[team2Index] : null,
          awayTeamName: team2Index != null ? teamNames[team2Index] : null,
          status: 'scheduled',
          roundNumber: 1,
          matchNumber: matchNumber,
        ));
      }
    }

    bracketRounds.add(BracketRound(
      roundNumber: 1,
      roundName: _getRoundName(1, rounds),
      matches: firstRoundMatches,
    ));

    // Generate subsequent rounds (empty placeholders)
    int matchesInRound = firstRoundMatches.length ~/ 2;
    for (int round = 2; round <= rounds; round++) {
      final roundMatches = <TournamentMatchModel>[];
      for (int m = 0; m < matchesInRound; m++) {
        matchNumber++;
        roundMatches.add(TournamentMatchModel(
          id: 'tm_${tournamentId}_r${round}_m$matchNumber',
          matchId: 'tm_${tournamentId}_r${round}_m$matchNumber',
          tournamentId: tournamentId,
          status: 'scheduled',
          roundNumber: round,
          matchNumber: matchNumber,
        ));
      }
      bracketRounds.add(BracketRound(
        roundNumber: round,
        roundName: _getRoundName(round, rounds),
        matches: roundMatches,
      ));
      matchesInRound ~/= 2;
    }

    return BracketModel(
      id: 'bracket_$tournamentId',
      tournamentId: tournamentId,
      rounds: bracketRounds,
      updatedAt: DateTime.now(),
    );
  }

  BracketModel _generateLeagueBracket(
    String tournamentId,
    List<String> teamIds,
    List<String> teamNames,
  ) {
    final n = teamIds.length;
    final rounds = n - 1;

    final bracketRounds = <BracketRound>[];
    int matchNumber = 0;

    // Round-robin scheduling using circle method
    final teams = List.generate(n, (i) => i);
    final hasBye = n.isOdd;
    if (hasBye) teams.add(-1);

    for (int round = 0; round < rounds; round++) {
      final roundMatches = <TournamentMatchModel>[];

      for (int match = 0; match < teams.length ~/ 2; match++) {
        matchNumber++;
        final team1 = teams[match];
        final team2 = teams[teams.length - 1 - match];

        if (team1 == -1 || team2 == -1) continue;

        roundMatches.add(TournamentMatchModel(
          id: 'tm_${tournamentId}_r${round + 1}_m$matchNumber',
          matchId: 'tm_${tournamentId}_r${round + 1}_m$matchNumber',
          tournamentId: tournamentId,
          homeTeamId: teamIds[team1],
          homeTeamName: teamNames[team1],
          awayTeamId: teamIds[team2],
          awayTeamName: teamNames[team2],
          status: 'scheduled',
          roundNumber: round + 1,
          matchNumber: matchNumber,
        ));
      }

      // Rotate teams (keep first team fixed)
      final last = teams.removeLast();
      teams.insert(1, last);

      if (roundMatches.isNotEmpty) {
        bracketRounds.add(BracketRound(
          roundNumber: round + 1,
          roundName: 'Round ${round + 1}',
          matches: roundMatches,
        ));
      }
    }

    return BracketModel(
      id: 'bracket_$tournamentId',
      tournamentId: tournamentId,
      rounds: bracketRounds,
      updatedAt: DateTime.now(),
    );
  }

  BracketModel _generateGroupKnockoutBracket(
    String tournamentId,
    List<String> teamIds,
    List<String> teamNames,
    int maxTeams,
  ) {
    // For simplicity, generate knockout bracket
    return _generateKnockoutBracket(tournamentId, teamIds, teamNames, maxTeams);
  }

  String _getRoundName(int roundNumber, int totalRounds) {
    final fromFinal = totalRounds - roundNumber + 1;
    switch (fromFinal) {
      case 1: return 'Final';
      case 2: return 'Semi-Final';
      case 3: return 'Quarter-Final';
      case 4: return 'Round of 16';
      case 5: return 'Round of 32';
      default: return 'Round $roundNumber';
    }
  }

  Future<BracketModel> _saveBracket(BracketModel bracket) async {
    final row = await _tablesDB.createRow(
      databaseId: databaseId,
      tableId: Environment.bracketsCollectionId,
      rowId: bracket.id,
      data: bracket.toJson(),
    );
    return BracketModel.fromJson(row.data);
  }

  // ===========================================================================
  // BRACKET OPERATIONS
  // ===========================================================================

  Future<BracketModel?> getBracket(String tournamentId) async {
    final brackets = await _tablesDB.listRows(
      databaseId: databaseId,
      tableId: Environment.bracketsCollectionId,
      queries: [
        Query.equal('tournamentId', [tournamentId]),
        Query.limit(1),
      ],
    );
    if (brackets.rows.isEmpty) return null;
    return BracketModel.fromJson(brackets.rows.first.data);
  }

  Future<BracketModel?> updateMatchResult({
    required String tournamentId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    final bracket = await getBracket(tournamentId);
    if (bracket == null) return null;

    TournamentMatchModel? completedMatch;
    bool isFinalMatch = false;
    var updatedRounds = <BracketRound>[];

    for (final round in bracket.rounds) {
      final updatedMatches = <TournamentMatchModel>[];
      for (final match in round.matches) {
        if (match.matchId == matchId) {
          String? winnerId;
          String? winnerName;
          if (homeScore > awayScore) {
            winnerId = match.homeTeamId;
            winnerName = match.homeTeamName;
          } else if (awayScore > homeScore) {
            winnerId = match.awayTeamId;
            winnerName = match.awayTeamName;
          }

          completedMatch = match.copyWith(
            homeScore: homeScore,
            awayScore: awayScore,
            status: 'completed',
            winnerId: winnerId,
            winnerName: winnerName,
          );
          updatedMatches.add(completedMatch);
          isFinalMatch = round.roundNumber == bracket.rounds.length;
        } else {
          updatedMatches.add(match);
        }
      }
      updatedRounds.add(round.copyWith(matches: updatedMatches));
    }

    // Advance winner to next round
    if (completedMatch != null && completedMatch.winnerId != null && !isFinalMatch) {
      updatedRounds = _advanceWinner(updatedRounds, completedMatch);
    }

    var updatedBracket = bracket.copyWith(
      rounds: updatedRounds,
      updatedAt: DateTime.now(),
    );

    if (isFinalMatch && completedMatch != null) {
      updatedBracket = updatedBracket.copyWith(
        winnerId: completedMatch.winnerId,
        winnerName: completedMatch.winnerName,
      );
      await updateTournamentStatus(tournamentId, 'completed');
    }

    await _tablesDB.updateRow(
      databaseId: databaseId,
      tableId: Environment.bracketsCollectionId,
      rowId: bracket.id,
      data: updatedBracket.toJson(),
    );

    if (completedMatch != null) {
      await _updateTeamStats(tournamentId, completedMatch);
    }

    return updatedBracket;
  }

  List<BracketRound> _advanceWinner(List<BracketRound> rounds, TournamentMatchModel completedMatch) {
    final nextRoundNumber = completedMatch.roundNumber + 1;
    if (nextRoundNumber > rounds.length) return rounds;

    final nextRoundIndex = nextRoundNumber - 1;
    final nextRound = rounds[nextRoundIndex];

    final matchIndexInRound = rounds[completedMatch.roundNumber - 1]
        .matches
        .indexWhere((m) => m.matchId == completedMatch.matchId);
    final nextMatchIndex = matchIndexInRound ~/ 2;

    final updatedMatches = List<TournamentMatchModel>.from(nextRound.matches);
    final nextMatch = updatedMatches[nextMatchIndex];

    final isHome = matchIndexInRound % 2 == 0;
    if (isHome) {
      updatedMatches[nextMatchIndex] = nextMatch.copyWith(
        homeTeamId: completedMatch.winnerId,
        homeTeamName: completedMatch.winnerName,
      );
    } else {
      updatedMatches[nextMatchIndex] = nextMatch.copyWith(
        awayTeamId: completedMatch.winnerId,
        awayTeamName: completedMatch.winnerName,
      );
    }

    final updatedRounds = List<BracketRound>.from(rounds);
    updatedRounds[nextRoundIndex] = nextRound.copyWith(matches: updatedMatches);
    return updatedRounds;
  }

  Future<void> _updateTeamStats(String tournamentId, TournamentMatchModel match) async {
    if (match.homeTeamId != null) {
      await _updateSingleTeamStats(
        tournamentId,
        match.homeTeamId!,
        match.homeTeamName!,
        match.homeScore ?? 0,
        match.awayScore ?? 0,
      );
    }
    if (match.awayTeamId != null) {
      await _updateSingleTeamStats(
        tournamentId,
        match.awayTeamId!,
        match.awayTeamName!,
        match.awayScore ?? 0,
        match.homeScore ?? 0,
      );
    }
  }

  Future<void> _updateSingleTeamStats(
    String tournamentId,
    String teamId,
    String teamName,
    int goalsScored,
    int goalsConceded,
  ) async {
    final teams = await _tablesDB.listRows(
      databaseId: databaseId,
      tableId: Environment.tournamentTeamsCollectionId,
      queries: [
        Query.equal('tournamentId', [tournamentId]),
        Query.equal('teamId', [teamId]),
        Query.limit(1),
      ],
    );

    TournamentTeamModel teamStats;
    if (teams.rows.isEmpty) {
      teamStats = TournamentTeamModel(
        id: 'tt_${tournamentId}_$teamId',
        tournamentId: tournamentId,
        teamId: teamId,
        teamName: teamName,
      );
    } else {
      teamStats = TournamentTeamModel.fromJson(teams.rows.first.data);
    }

    TournamentTeamModel updatedStats;
    if (goalsScored > goalsConceded) {
      updatedStats = teamStats.recordWin(goalsScored, goalsConceded);
    } else if (goalsScored < goalsConceded) {
      updatedStats = teamStats.recordLoss(goalsScored, goalsConceded);
    } else {
      updatedStats = teamStats.recordDraw(goalsScored, goalsConceded);
    }

    if (teams.rows.isEmpty) {
      await _tablesDB.createRow(
        databaseId: databaseId,
        tableId: Environment.tournamentTeamsCollectionId,
        rowId: updatedStats.id,
        data: updatedStats.toJson(),
      );
    } else {
      await _tablesDB.updateRow(
        databaseId: databaseId,
        tableId: Environment.tournamentTeamsCollectionId,
        rowId: teamStats.id,
        data: updatedStats.toJson(),
      );
    }
  }

  // ===========================================================================
  // MATCHES
  // ===========================================================================

  Future<List<TournamentMatchModel>> getTournamentMatches(String tournamentId) async {
    final bracket = await getBracket(tournamentId);
    if (bracket == null) return [];
    return bracket.rounds.expand((r) => r.matches).toList();
  }

  Future<TournamentMatchModel?> getMatch(String matchId) async {
    final brackets = await _tablesDB.listRows(
      databaseId: databaseId,
      tableId: Environment.bracketsCollectionId,
    );
    for (final row in brackets.rows) {
      final bracket = BracketModel.fromJson(row.data);
      for (final round in bracket.rounds) {
        for (final match in round.matches) {
          if (match.matchId == matchId) return match;
        }
      }
    }
    return null;
  }

  // ===========================================================================
  // STATS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getTopScorers(String tournamentId) async {
    // Would require a separate tournament_goals table
    return [];
  }

  Future<List<TournamentTeamModel>> getStandings(String tournamentId) async {
    return getTournamentTeams(tournamentId);
  }
}