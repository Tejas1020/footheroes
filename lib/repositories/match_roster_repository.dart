import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../models/match_roster_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class MatchRosterRepository extends BaseRepository<MatchRosterEntry> {
  MatchRosterRepository(AppwriteService service)
      : super(service, 'matchRoster');

  @override
  MatchRosterEntry fromJson(Map<String, dynamic> json) =>
      MatchRosterEntry.fromJson(json);

  @override
  Map<String, dynamic> toJson(MatchRosterEntry item) => item.toJson();

  /// Get all roster entries for a match.
  Future<List<MatchRosterEntry>> getRosterForMatch(String matchId) async {
    return getAll(queries: [
      Query.equal('matchId', [matchId]),
    ]);
  }

  /// Add a player to a match roster.
  Future<MatchRosterEntry> addPlayerToRoster(MatchRosterEntry entry) async {
    return create(entry.id, entry.toJson());
  }

  /// Remove a player from a match roster.
  Future<bool> removePlayerFromRoster(String entryId) async {
    return delete(entryId);
  }

  /// Add multiple players to a match roster at once.
  Future<List<MatchRosterEntry>> addPlayersToRoster(
      List<MatchRosterEntry> entries) async {
    final results = <MatchRosterEntry>[];
    for (final entry in entries) {
      try {
        final result = await addPlayerToRoster(entry);
        results.add(result);
      } catch (e) {
        debugPrint('[matchRoster] Failed to add player: $e');
      }
    }
    return results;
  }
}