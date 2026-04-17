import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge_model.dart';
import '../repositories/challenge_repository.dart';
import 'auth_provider.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(ref.watch(appwriteServiceProvider));
});

// Challenge state
enum ChallengeStatus { initial, loading, loaded, error }

class ChallengeState {
  final ChallengeStatus status;
  final ChallengeModel? currentChallenge;
  final List<ChallengeModel> challenges;
  final String? error;

  const ChallengeState({
    this.status = ChallengeStatus.initial,
    this.currentChallenge,
    this.challenges = const [],
    this.error,
  });

  ChallengeState copyWith({
    ChallengeStatus? status,
    ChallengeModel? currentChallenge,
    List<ChallengeModel>? challenges,
    String? error,
  }) {
    return ChallengeState(
      status: status ?? this.status,
      currentChallenge: currentChallenge ?? this.currentChallenge,
      challenges: challenges ?? this.challenges,
      error: error,
    );
  }
}

// Challenge notifier
class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final ChallengeRepository _challengeRepo;

  ChallengeNotifier(this._challengeRepo) : super(const ChallengeState());

  Future<void> loadCurrentChallenge() async {
    state = state.copyWith(status: ChallengeStatus.loading);
    try {
      final challenge = await _challengeRepo.getCurrentChallenge();
      state = state.copyWith(
        status: ChallengeStatus.loaded,
        currentChallenge: challenge,
      );
    } catch (e) {
      state = state.copyWith(status: ChallengeStatus.error, error: e.toString());
    }
  }

  Future<void> loadChallengesByPosition(String position) async {
    try {
      final challenges = await _challengeRepo.getChallengesByPosition(position);
      state = state.copyWith(challenges: challenges);
    } catch (_) {}
  }

  Future<void> markCompleted(String challengeId, String userId) async {
    try {
      await _challengeRepo.markCompleted(challengeId, userId);
      await loadCurrentChallenge();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Challenge provider
final challengeProvider = StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
  return ChallengeNotifier(ref.watch(challengeRepositoryProvider));
});