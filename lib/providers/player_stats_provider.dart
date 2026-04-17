import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career_stats.dart';
import '../repositories/player_profile_repository.dart';
import '../providers/auth_provider.dart';

/// Provider for player stats
final playerStatsProvider = FutureProvider.family<CareerStats, String>((ref, userId) async {
  final repo = ref.watch(playerProfileRepositoryProvider);
  return repo.getCareerStats(userId);
});

/// Provider for the current user's stats
final currentUserStatsProvider = FutureProvider<CareerStats?>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;
  if (userId == null) return null;

  final repo = ref.watch(playerProfileRepositoryProvider);
  return repo.getCareerStats(userId);
});
