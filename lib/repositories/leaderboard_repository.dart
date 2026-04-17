import 'package:appwrite/appwrite.dart';
import '../models/leaderboard_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class LeaderboardRepository extends BaseRepository<LeaderboardModel> {
  LeaderboardRepository(AppwriteService service)
      : super(service, 'leaderboards');

  @override
  LeaderboardModel fromJson(Map<String, dynamic> json) => LeaderboardModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(LeaderboardModel item) => item.toJson();

  /// Get leaderboard by area, position, and timeframe.
  Future<LeaderboardModel?> getLeaderboard({
    required String area,
    required String position,
    required String timeframe,
  }) async {
    final results = await getAll(queries: [
      Query.equal('area', [area]),
      Query.equal('position', [position]),
      Query.equal('timeframe', [timeframe]),
      Query.limit(1),
    ]);
    return results.isNotEmpty ? results.first : null;
  }

  /// Get leaderboards by timeframe.
  Future<List<LeaderboardModel>> getByTimeframe(String timeframe) async {
    return getAll(queries: [
      Query.equal('timeframe', [timeframe]),
    ]);
  }

  /// Get leaderboards by area.
  Future<List<LeaderboardModel>> getByArea(String area) async {
    return getAll(queries: [
      Query.equal('area', [area]),
    ]);
  }

  /// Create or update a leaderboard.
  Future<LeaderboardModel?> saveLeaderboard(LeaderboardModel leaderboard) async {
    final existing = await getLeaderboard(
      area: leaderboard.area,
      position: leaderboard.position,
      timeframe: leaderboard.timeframe,
    );
    if (existing != null) {
      return update(existing.id, leaderboard.toJson());
    }
    return create(leaderboard.id.isEmpty ? 'unique()' : leaderboard.id, leaderboard.toJson());
  }
}