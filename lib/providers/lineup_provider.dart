import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lineup_model.dart';
import '../models/formation_model.dart';
import '../repositories/lineup_repository.dart';
import 'auth_provider.dart';

final lineupRepositoryProvider = Provider<LineupRepository>((ref) {
  return LineupRepository(ref.watch(appwriteServiceProvider));
});

// Lineup state
enum LineupStatus { initial, loading, loaded, error }

class LineupState {
  final LineupStatus status;
  final LineupModel? currentLineup;
  final List<LineupModel> teamLineups;
  final String? error;

  const LineupState({
    this.status = LineupStatus.initial,
    this.currentLineup,
    this.teamLineups = const [],
    this.error,
  });

  LineupState copyWith({
    LineupStatus? status,
    LineupModel? currentLineup,
    List<LineupModel>? teamLineups,
    String? error,
  }) {
    return LineupState(
      status: status ?? this.status,
      currentLineup: currentLineup ?? this.currentLineup,
      teamLineups: teamLineups ?? this.teamLineups,
      error: error,
    );
  }

  int get assignedCount => currentLineup?.assignedCount ?? 0;
  bool get isComplete => currentLineup?.isComplete ?? false;
  int get substituteCount => currentLineup?.substituteIds.length ?? 0;
}

// Lineup notifier
class LineupNotifier extends StateNotifier<LineupState> {
  final LineupRepository _lineupRepo;

  LineupNotifier(this._lineupRepo) : super(const LineupState());

  Future<void> loadLineup(String matchId, String teamId) async {
    state = state.copyWith(status: LineupStatus.loading);
    try {
      final lineup = await _lineupRepo.getLineup(matchId, teamId);
      state = state.copyWith(
        status: LineupStatus.loaded,
        currentLineup: lineup,
      );
    } catch (e) {
      state = state.copyWith(status: LineupStatus.error, error: e.toString());
    }
  }

  Future<void> loadTeamLineups(String teamId) async {
    state = state.copyWith(status: LineupStatus.loading);
    try {
      final lineups = await _lineupRepo.getTeamLineups(teamId);
      state = state.copyWith(
        status: LineupStatus.loaded,
        teamLineups: lineups,
      );
    } catch (e) {
      state = state.copyWith(status: LineupStatus.error, error: e.toString());
    }
  }

  Future<bool> createFromFormation({
    required String matchId,
    required String teamId,
    required FormationModel formation,
  }) async {
    try {
      final lineup = await _lineupRepo.createFromFormation(
        matchId: matchId,
        teamId: teamId,
        formation: formation,
      );
      if (lineup != null) {
        state = state.copyWith(
          status: LineupStatus.loaded,
          currentLineup: lineup,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> assignPlayerToSlot(
    String slotId,
    String playerId,
    String playerName,
  ) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.assignPlayerToSlot(
        lineup.id,
        slotId,
        playerId,
        playerName,
      );
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removePlayerFromSlot(String slotId) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.removePlayerFromSlot(lineup.id, slotId);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> setCaptain(String playerId) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.setCaptain(lineup.id, playerId);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> setViceCaptain(String playerId) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.setViceCaptain(lineup.id, playerId);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addSubstitute(String playerId) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.addSubstitute(lineup.id, playerId);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeSubstitute(String playerId) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.removeSubstitute(lineup.id, playerId);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> changeFormation(String formationType) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.changeFormation(lineup.id, formationType);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTeamTalk(String notes) async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.updateTeamTalk(lineup.id, notes);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> saveLineup() async {
    final lineup = state.currentLineup;
    if (lineup == null) return false;

    try {
      final updated = await _lineupRepo.updateLineup(lineup);
      if (updated != null) {
        state = state.copyWith(currentLineup: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearLineup() {
    state = const LineupState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Lineup provider
final lineupProvider = StateNotifierProvider<LineupNotifier, LineupState>((ref) {
  return LineupNotifier(ref.watch(lineupRepositoryProvider));
});

// Derived providers
final currentLineupProvider = Provider<LineupModel?>((ref) {
  return ref.watch(lineupProvider).currentLineup;
});

final lineupAssignedCountProvider = Provider<int>((ref) {
  return ref.watch(lineupProvider).assignedCount;
});

final lineupIsCompleteProvider = Provider<bool>((ref) {
  return ref.watch(lineupProvider).isComplete;
});