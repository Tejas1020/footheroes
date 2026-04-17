import 'package:appwrite/appwrite.dart';
import '../models/challenge_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class ChallengeRepository extends BaseRepository<ChallengeModel> {
  ChallengeRepository(AppwriteService service) : super(service, 'challenges');

  @override
  ChallengeModel fromJson(Map<String, dynamic> json) => ChallengeModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(ChallengeModel item) => item.toJson();

  /// Get the current active challenge (not expired).
  Future<ChallengeModel?> getCurrentChallenge() async {
    final challenges = await getAll(queries: [
      Query.greaterThan('expiresAt', DateTime.now().toIso8601String()),
      Query.orderDesc('weekNumber'),
      Query.limit(1),
    ]);
    return challenges.isNotEmpty ? challenges.first : null;
  }

  /// Get challenges for a specific position.
  Future<List<ChallengeModel>> getChallengesByPosition(String position) async {
    return getAll(queries: [
      Query.equal('position', [position]),
    ]);
  }

  /// Get challenges by week number.
  Future<ChallengeModel?> getChallengeByWeek(int weekNumber) async {
    final challenges = await getAll(queries: [
      Query.equal('weekNumber', [weekNumber]),
      Query.limit(1),
    ]);
    return challenges.isNotEmpty ? challenges.first : null;
  }

  /// Mark a challenge as completed by a user.
  Future<ChallengeModel?> markCompleted(String challengeId, String userId) async {
    final challenge = await getById(challengeId);
    if (challenge == null) return null;
    final updated = [...?challenge.completedBy, userId];
    return update(challengeId, {'completedBy': updated});
  }

  /// Get current active challenges for a position.
  Future<List<ChallengeModel>> getCurrentChallenges(String position) async {
    final now = DateTime.now().toIso8601String();
    return getAll(queries: [
      Query.equal('position', [position]),
      Query.greaterThan('expiresAt', now),
      Query.orderDesc('weekNumber'),
      Query.limit(1),
    ]);
  }

  /// Mark a challenge as complete by a user.
  Future<bool> markChallengeComplete(String challengeId, String userId) async {
    final result = await markCompleted(challengeId, userId);
    return result != null;
  }

  /// Create a new challenge.
  Future<ChallengeModel?> createChallenge(ChallengeModel challenge) async {
    return create(challenge.challengeId, challenge.toJson());
  }
}