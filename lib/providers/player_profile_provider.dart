import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career_stats.dart';
import '../models/match_model.dart';
import '../models/player_badge.dart';
import '../repositories/player_profile_repository.dart';
import '../providers/auth_provider.dart';

/// State for Player Profile feature.
class PlayerProfileState {
  final CareerStats? careerStats;
  final List<MatchModel> recentMatches;
  final List<PlayerBadge> badges;
  final List<double> last5Ratings;
  final int winStreak;
  final bool isLoading;
  final String? error;

  const PlayerProfileState({
    this.careerStats,
    this.recentMatches = const [],
    this.badges = const [],
    this.last5Ratings = const [],
    this.winStreak = 0,
    this.isLoading = false,
    this.error,
  });

  PlayerProfileState copyWith({
    CareerStats? careerStats,
    List<MatchModel>? recentMatches,
    List<PlayerBadge>? badges,
    List<double>? last5Ratings,
    int? winStreak,
    bool? isLoading,
    String? error,
  }) {
    return PlayerProfileState(
      careerStats: careerStats ?? this.careerStats,
      recentMatches: recentMatches ?? this.recentMatches,
      badges: badges ?? this.badges,
      last5Ratings: last5Ratings ?? this.last5Ratings,
      winStreak: winStreak ?? this.winStreak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for Player Profile state.
class PlayerProfileNotifier extends StateNotifier<PlayerProfileState> {
  final PlayerProfileRepository _repo;

  PlayerProfileNotifier(this._repo) : super(const PlayerProfileState());

  /// Load profile for a user.
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final futures = await Future.wait([
        _repo.getCareerStats(userId),
        _repo.getRecentMatches(userId, limit: 10),
        _repo.getEarnedBadges(userId),
        _repo.getLast5Ratings(userId),
        _repo.getWinStreak(userId),
      ]);

      final stats = futures[0] as CareerStats;
      final matches = futures[1] as List<MatchModel>;
      // final badges = futures[2] as List<PlayerBadge>; // Unused - will recalculate with streak
      final ratings = futures[3] as List<double>;
      final streak = futures[4] as int;

      // Calculate badges with win streak
      final updatedBadges = BadgeDefinitions.calculateEarnedBadges(stats, winStreak: streak);

      state = state.copyWith(
        careerStats: stats,
        recentMatches: matches,
        badges: updatedBadges,
        last5Ratings: ratings,
        winStreak: streak,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh stats for current user.
  Future<void> refreshStats(String userId) async {
    try {
      final stats = await _repo.getCareerStats(userId);
      final streak = await _repo.getWinStreak(userId);
      final badges = BadgeDefinitions.calculateEarnedBadges(stats, winStreak: streak);

      state = state.copyWith(
        careerStats: stats,
        badges: badges,
        winStreak: streak,
      );
    } catch (e) {
      // Keep existing state on error
    }
  }

  /// Update user's position.
  Future<void> updatePosition({
    required String userId,
    required String primaryPosition,
    String? secondaryPosition,
  }) async {
    try {
      await _repo.updateProfile(
        userId: userId,
        primaryPosition: primaryPosition,
        secondaryPosition: secondaryPosition,
      );

      // Refresh profile
      await loadProfile(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear profile state.
  void clear() {
    state = const PlayerProfileState();
  }
}

/// Provider for Player Profile state.
final playerProfileProvider = StateNotifierProvider<PlayerProfileNotifier, PlayerProfileState>((ref) {
  return PlayerProfileNotifier(ref.watch(playerProfileRepositoryProvider));
});

/// Provider for current user's profile (convenience).
final currentUserProfileProvider = FutureProvider<PlayerProfileState>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final notifier = ref.watch(playerProfileProvider.notifier);
  await notifier.loadProfile(userId);
  return ref.watch(playerProfileProvider);
});

/// Provider for specific user's profile.
final userProfileProvider = FutureProvider.family<PlayerProfileState, String>((ref, userId) async {
  final notifier = ref.watch(playerProfileProvider.notifier);
  await notifier.loadProfile(userId);
  return ref.watch(playerProfileProvider);
});