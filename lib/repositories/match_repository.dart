import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class MatchRepository extends BaseRepository<MatchModel> {
  MatchRepository(AppwriteService service) : super(service, 'matches');

  @override
  MatchModel fromJson(Map<String, dynamic> json) => MatchModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(MatchModel item) => item.toJson();

  /// Get upcoming matches for a team.
  Future<List<MatchModel>> getUpcomingMatches(String teamId) async {
    return getAll(queries: [
      Query.equal('homeTeamId', [teamId]),
      Query.equal('status', ['upcoming']),
      Query.orderAsc('matchDate'),
    ]);
  }

  /// Get the next upcoming match for a team.
  Future<MatchModel?> getNextMatch(String teamId) async {
    final matches = await getAll(queries: [
      Query.equal('homeTeamId', [teamId]),
      Query.equal('status', ['upcoming']),
      Query.orderAsc('matchDate'),
      Query.limit(1),
    ]);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Get completed matches for a team.
  Future<List<MatchModel>> getCompletedMatches(String teamId) async {
    return getAll(queries: [
      Query.equal('homeTeamId', [teamId]),
      Query.equal('status', ['completed']),
      Query.orderDesc('matchDate'),
    ]);
  }

  /// Get past matches for a team.
  Future<List<MatchModel>> getPastMatches(String teamId) async {
    final now = DateTime.now().toIso8601String();
    return getAll(queries: [
      Query.equal('homeTeamId', [teamId]),
      Query.lessThan('matchDate', now),
      Query.orderDesc('matchDate'),
    ]);
  }

  /// Get RSVP status for a match.
  Future<Map<String, String>> getRsvpStatus(String teamId) async {
    // This would query a match_rsvps table
    // For now, return empty map
    return {};
  }

  /// Update RSVP status for a player.
  Future<bool> updateRsvp(String matchId, String playerId, String status) async {
    // This would update a match_rsvps table
    return true;
  }

  /// Get live matches.
  Future<List<MatchModel>> getLiveMatches() async {
    return getAll(queries: [
      Query.equal('status', ['live']),
    ]);
  }

  /// Get matches created by a user.
  Future<List<MatchModel>> getMatchesCreatedBy(String userId) async {
    return getAll(queries: [
      Query.equal('createdBy', [userId]),
    ]);
  }

  /// Create a new match with proper permissions.
  Future<MatchModel> createMatch(MatchModel match, {String? scorerId}) async {
    final permissions = <String>[
      Permission.read(Role.any()),
    ];
    if (scorerId != null) {
      permissions.add(Permission.update(Role.user(scorerId)));
    }

    final data = <String, dynamic>{
      'matchId': match.matchId,
      'homeTeamId': match.homeTeamId,
      'format': match.format,
      'status': match.status,
      'homeScore': match.homeScore,
      'awayScore': match.awayScore,
      'matchDate': match.matchDate.toIso8601String(),
      'createdBy': match.createdBy,
    };
    // Only include optional fields when they have values
    if (match.awayTeamId != null && match.awayTeamId!.isNotEmpty) data['awayTeamId'] = match.awayTeamId!;
    if (match.homeTeamName.isNotEmpty) data['homeTeamName'] = match.homeTeamName;
    if (match.awayTeamName != null && match.awayTeamName!.isNotEmpty) data['awayTeamName'] = match.awayTeamName!;
    if (match.venue != null && match.venue!.isNotEmpty) data['venue'] = match.venue;

    debugPrint('[matches] createMatch — homeTeamId: "${match.homeTeamId}", createdBy: "${match.createdBy}"');
    debugPrint('[matches] data payload: $data');

    try {
      return create(match.matchId, data, permissions: permissions);
    } on AppwriteException catch (e) {
      debugPrint('[matches] create failed: ${e.message} (${e.code})');
      rethrow;
    }
  }

  /// Delete a match. Only the creator should call this.
  Future<bool> deleteMatch(String matchId) async {
    return delete(matchId);
  }

  /// Update match status.
  /// Throws [AppwriteException] on failure.
  Future<MatchModel> updateStatus(String matchId, String status) async {
    return update(matchId, {'status': status});
  }

  /// Update match score.
  /// Throws [AppwriteException] on failure.
  Future<MatchModel> updateScore(String matchId, int homeScore, int awayScore) async {
    return update(matchId, {
      'homeScore': homeScore,
      'awayScore': awayScore,
    });
  }

  /// Get recent matches (limit).
  Future<List<MatchModel>> getRecentMatches(int limit) async {
    return getAll(queries: [
      Query.equal('status', ['completed']),
      Query.orderDesc('matchDate'),
      Query.limit(limit),
    ]);
  }

  /// Submit a MOTM vote. Stores {votingPlayerId: votedForPlayerId} in the match document.
  Future<void> submitMotmVote(String matchId, String votedForPlayerId, String votingPlayerId) async {
    final match = await getById(matchId);
    if (match == null) return;
    final stats = Map<String, dynamic>.from(match.stats ?? {});
    final motmVotes = Map<String, dynamic>.from(stats['motmVotes'] as Map? ?? {});
    motmVotes[votingPlayerId] = votedForPlayerId;
    stats['motmVotes'] = motmVotes;
    await update(matchId, {'stats': stats});
  }

  /// Close MOTM voting — tally votes, find winner, store on match document.
  Future<String?> closeMotmVoting(String matchId) async {
    final match = await getById(matchId);
    if (match == null) return null;
    final stats = Map<String, dynamic>.from(match.stats ?? {});
    final motmVotes = Map<String, dynamic>.from(stats['motmVotes'] as Map? ?? {});
    final tally = <String, int>{};
    for (final v in motmVotes.values) {
      final key = v.toString();
      tally[key] = (tally[key] ?? 0) + 1;
    }
    String? winner;
    if (tally.isNotEmpty) {
      winner = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
    await update(matchId, {
      'motmWinnerId': winner,
      'motmVotingClosed': true,
    });
    return winner;
  }
}

/// Repository for match events.
class MatchEventRepository extends BaseRepository<MatchEventModel> {
  MatchEventRepository(AppwriteService service)
      : super(service, 'matchEvents');

  @override
  MatchEventModel fromJson(Map<String, dynamic> json) => MatchEventModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(MatchEventModel item) => item.toJson();

  /// Get all events for a match.
  Future<List<MatchEventModel>> getEventsForMatch(String matchId) async {
    return getAll(queries: [
      Query.equal('matchId', [matchId]),
      Query.orderAsc('minute'),
    ]);
  }

  /// Get all events for a player.
  Future<List<MatchEventModel>> getEventsForPlayer(String playerId) async {
    return getAll(queries: [
      Query.equal('playerId', [playerId]),
    ]);
  }

  /// Create a match event.
  Future<MatchEventModel?> createEvent(MatchEventModel event) async {
    return create(event.eventId, event.toJson());
  }

  /// Get goals for a player.
  Future<List<MatchEventModel>> getGoalsForPlayer(String playerId) async {
    return getAll(queries: [
      Query.equal('playerId', [playerId]),
      Query.equal('type', ['goal']),
    ]);
  }

  /// Get assists for a player.
  Future<List<MatchEventModel>> getAssistsForPlayer(String playerId) async {
    return getAll(queries: [
      Query.equal('playerId', [playerId]),
      Query.equal('type', ['assist']),
    ]);
  }
}