import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/appwrite_service.dart';
import '../services/football_api_service.dart';
import '../providers/auth_provider.dart';
import '../models/pro_player_stat.dart';
import '../models/pro_match_performance.dart';
import '../environment.dart';

/// Repository for caching pro player stats in Appwrite.
/// Used by Pro Comparison feature and Learning Hub.
class ProStatsRepository {
  final AppwriteService _appwrite;
  final FootballApiService _footballApi;

  ProStatsRepository(this._appwrite, this._footballApi);

  /// Cache duration for pro stats (24 hours).
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Cache duration for weekend standouts (1 week).
  static const Duration _standoutCacheDuration = Duration(days: 7);

  /// Get top scorers for a competition (cached).
  Future<List<ProPlayerStat>> getTopScorers({
    required String competitionCode,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'pro_scorers_$competitionCode';

    // Check Appwrite cache first
    if (!forceRefresh) {
      final cached = await _getFromCache(cacheKey, _cacheDuration);
      if (cached != null) {
        return (cached as List).map((e) => ProPlayerStat.fromJson(e)).toList();
      }
    }

    // Fetch from API
    final players = await _footballApi.getTopScorers(
      competitionCode: competitionCode,
      limit: limit,
    );

    // Store in cache
    await _storeInCache(cacheKey, players.map((p) => p.toJson()).toList());

    return players;
  }

  /// Get pro player by position for comparison.
  Future<ProPlayerStat?> getTopPlayerByPosition({
    required String position,
    String competitionCode = 'PL',
  }) async {
    final positionGroup = _getPositionGroup(position);

    // Get all scorers and find top in position
    final scorers = await getTopScorers(competitionCode: competitionCode, limit: 50);

    // Filter by position group
    final filtered = scorers.where((p) => _getPositionGroup(p.position) == positionGroup);

    if (filtered.isEmpty) return null;

    // Sort by goals + assists and return top
    final sorted = filtered.toList()
      ..sort((a, b) => (b.goals + b.assists).compareTo(a.goals + a.assists));

    return sorted.first;
  }

  /// Get weekend standout performances (cached).
  Future<List<ProMatchPerformance>> getWeekendStandouts({
    required String competitionCode,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'standouts_$competitionCode';

    if (!forceRefresh) {
      final cached = await _getFromCache(cacheKey, _standoutCacheDuration);
      if (cached != null) {
        return (cached as List).map((e) => ProMatchPerformance.fromJson(e)).toList();
      }
    }

    final standouts = await _footballApi.getWeekendStandouts(
      competitionCode: competitionCode,
    );

    await _storeInCache(cacheKey, standouts.map((s) => s.toJson()).toList());

    return standouts;
  }

  /// Get player photo URL (from TheSportsDB).
  Future<String?> getPlayerPhotoUrl(String playerName) async {
    return _footballApi.getPlayerPhotoUrl(playerName);
  }

  /// Generate comparison verdict message.
  String generateVerdict({
    required String proName,
    required String position,
    required int userGoals,
    required int userAssists,
    required double userRating,
    required double proGoalsPerGame,
    required double proAssistsPerGame,
  }) {
    // Check if user outperformed pro
    final userConversionRate = userGoals > 0 ? 100.0 : 0.0; // Simplified
    final proConversionRate = 23.0; // Approximate average

    if (userGoals > proGoalsPerGame) {
      return "🔥 You scored more goals than $proName averages per game this season! ($userGoals vs ${proGoalsPerGame.toStringAsFixed(1)})";
    }

    if (userAssists > proAssistsPerGame) {
      return "🎯 You provided more assists than $proName averages per game! ($userAssists vs ${proAssistsPerGame.toStringAsFixed(1)})";
    }

    if (userRating > 8.0) {
      return "⭐ Outstanding performance! $proName would be proud of that ${userRating.toStringAsFixed(1)} rating.";
    }

    if (userGoals > 0 && userConversionRate > proConversionRate) {
      return "💪 You outperformed $proName in shot conversion today! Your efficiency was impressive.";
    }

    // Motivational message
    return "📈 $proName averages ${proGoalsPerGame.toStringAsFixed(1)} goals per game. Keep going — you're getting closer!";
  }

  String _getPositionGroup(String position) {
    if (position.contains('ST') || position.contains('CF') || position.contains('LW') || position.contains('RW')) {
      return 'attacker';
    }
    if (position.contains('CM') || position.contains('CDM') || position.contains('CAM') || position.contains('LM') || position.contains('RM')) {
      return 'midfielder';
    }
    if (position.contains('CB') || position.contains('LB') || position.contains('RB') || position.contains('WB')) {
      return 'defender';
    }
    if (position.contains('GK')) {
      return 'goalkeeper';
    }
    return 'midfielder';
  }

  /// Get from Appwrite cache.
  Future<dynamic> _getFromCache(String key, Duration maxAge) async {
    try {
      final doc = await _appwrite.tablesDB.getRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.leaderboardsCollectionId,
        rowId: 'cache_$key',
      );

      final data = doc.data;
      final updatedAt = DateTime.parse(data['updatedAt'] as String);
      if (DateTime.now().difference(updatedAt) > maxAge) {
        return null; // Cache is stale
      }

      return jsonDecode(data['rankings'] as String);
    } catch (e) {
      return null;
    }
  }

  /// Store in Appwrite cache.
  Future<void> _storeInCache(String key, dynamic data) async {
    try {
      await _appwrite.tablesDB.createRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.leaderboardsCollectionId,
        rowId: 'cache_$key',
        data: {
          'area': 'pro_stats_cache',
          'position': key,
          'rankings': jsonEncode(data),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Document might already exist, try update
      try {
        await _appwrite.tablesDB.updateRow(
          databaseId: Environment.appwriteDatabaseId,
          tableId: Environment.leaderboardsCollectionId,
          rowId: 'cache_$key',
          data: {
            'rankings': jsonEncode(data),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {
        // Ignore cache errors
      }
    }
  }
}

/// Provider for ProStatsRepository.
final proStatsRepositoryProvider = Provider<ProStatsRepository>((ref) {
  return ProStatsRepository(
    ref.watch(appwriteServiceProvider),
    ref.watch(footballApiServiceProvider),
  );
});