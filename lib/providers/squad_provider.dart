import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/session_plan_model.dart';
import '../repositories/team_repository.dart' show TeamRepository, TeamMember;
import '../repositories/match_repository.dart';
import '../repositories/session_plan_repository.dart';
import 'auth_provider.dart';
import 'team_provider.dart' show teamRepositoryProvider;
import 'match_provider.dart' show matchRepositoryProvider;

final sessionPlanRepositoryProvider = Provider<SessionPlanRepository>((ref) {
  return SessionPlanRepository(ref.watch(appwriteServiceProvider));
});

// Squad status
enum SquadStatus { initial, loading, loaded, error }

// Squad state - extends team management with training sessions
class SquadState {
  final SquadStatus status;
  final TeamModel? team;
  final List<TeamMember> roster;
  final List<MatchModel> upcomingMatches;
  final List<MatchModel> pastMatches;
  final List<SessionPlanModel> upcomingSessions;
  final MatchModel? nextMatch;
  final Map<String, String> rsvpStatus; // playerId -> 'yes'/'no'/'maybe'
  final Map<String, bool> payments; // playerId -> paid
  final String? error;

  const SquadState({
    this.status = SquadStatus.initial,
    this.team,
    this.roster = const [],
    this.upcomingMatches = const [],
    this.pastMatches = const [],
    this.upcomingSessions = const [],
    this.nextMatch,
    this.rsvpStatus = const {},
    this.payments = const {},
    this.error,
  });

  SquadState copyWith({
    SquadStatus? status,
    TeamModel? team,
    List<TeamMember>? roster,
    List<MatchModel>? upcomingMatches,
    List<MatchModel>? pastMatches,
    List<SessionPlanModel>? upcomingSessions,
    MatchModel? nextMatch,
    Map<String, String>? rsvpStatus,
    Map<String, bool>? payments,
    String? error,
  }) {
    return SquadState(
      status: status ?? this.status,
      team: team ?? this.team,
      roster: roster ?? this.roster,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      pastMatches: pastMatches ?? this.pastMatches,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      nextMatch: nextMatch ?? this.nextMatch,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      payments: payments ?? this.payments,
      error: error,
    );
  }

  int get rosterCount => roster.length;
  int get confirmedCount => rsvpStatus.values.where((v) => v == 'yes').length;
  int get paidCount => payments.values.where((v) => v).length;
}

// Squad notifier
class SquadNotifier extends StateNotifier<SquadState> {
  final TeamRepository _teamRepo;
  final MatchRepository _matchRepo;
  final SessionPlanRepository _sessionRepo;

  SquadNotifier(this._teamRepo, this._matchRepo, this._sessionRepo)
      : super(const SquadState());

  Future<void> loadSquad(String teamId) async {
    state = state.copyWith(status: SquadStatus.loading);
    try {
      // Load team
      final team = await _teamRepo.getById(teamId);
      if (team == null) {
        state = state.copyWith(status: SquadStatus.error, error: 'Team not found');
        return;
      }

      // Load roster
      final roster = await _teamRepo.getTeamMembers(teamId);

      // Load matches
      final upcomingMatches = await _matchRepo.getUpcomingMatches(teamId);
      final pastMatches = await _matchRepo.getPastMatches(teamId);
      final nextMatch = upcomingMatches.isNotEmpty ? upcomingMatches.first : null;

      // Load sessions
      final upcomingSessions = await _sessionRepo.getUpcomingSessions(teamId);

      // Load RSVP and payment status
      final rsvpStatus = await _matchRepo.getRsvpStatus(teamId);
      final payments = await _teamRepo.getPaymentStatus(teamId);

      state = state.copyWith(
        status: SquadStatus.loaded,
        team: team,
        roster: roster,
        upcomingMatches: upcomingMatches,
        pastMatches: pastMatches,
        upcomingSessions: upcomingSessions,
        nextMatch: nextMatch,
        rsvpStatus: rsvpStatus,
        payments: payments,
      );
    } catch (e) {
      state = state.copyWith(status: SquadStatus.error, error: e.toString());
    }
  }

  Future<bool> updateRsvp(String matchId, String playerId, String status) async {
    try {
      await _matchRepo.updateRsvp(matchId, playerId, status);
      final newRsvpStatus = Map<String, String>.from(state.rsvpStatus);
      newRsvpStatus[playerId] = status;
      state = state.copyWith(rsvpStatus: newRsvpStatus);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> markPaid(String playerId, bool paid) async {
    final team = state.team;
    if (team == null) return false;

    try {
      await _teamRepo.updatePaymentStatus(team.teamId, playerId, paid);
      final newPayments = Map<String, bool>.from(state.payments);
      newPayments[playerId] = paid;
      state = state.copyWith(payments: newPayments);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removePlayer(String playerId) async {
    final team = state.team;
    if (team == null) return false;

    try {
      await _teamRepo.removeMember(team.teamId, playerId);
      await loadSquad(team.teamId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePlayerPosition(String playerId, String position) async {
    try {
      await _teamRepo.updateMemberPosition(playerId, position);
      final team = state.team;
      if (team != null) {
        await loadSquad(team.teamId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createSession(SessionPlanModel session) async {
    try {
      await _sessionRepo.saveSessionPlan(session);
      final team = state.team;
      if (team != null) {
        await loadSquad(team.teamId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateAttendance(String sessionId, List<String> attendeeIds) async {
    try {
      await _sessionRepo.updateAttendance(sessionId, attendeeIds);
      final team = state.team;
      if (team != null) {
        await loadSquad(team.teamId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Squad provider
final squadProvider = StateNotifierProvider<SquadNotifier, SquadState>((ref) {
  return SquadNotifier(
    ref.watch(teamRepositoryProvider),
    ref.watch(matchRepositoryProvider),
    ref.watch(sessionPlanRepositoryProvider),
  );
});

// Derived providers
final rosterProvider = Provider<List<TeamMember>>((ref) {
  return ref.watch(squadProvider).roster;
});

final nextMatchProvider = Provider<MatchModel?>((ref) {
  return ref.watch(squadProvider).nextMatch;
});

final upcomingSessionsProvider = Provider<List<SessionPlanModel>>((ref) {
  return ref.watch(squadProvider).upcomingSessions;
});