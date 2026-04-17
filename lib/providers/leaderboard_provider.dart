import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';
import '../repositories/leaderboard_repository.dart';
import 'auth_provider.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.watch(appwriteServiceProvider));
});

// Leaderboard state
enum LeaderboardStatus { initial, loading, loaded, error }

class LeaderboardState {
  final LeaderboardStatus status;
  final LeaderboardModel? leaderboard;
  final List<RankingEntry> rankings;
  final String activeTab; // 'area', 'position', 'team'
  final String activeTimeframe; // 'monthly', 'weekly', 'alltime'
  final String activeArea;
  final String activePosition;
  final String? error;

  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.leaderboard,
    this.rankings = const [],
    this.activeTab = 'area',
    this.activeTimeframe = 'monthly',
    this.activeArea = 'London',
    this.activePosition = 'ST',
    this.error,
  });

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardModel? leaderboard,
    List<RankingEntry>? rankings,
    String? activeTab,
    String? activeTimeframe,
    String? activeArea,
    String? activePosition,
    String? error,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      leaderboard: leaderboard ?? this.leaderboard,
      rankings: rankings ?? this.rankings,
      activeTab: activeTab ?? this.activeTab,
      activeTimeframe: activeTimeframe ?? this.activeTimeframe,
      activeArea: activeArea ?? this.activeArea,
      activePosition: activePosition ?? this.activePosition,
      error: error,
    );
  }
}

// Leaderboard notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _leaderboardRepo;

  LeaderboardNotifier(this._leaderboardRepo) : super(const LeaderboardState());

  Future<void> loadLeaderboard() async {
    state = state.copyWith(status: LeaderboardStatus.loading);
    try {
      final leaderboard = await _leaderboardRepo.getLeaderboard(
        area: state.activeArea,
        position: state.activePosition,
        timeframe: state.activeTimeframe,
      );
      state = state.copyWith(
        status: LeaderboardStatus.loaded,
        leaderboard: leaderboard,
        rankings: leaderboard?.rankings ?? [],
      );
    } catch (e) {
      state = state.copyWith(status: LeaderboardStatus.error, error: e.toString());
    }
  }

  void setTab(String tab) {
    state = state.copyWith(activeTab: tab);
    loadLeaderboard();
  }

  void setTimeframe(String timeframe) {
    state = state.copyWith(activeTimeframe: timeframe);
    loadLeaderboard();
  }

  void setArea(String area) {
    state = state.copyWith(activeArea: area);
    loadLeaderboard();
  }

  void setPosition(String position) {
    state = state.copyWith(activePosition: position);
    loadLeaderboard();
  }
}

// Leaderboard provider
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.watch(leaderboardRepositoryProvider));
});