import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drill_model.dart';
import '../models/challenge_model.dart';
import '../repositories/drill_repository.dart';
import '../repositories/challenge_repository.dart';
import 'drill_provider.dart';
import 'challenge_provider.dart';

// Learning hub status
enum LearningHubStatus { initial, loading, loaded, error }

// Learning hub state - position-specific content feed
class LearningHubState {
  final LearningHubStatus status;
  final String selectedPosition;
  final List<DrillModel> positionDrills;
  final List<DrillModel> recommendedDrills;
  final ChallengeModel? currentChallenge;
  final List<DrillModel> completedDrills;
  final List<String> savedDrillIds;
  final int weeklyDrillTarget;
  final int drillsCompletedThisWeek;
  final String? error;

  const LearningHubState({
    this.status = LearningHubStatus.initial,
    this.selectedPosition = '',
    this.positionDrills = const [],
    this.recommendedDrills = const [],
    this.currentChallenge,
    this.completedDrills = const [],
    this.savedDrillIds = const [],
    this.weeklyDrillTarget = 3,
    this.drillsCompletedThisWeek = 0,
    this.error,
  });

  LearningHubState copyWith({
    LearningHubStatus? status,
    String? selectedPosition,
    List<DrillModel>? positionDrills,
    List<DrillModel>? recommendedDrills,
    ChallengeModel? currentChallenge,
    List<DrillModel>? completedDrills,
    List<String>? savedDrillIds,
    int? weeklyDrillTarget,
    int? drillsCompletedThisWeek,
    String? error,
  }) {
    return LearningHubState(
      status: status ?? this.status,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      positionDrills: positionDrills ?? this.positionDrills,
      recommendedDrills: recommendedDrills ?? this.recommendedDrills,
      currentChallenge: currentChallenge ?? this.currentChallenge,
      completedDrills: completedDrills ?? this.completedDrills,
      savedDrillIds: savedDrillIds ?? this.savedDrillIds,
      weeklyDrillTarget: weeklyDrillTarget ?? this.weeklyDrillTarget,
      drillsCompletedThisWeek: drillsCompletedThisWeek ?? this.drillsCompletedThisWeek,
      error: error,
    );
  }

  double get weeklyProgress =>
      weeklyDrillTarget > 0 ? drillsCompletedThisWeek / weeklyDrillTarget : 0.0;

  bool get hasChallenge => currentChallenge != null;
  int get savedCount => savedDrillIds.length;
}

// Learning hub notifier
class LearningHubNotifier extends StateNotifier<LearningHubState> {
  final DrillRepository _drillRepo;
  final ChallengeRepository _challengeRepo;

  LearningHubNotifier(this._drillRepo, this._challengeRepo)
      : super(const LearningHubState());

  Future<void> loadContent(String position, String userId) async {
    state = state.copyWith(status: LearningHubStatus.loading);
    try {
      // Load drills for position
      final positionDrills = await _drillRepo.getDrillsByPosition(position);

      // Load current challenge
      final challenges = await _challengeRepo.getCurrentChallenges(position);
      final currentChallenge = challenges.isNotEmpty ? challenges.first : null;

      // Load completed drills this week
      final completedDrills = await _drillRepo.getCompletedDrillsThisWeek(userId);
      final drillsCompletedThisWeek = completedDrills.length;

      // Load saved drills
      final savedDrillIds = await _drillRepo.getSavedDrillIds(userId);

      // Get recommended drills based on position and skill level
      final recommendedDrills = await _drillRepo.getRecommendedDrills(position, userId);

      state = state.copyWith(
        status: LearningHubStatus.loaded,
        selectedPosition: position,
        positionDrills: positionDrills,
        currentChallenge: currentChallenge,
        completedDrills: completedDrills,
        savedDrillIds: savedDrillIds,
        drillsCompletedThisWeek: drillsCompletedThisWeek,
        recommendedDrills: recommendedDrills,
      );
    } catch (e) {
      state = state.copyWith(status: LearningHubStatus.error, error: e.toString());
    }
  }

  Future<void> changePosition(String position, String userId) async {
    await loadContent(position, userId);
  }

  Future<bool> markDrillComplete(String drillId, String userId) async {
    try {
      await _drillRepo.markDrillComplete(drillId, userId);
      state = state.copyWith(
        drillsCompletedThisWeek: state.drillsCompletedThisWeek + 1,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> saveDrill(String drillId, String userId) async {
    try {
      await _drillRepo.saveDrill(drillId, userId);
      final newSavedIds = [...state.savedDrillIds, drillId];
      state = state.copyWith(savedDrillIds: newSavedIds);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> unsaveDrill(String drillId, String userId) async {
    try {
      await _drillRepo.unsaveDrill(drillId, userId);
      final newSavedIds = state.savedDrillIds.where((id) => id != drillId).toList();
      state = state.copyWith(savedDrillIds: newSavedIds);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> completeChallenge(String challengeId, String userId) async {
    try {
      await _challengeRepo.markChallengeComplete(challengeId, userId);
      state = state.copyWith(currentChallenge: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  bool isDrillSaved(String drillId) {
    return state.savedDrillIds.contains(drillId);
  }

  bool isDrillCompleted(String drillId) {
    return state.completedDrills.any((d) => d.drillId == drillId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Learning hub provider
final learningHubProvider =
    StateNotifierProvider<LearningHubNotifier, LearningHubState>((ref) {
  return LearningHubNotifier(
    ref.watch(drillRepositoryProvider),
    ref.watch(challengeRepositoryProvider),
  );
});

// Derived providers
final positionDrillsProvider = Provider<List<DrillModel>>((ref) {
  return ref.watch(learningHubProvider).positionDrills;
});

final currentChallengeProvider = Provider<ChallengeModel?>((ref) {
  return ref.watch(learningHubProvider).currentChallenge;
});

final weeklyProgressProvider = Provider<double>((ref) {
  return ref.watch(learningHubProvider).weeklyProgress;
});

final recommendedDrillsProvider = Provider<List<DrillModel>>((ref) {
  return ref.watch(learningHubProvider).recommendedDrills;
});