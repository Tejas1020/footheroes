import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../repositories/match_repository.dart';
import 'auth_provider.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(appwriteServiceProvider));
});

final matchEventRepositoryProvider = Provider<MatchEventRepository>((ref) {
  return MatchEventRepository(ref.watch(appwriteServiceProvider));
});

// Match state
enum MatchStatus { initial, loading, loaded, error }

class MatchState {
  final MatchStatus status;
  final List<MatchModel> matches;
  final MatchModel? currentMatch;
  final List<MatchEventModel> currentMatchEvents;
  final List<MatchModel> upcomingMatches;
  final List<MatchModel> recentMatches;
  final String? error;

  const MatchState({
    this.status = MatchStatus.initial,
    this.matches = const [],
    this.currentMatch,
    this.currentMatchEvents = const [],
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.error,
  });

  MatchState copyWith({
    MatchStatus? status,
    List<MatchModel>? matches,
    MatchModel? currentMatch,
    List<MatchEventModel>? currentMatchEvents,
    List<MatchModel>? upcomingMatches,
    List<MatchModel>? recentMatches,
    String? error,
  }) {
    return MatchState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      currentMatch: currentMatch ?? this.currentMatch,
      currentMatchEvents: currentMatchEvents ?? this.currentMatchEvents,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      recentMatches: recentMatches ?? this.recentMatches,
      error: error,
    );
  }
}

// Match notifier
class MatchNotifier extends StateNotifier<MatchState> {
  final MatchRepository _matchRepo;
  final MatchEventRepository _eventRepo;

  MatchNotifier(this._matchRepo, this._eventRepo) : super(const MatchState());

  Future<void> loadUpcomingMatches(String teamId) async {
    try {
      final matches = await _matchRepo.getUpcomingMatches(teamId);
      state = state.copyWith(upcomingMatches: matches);
    } catch (_) {}
  }

  Future<void> loadRecentMatches({int limit = 5}) async {
    try {
      final matches = await _matchRepo.getRecentMatches(limit);
      state = state.copyWith(recentMatches: matches);
    } catch (_) {}
  }

  /// Load matches where the given user is a participant (created or on roster).
  /// Includes live, upcoming, and challenge_accepted matches.
  Future<void> loadMyActiveMatches(String userId) async {
    try {
      final allMatches = await _matchRepo.getAll();
      final active = allMatches.where((m) {
        final isActive = m.status == 'live' ||
            m.status == 'upcoming' ||
            m.status == 'challenge_accepted' ||
            m.status == 'challenge_sent';
        final isParticipant = m.homeTeamId == userId ||
            m.awayTeamId == userId ||
            m.createdBy == userId;
        return isActive && isParticipant;
      }).toList();
      state = state.copyWith(upcomingMatches: [
        ...active,
        ...state.upcomingMatches.where((m) => !active.any((a) => a.matchId == m.matchId)),
      ]);
    } catch (_) {}
  }

  Future<void> loadMatchWithEvents(String matchId) async {
    state = state.copyWith(status: MatchStatus.loading);
    try {
      final match = await _matchRepo.getById(matchId);
      final events = await _eventRepo.getEventsForMatch(matchId);
      state = state.copyWith(
        status: MatchStatus.loaded,
        currentMatch: match,
        currentMatchEvents: events,
      );
    } catch (e) {
      state = state.copyWith(status: MatchStatus.error, error: e.toString());
    }
  }

  Future<void> createMatch(MatchModel match) async {
    try {
      await _matchRepo.createMatch(match);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _matchRepo.updateStatus(matchId, status);
      final currentMatch = state.currentMatch;
      if (currentMatch != null && currentMatch.matchId == matchId) {
        state = state.copyWith(
          currentMatch: currentMatch.copyWith(status: status),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateMatchScore(String matchId, int homeScore, int awayScore) async {
    try {
      await _matchRepo.updateScore(matchId, homeScore, awayScore);
      final currentMatch = state.currentMatch;
      if (currentMatch != null && currentMatch.matchId == matchId) {
        state = state.copyWith(
          currentMatch: currentMatch.copyWith(
            homeScore: homeScore,
            awayScore: awayScore,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logEvent(MatchEventModel event) async {
    try {
      await _eventRepo.createEvent(event);
      state = state.copyWith(
        currentMatchEvents: [...state.currentMatchEvents, event],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Match provider
final matchProvider = StateNotifierProvider<MatchNotifier, MatchState>((ref) {
  return MatchNotifier(
    ref.watch(matchRepositoryProvider),
    ref.watch(matchEventRepositoryProvider),
  );
});