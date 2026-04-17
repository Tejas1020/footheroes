import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';
import 'auth_provider.dart';

// Repository provider
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(ref.watch(appwriteServiceProvider));
});

// Tournament state enum
enum TournamentStatus {
  initial,
  loading,
  loaded,
  creating,
  error,
}

/// Tournament state - holds all tournament-related data
class TournamentState {
  final TournamentStatus status;
  final List<TournamentModel> myTournaments;
  final List<TournamentModel> publicTournaments;
  final TournamentModel? selectedTournament;
  final BracketModel? bracket;
  final List<TournamentMatchModel> matches;
  final List<TournamentTeamModel> standings;
  final String? error;

  const TournamentState({
    this.status = TournamentStatus.initial,
    this.myTournaments = const [],
    this.publicTournaments = const [],
    this.selectedTournament,
    this.bracket,
    this.matches = const [],
    this.standings = const [],
    this.error,
  });

  TournamentState copyWith({
    TournamentStatus? status,
    List<TournamentModel>? myTournaments,
    List<TournamentModel>? publicTournaments,
    TournamentModel? selectedTournament,
    BracketModel? bracket,
    List<TournamentMatchModel>? matches,
    List<TournamentTeamModel>? standings,
    String? error,
  }) {
    return TournamentState(
      status: status ?? this.status,
      myTournaments: myTournaments ?? this.myTournaments,
      publicTournaments: publicTournaments ?? this.publicTournaments,
      selectedTournament: selectedTournament ?? this.selectedTournament,
      bracket: bracket ?? this.bracket,
      matches: matches ?? this.matches,
      standings: standings ?? this.standings,
      error: error,
    );
  }

  // Convenience getters
  bool get isLoading => status == TournamentStatus.loading;
  bool get isCreating => status == TournamentStatus.creating;
  bool get hasError => status == TournamentStatus.error;
  bool get hasTournaments => myTournaments.isNotEmpty || publicTournaments.isNotEmpty;
  bool get hasBracket => bracket != null;
  bool get hasSelectedTournament => selectedTournament != null;
}

/// Tournament notifier - manages all tournament operations
class TournamentNotifier extends StateNotifier<TournamentState> {
  final TournamentRepository _repository;

  TournamentNotifier(this._repository) : super(const TournamentState());

  /// Load user's tournaments and public tournaments
  Future<void> loadTournaments(String userId) async {
    state = state.copyWith(status: TournamentStatus.loading);
    try {
      final myTournaments = await _repository.getUserTournaments(userId);
      final publicTournaments = await _repository.getPublicTournaments();

      state = state.copyWith(
        status: TournamentStatus.loaded,
        myTournaments: myTournaments,
        publicTournaments: publicTournaments,
      );
    } catch (e) {
      state = state.copyWith(
        status: TournamentStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Load a specific tournament with bracket and standings
  Future<void> loadTournamentDetails(String tournamentId) async {
    state = state.copyWith(status: TournamentStatus.loading);
    try {
      final tournament = await _repository.getTournament(tournamentId);
      if (tournament == null) {
        state = state.copyWith(
          status: TournamentStatus.error,
          error: 'Tournament not found',
        );
        return;
      }

      // Load bracket and standings in parallel
      final results = await Future.wait([
        _repository.getBracket(tournamentId),
        _repository.getStandings(tournamentId),
      ]);

      final bracket = results[0] as BracketModel?;
      final standings = results[1] as List<TournamentTeamModel>;

      final matches = bracket?.rounds.expand((r) => r.matches).toList() ?? [];

      state = state.copyWith(
        status: TournamentStatus.loaded,
        selectedTournament: tournament,
        bracket: bracket,
        matches: matches,
        standings: standings,
      );
    } catch (e) {
      state = state.copyWith(
        status: TournamentStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Create a new tournament
  Future<TournamentModel?> createTournament(TournamentModel tournament) async {
    state = state.copyWith(status: TournamentStatus.creating);
    try {
      final created = await _repository.createTournament(tournament);
      state = state.copyWith(
        status: TournamentStatus.loaded,
        myTournaments: [...state.myTournaments, created],
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        status: TournamentStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update tournament details
  Future<void> updateTournament(TournamentModel tournament) async {
    try {
      final updated = await _repository.updateTournament(tournament);
      final updatedList = state.myTournaments.map((t) {
        return t.tournamentId == tournament.tournamentId ? updated : t;
      }).toList();

      state = state.copyWith(
        myTournaments: updatedList,
        selectedTournament: state.selectedTournament?.tournamentId == tournament.tournamentId
            ? updated
            : state.selectedTournament,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update tournament fields (name, venue, description) by ID
  Future<void> updateTournamentFields({
    required String tournamentId,
    String? name,
    String? venue,
    String? description,
  }) async {
    final current = state.myTournaments
            .where((t) => t.tournamentId == tournamentId)
            .firstOrNull ??
        state.selectedTournament;

    if (current == null) return;

    final updated = current.copyWith(
      name: name ?? current.name,
      venue: venue ?? current.venue,
      description: description ?? current.description,
    );

    await updateTournament(updated);
  }

  /// Open tournament for registration
  Future<void> openRegistration(String tournamentId) async {
    try {
      await _repository.updateTournamentStatus(tournamentId, 'registration');
      await loadTournamentDetails(tournamentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Register a team for a tournament
  Future<bool> registerTeam(String tournamentId, String teamId) async {
    try {
      final updated = await _repository.addTeamToTournament(tournamentId, teamId);
      if (updated != null) {
        await loadTournamentDetails(tournamentId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Withdraw a team from a tournament
  Future<void> withdrawTeam(String tournamentId, String teamId) async {
    try {
      await _repository.removeTeamFromTournament(tournamentId, teamId);
      await loadTournamentDetails(tournamentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Generate bracket and start tournament
  Future<BracketModel?> startTournament(
    String tournamentId,
    List<String> teamIds,
    List<String> teamNames,
  ) async {
    state = state.copyWith(status: TournamentStatus.loading);
    try {
      final bracket = await _repository.generateBracket(
        tournamentId,
        teamIds,
        teamNames,
      );
      if (bracket != null) {
        await loadTournamentDetails(tournamentId);
      }
      return bracket;
    } catch (e) {
      state = state.copyWith(
        status: TournamentStatus.error,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update match result
  Future<void> updateMatchResult({
    required String tournamentId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      final updatedBracket = await _repository.updateMatchResult(
        tournamentId: tournamentId,
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
      );

      if (updatedBracket != null) {
        final matches = updatedBracket.rounds.expand((r) => r.matches).toList();
        final standings = await _repository.getStandings(tournamentId);

        state = state.copyWith(
          bracket: updatedBracket,
          matches: matches,
          standings: standings,
        );

        // Check if tournament completed
        if (updatedBracket.hasWinner) {
          final tournament = await _repository.getTournament(tournamentId);
          if (tournament != null) {
            final updatedList = state.myTournaments.map((t) {
              return t.tournamentId == tournamentId ? tournament : t;
            }).toList();
            state = state.copyWith(
              myTournaments: updatedList,
              selectedTournament: tournament,
            );
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get matches for a specific round
  List<TournamentMatchModel> getRoundMatches(int roundNumber) {
    if (state.bracket == null) return [];
    final round = state.bracket!.rounds
        .where((r) => r.roundNumber == roundNumber)
        .firstOrNull;
    return round?.matches ?? [];
  }

  /// Clear selected tournament
  void clearSelectedTournament() {
    state = state.copyWith(
      selectedTournament: null,
      bracket: null,
      matches: const [],
      standings: const [],
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Main tournament provider
final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, TournamentState>((ref) {
  return TournamentNotifier(ref.watch(tournamentRepositoryProvider));
});

// ===========================================================================
// Derived providers for convenience
// ===========================================================================

/// Provider for user's tournaments only
final myTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentProvider).myTournaments;
});

/// Provider for public tournaments
final publicTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentProvider).publicTournaments;
});

/// Provider for selected tournament
final selectedTournamentProvider = Provider<TournamentModel?>((ref) {
  return ref.watch(tournamentProvider).selectedTournament;
});

/// Provider for bracket
final bracketProvider = Provider<BracketModel?>((ref) {
  return ref.watch(tournamentProvider).bracket;
});

/// Provider for standings
final standingsProvider = Provider<List<TournamentTeamModel>>((ref) {
  return ref.watch(tournamentProvider).standings;
});

/// Provider for tournament matches
final tournamentMatchesProvider = Provider<List<TournamentMatchModel>>((ref) {
  return ref.watch(tournamentProvider).matches;
});

/// Provider for tournament winner (if any)
final tournamentWinnerProvider = Provider<String?>((ref) {
  return ref.watch(tournamentProvider).bracket?.winnerName;
});

/// Provider to check if user can start a tournament
final canStartTournamentProvider = Provider<bool>((ref) {
  final tournament = ref.watch(tournamentProvider).selectedTournament;
  if (tournament == null) return false;
  return tournament.canStart;
});

/// Provider for active tournaments (status == 'active')
final activeTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final state = ref.watch(tournamentProvider);
  return [
    ...state.myTournaments,
    ...state.publicTournaments,
  ].where((t) => t.isActive).toList();
});

/// Provider for registration tournaments
final registrationTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final state = ref.watch(tournamentProvider);
  return [
    ...state.myTournaments,
    ...state.publicTournaments,
  ].where((t) => t.isRegistration).toList();
});

/// Provider for completed tournaments
final completedTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final state = ref.watch(tournamentProvider);
  return [
    ...state.myTournaments,
    ...state.publicTournaments,
  ].where((t) => t.isCompleted).toList();
});