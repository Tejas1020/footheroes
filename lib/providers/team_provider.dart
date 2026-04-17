import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../repositories/team_repository.dart';
import '../repositories/match_repository.dart';
import 'auth_provider.dart';
import 'match_provider.dart';

// Repository providers
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(ref.watch(appwriteServiceProvider));
});

// Team state
enum TeamStatus { initial, loading, loaded, error }

class TeamState {
  final TeamStatus status;
  final List<TeamModel> teams;
  final TeamModel? currentTeam;
  final MatchModel? nextMatch;
  final String? error;

  const TeamState({
    this.status = TeamStatus.initial,
    this.teams = const [],
    this.currentTeam,
    this.nextMatch,
    this.error,
  });

  TeamState copyWith({
    TeamStatus? status,
    List<TeamModel>? teams,
    TeamModel? currentTeam,
    MatchModel? nextMatch,
    String? error,
  }) {
    return TeamState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      currentTeam: currentTeam ?? this.currentTeam,
      nextMatch: nextMatch ?? this.nextMatch,
      error: error,
    );
  }
}

// Team notifier
class TeamNotifier extends StateNotifier<TeamState> {
  final TeamRepository _teamRepo;
  final MatchRepository _matchRepo;

  TeamNotifier(this._teamRepo, this._matchRepo) : super(const TeamState());

  Future<void> loadUserTeams(String userId) async {
    state = state.copyWith(status: TeamStatus.loading);
    try {
      final teams = await _teamRepo.getTeamsForUser(userId);
      state = state.copyWith(
        status: TeamStatus.loaded,
        teams: teams,
        currentTeam: teams.isNotEmpty ? teams.first : null,
      );
      if (teams.isNotEmpty) {
        await loadNextMatch(teams.first.teamId);
      }
    } catch (e) {
      state = state.copyWith(status: TeamStatus.error, error: e.toString());
    }
  }

  Future<void> loadNextMatch(String teamId) async {
    try {
      final match = await _matchRepo.getNextMatch(teamId);
      state = state.copyWith(nextMatch: match);
    } catch (_) {
      // Silently fail for next match
    }
  }

  Future<void> createTeam(TeamModel team) async {
    try {
      await _teamRepo.createTeam(team);
      await loadUserTeams(team.captainUid);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> joinTeam(String inviteCode, String userId) async {
    try {
      final team = await _teamRepo.getTeamByInviteCode(inviteCode);
      if (team != null) {
        await _teamRepo.addMember(team.teamId, userId);
        await loadUserTeams(userId);
      } else {
        state = state.copyWith(error: 'Invalid invite code');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Team provider
final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  return TeamNotifier(
    ref.watch(teamRepositoryProvider),
    ref.watch(matchRepositoryProvider),
  );
});