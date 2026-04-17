import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../repositories/team_repository.dart';
import '../repositories/match_repository.dart';
import 'team_provider.dart';
import 'match_provider.dart';

/// State for Find Match feature.
class FindMatchState {
  final List<TeamModel> availableTeams;
  final List<MatchModel> incomingChallenges;
  final List<MatchModel> sentChallenges;
  final bool isLoading;
  final bool isSendingChallenge;
  final String? error;

  const FindMatchState({
    this.availableTeams = const [],
    this.incomingChallenges = const [],
    this.sentChallenges = const [],
    this.isLoading = false,
    this.isSendingChallenge = false,
    this.error,
  });

  FindMatchState copyWith({
    List<TeamModel>? availableTeams,
    List<MatchModel>? incomingChallenges,
    List<MatchModel>? sentChallenges,
    bool? isLoading,
    bool? isSendingChallenge,
    String? error,
  }) {
    return FindMatchState(
      availableTeams: availableTeams ?? this.availableTeams,
      incomingChallenges: incomingChallenges ?? this.incomingChallenges,
      sentChallenges: sentChallenges ?? this.sentChallenges,
      isLoading: isLoading ?? this.isLoading,
      isSendingChallenge: isSendingChallenge ?? this.isSendingChallenge,
      error: error,
    );
  }
}

/// Search filters for finding teams.
class TeamSearchFilters {
  final String? format;
  final String? skillLevel;
  final String? dayPreference;
  final double? radiusKm;
  final double? userLat;
  final double? userLng;

  const TeamSearchFilters({
    this.format,
    this.skillLevel,
    this.dayPreference,
    this.radiusKm,
    this.userLat,
    this.userLng,
  });

  TeamSearchFilters copyWith({
    String? format,
    String? skillLevel,
    String? dayPreference,
    double? radiusKm,
    double? userLat,
    double? userLng,
  }) {
    return TeamSearchFilters(
      format: format ?? this.format,
      skillLevel: skillLevel ?? this.skillLevel,
      dayPreference: dayPreference ?? this.dayPreference,
      radiusKm: radiusKm ?? this.radiusKm,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

/// Notifier for Find Match state.
class FindMatchNotifier extends StateNotifier<FindMatchState> {
  final TeamRepository _teamRepo;
  final MatchRepository _matchRepo;

  FindMatchNotifier(this._teamRepo, this._matchRepo) : super(const FindMatchState());

  /// Search for available teams with filters.
  Future<void> searchTeams(TeamSearchFilters filters) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Build query based on filters
      final teams = await _teamRepo.getAll();

      // Apply filters
      var filteredTeams = teams.where((team) {
        // Filter by format
        if (filters.format != null && team.format != filters.format) {
          return false;
        }
        // Check if team is looking for matches
        // This would need to be added to TeamModel
        return true;
      }).toList();

      // Apply distance filter if location is available
      if (filters.userLat != null && filters.userLng != null && filters.radiusKm != null) {
        // Calculate distance and filter
        // For now, just use all teams
        filteredTeams = filteredTeams;
      }

      state = state.copyWith(
        availableTeams: filteredTeams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Send a challenge to another team.
  Future<bool> sendChallenge({
    required String fromTeamId,
    required String toTeamId,
    required DateTime proposedDate,
    required String format,
    String? venue,
  }) async {
    state = state.copyWith(isSendingChallenge: true, error: null);

    try {
      // Create challenge match
      final match = MatchModel(
        id: '',
        matchId: DateTime.now().millisecondsSinceEpoch.toString(),
        homeTeamId: fromTeamId,
        awayTeamId: toTeamId,
        format: format,
        status: 'challenge_sent',
        homeScore: 0,
        awayScore: 0,
        matchDate: proposedDate,
        createdBy: '', // Would be current user ID
      );

      await _matchRepo.create(match.matchId, match.toJson());

      // Add to sent challenges
      state = state.copyWith(
        sentChallenges: [...state.sentChallenges, match],
        isSendingChallenge: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSendingChallenge: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load incoming and sent challenges for a team.
  Future<void> loadChallenges(String teamId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load challenges where team is home or away
      final allMatches = await _matchRepo.getAll();

      final incoming = allMatches.where((m) =>
        m.status == 'challenge_sent' &&
        m.awayTeamId == teamId &&
        m.homeTeamId != teamId
      ).toList();

      final sent = allMatches.where((m) =>
        m.status == 'challenge_sent' &&
        m.homeTeamId == teamId
      ).toList();

      state = state.copyWith(
        incomingChallenges: incoming,
        sentChallenges: sent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Accept or decline a challenge.
  Future<bool> respondToChallenge(String matchId, bool accepted) async {
    try {
      await _matchRepo.updateStatus(
        matchId,
        accepted ? 'challenge_accepted' : 'challenge_declined',
      );

      // Remove from incoming challenges
      state = state.copyWith(
        incomingChallenges: state.incomingChallenges
            .where((m) => m.matchId != matchId)
            .toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear state.
  void clear() {
    state = const FindMatchState();
  }
}

/// Provider for Find Match state.
final findMatchProvider = StateNotifierProvider<FindMatchNotifier, FindMatchState>((ref) {
  return FindMatchNotifier(
    ref.watch(teamRepositoryProvider),
    ref.watch(matchRepositoryProvider),
  );
});

/// Current search filters.
final searchFiltersProvider = StateProvider<TeamSearchFilters>((ref) {
  return const TeamSearchFilters();
});