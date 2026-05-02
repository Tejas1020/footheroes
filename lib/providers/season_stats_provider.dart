import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career_stats.dart';
import '../repositories/player_profile_repository.dart';
import '../core/utils/season_util.dart';

/// Provides computed CareerStats for a given user + season.
final seasonStatsProvider =
    FutureProvider.family<CareerStats, ({String userId, String season})>(
  (ref, params) async {
    final repo = ref.watch(playerProfileRepositoryProvider);
    final (start, end) = SeasonUtil.seasonDateRange(params.season);
    return repo.getCareerStats(params.userId, seasonStart: start, seasonEnd: end);
  },
);

/// Provides all available season labels for the current user's match history.
final availableSeasonsProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final repo = ref.watch(playerProfileRepositoryProvider);
    final matches = await repo.getRecentMatches(userId, limit: 200);
    final dates = matches.map((m) => m.matchDate).toList();
    return SeasonUtil.availableSeasons(dates);
  },
);
