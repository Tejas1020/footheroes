import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_roster_model.dart';
import '../features/match/data/models/live_match_models.dart';
import '../repositories/match_roster_repository.dart';
import 'auth_provider.dart';

final matchRosterRepositoryProvider = Provider<MatchRosterRepository>((ref) {
  return MatchRosterRepository(ref.watch(appwriteServiceProvider));
});

/// State for a match's roster.
class MatchRosterState {
  final List<MatchRosterEntry> entries;
  final bool isLoading;
  final String? error;

  const MatchRosterState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  MatchRosterState copyWith({
    List<MatchRosterEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return MatchRosterState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MatchRosterNotifier extends StateNotifier<MatchRosterState> {
  final MatchRosterRepository _repo;

  MatchRosterNotifier(this._repo) : super(const MatchRosterState());

  /// Load the roster for a match from Appwrite.
  Future<void> loadRoster(String matchId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _repo.getRosterForMatch(matchId);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a player to the roster (optimistic update + persist to Appwrite).
  Future<bool> addPlayer(String matchId, LivePlayerInfo player,
      {String? team}) async {
    // Optimistic: show player immediately
    final tempEntry = MatchRosterEntry(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      matchId: matchId,
      playerId: player.id,
      playerName: player.name,
      playerEmail: player.email,
      position: player.position,
      isRegistered: player.isRegistered,
      team: team,
    );
    state = state.copyWith(entries: [...state.entries, tempEntry]);

    try {
      final entry = MatchRosterEntry(
        id: ID.unique(),
        matchId: matchId,
        playerId: player.id,
        playerName: player.name,
        playerEmail: player.email,
        position: player.position,
        isRegistered: player.isRegistered,
        team: team,
      );
      final saved = await _repo.addPlayerToRoster(entry);
      // Replace temp entry with saved entry (has real ID from Appwrite)
      state = state.copyWith(
        entries: state.entries.map((e) => e.id == tempEntry.id ? saved : e).toList(),
      );
      return true;
    } catch (e) {
      // Remove optimistic entry on failure
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != tempEntry.id).toList(),
        error: e.toString(),
      );
      return false;
    }
  }

  /// Add multiple players at once (persists to Appwrite).
  Future<void> addPlayers(String matchId, List<LivePlayerInfo> players,
      {String? team}) async {
    final entries = players
        .map((p) => MatchRosterEntry(
              id: ID.unique(),
              matchId: matchId,
              playerId: p.id,
              playerName: p.name,
              playerEmail: p.email,
              position: p.position,
              isRegistered: p.isRegistered,
              team: team ?? p.team,
            ))
        .toList();
    try {
      final saved = await _repo.addPlayersToRoster(entries);
      state = state.copyWith(entries: [...state.entries, ...saved]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove a player from the roster.
  Future<bool> removePlayer(String entryId) async {
    try {
      await _repo.removePlayerFromRoster(entryId);
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != entryId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Save roster from a match creation flow (batch save).
  Future<void> saveRosterForMatch(
      String matchId, List<LivePlayerInfo> players) async {
    await addPlayers(matchId, players);
  }

  void clear() {
    state = const MatchRosterState();
  }
}

final matchRosterProvider =
    StateNotifierProvider<MatchRosterNotifier, MatchRosterState>((ref) {
  return MatchRosterNotifier(ref.watch(matchRosterRepositoryProvider));
});