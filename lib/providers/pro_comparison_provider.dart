import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pro_player_stat.dart';
import '../repositories/pro_stats_repository.dart';

/// User's match stats for comparison with pro.
class UserMatchStats {
  final int goals;
  final int assists;
  final double rating;
  final String position;
  final int minutesPlayed;

  const UserMatchStats({
    required this.goals,
    required this.assists,
    required this.rating,
    required this.position,
    this.minutesPlayed = 90,
  });

  /// Shot conversion rate (simplified - assumes shots = goals + misses).
  double get shotConversionRate => goals > 0 ? 100.0 : 0.0;

  /// Goals per game.
  double get goalsPerGame => goals.toDouble();

  /// Assists per game.
  double get assistsPerGame => assists.toDouble();
}

/// State for Pro Comparison feature.
class ProComparisonState {
  final ProPlayerStat? proPlayer;
  final UserMatchStats? userStats;
  final String? verdictMessage;
  final bool isLoading;
  final String? error;

  const ProComparisonState({
    this.proPlayer,
    this.userStats,
    this.verdictMessage,
    this.isLoading = false,
    this.error,
  });

  ProComparisonState copyWith({
    ProPlayerStat? proPlayer,
    UserMatchStats? userStats,
    String? verdictMessage,
    bool? isLoading,
    String? error,
  }) {
    return ProComparisonState(
      proPlayer: proPlayer ?? this.proPlayer,
      userStats: userStats ?? this.userStats,
      verdictMessage: verdictMessage ?? this.verdictMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for Pro Comparison state.
class ProComparisonNotifier extends StateNotifier<ProComparisonState> {
  final ProStatsRepository _proStatsRepo;

  ProComparisonNotifier(this._proStatsRepo) : super(const ProComparisonState());

  /// Load comparison for user's match stats.
  Future<void> loadComparison({
    required UserMatchStats userStats,
    String competitionCode = 'PL',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get top pro player in user's position
      final proPlayer = await _proStatsRepo.getTopPlayerByPosition(
        position: userStats.position,
        competitionCode: competitionCode,
      );

      if (proPlayer == null) {
        state = state.copyWith(
          userStats: userStats,
          proPlayer: null,
          verdictMessage: 'No pro player found for your position.',
          isLoading: false,
        );
        return;
      }

      // Generate verdict
      final verdict = _proStatsRepo.generateVerdict(
        proName: proPlayer.name,
        position: userStats.position,
        userGoals: userStats.goals,
        userAssists: userStats.assists,
        userRating: userStats.rating,
        proGoalsPerGame: proPlayer.goalsPerGame,
        proAssistsPerGame: proPlayer.assistsPerGame,
      );

      state = state.copyWith(
        proPlayer: proPlayer,
        userStats: userStats,
        verdictMessage: verdict,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load comparison for current user from their last match.
  Future<void> loadFromLastMatch({
    required int goals,
    required int assists,
    required double rating,
    required String position,
  }) async {
    final userStats = UserMatchStats(
      goals: goals,
      assists: assists,
      rating: rating,
      position: position,
    );
    await loadComparison(userStats: userStats);
  }

  /// Clear comparison state.
  void clear() {
    state = const ProComparisonState();
  }
}

/// Provider for Pro Comparison state.
final proComparisonProvider = StateNotifierProvider<ProComparisonNotifier, ProComparisonState>((ref) {
  return ProComparisonNotifier(ref.watch(proStatsRepositoryProvider));
});

/// Provider for fetching pro player photo.
final proPlayerPhotoProvider = FutureProvider.family<String?, String>((ref, playerName) async {
  final repo = ref.watch(proStatsRepositoryProvider);
  return repo.getPlayerPhotoUrl(playerName);
});