import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/appwrite_service.dart';
import '../providers/auth_provider.dart';
import '../models/career_stats.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../models/player_badge.dart';
import '../environment.dart';

/// Repository for player profile data.
/// Calculates career stats from match events and manages badges.
class PlayerProfileRepository {
  final AppwriteService _appwrite;

  PlayerProfileRepository(this._appwrite);

  /// Get career stats for a player.
  Future<CareerStats> getCareerStats(String userId) async {
    try {
      // Fetch matches where user is homeTeamId, awayTeamId, or createdBy
      final homeMatchesResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('homeTeamId', [userId])],
      );
      final awayMatchesResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('awayTeamId', [userId])],
      );
      final createdMatchesResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('createdBy', [userId])],
      );

      // Deduplicate by matchId
      final matchMap = <String, MatchModel>{};
      for (final row in [...homeMatchesResponse.rows, ...awayMatchesResponse.rows, ...createdMatchesResponse.rows]) {
        final m = MatchModel.fromJson(row.data);
        matchMap[m.matchId] = m;
      }
      final matches = matchMap.values.toList();

      // Get all events for this player
      final eventsResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchEventsCollectionId,
        queries: [Query.equal('playerId', [userId])],
      );

      final events = eventsResponse.rows
          .map((row) => MatchEventModel.fromJson(row.data))
          .toList();

      // Group events by matchId for per-match calculations
      final eventsByMatch = <String, List<MatchEventModel>>{};
      for (final event in events) {
        eventsByMatch.putIfAbsent(event.matchId, () => []).add(event);
      }

      // Aggregate stats from events
      int goals = 0;
      int assists = 0;
      int yellowCards = 0;
      int redCards = 0;

      for (final event in events) {
        switch (event.type) {
          case 'goal':
            goals++;
          case 'assist':
            assists++;
          case 'yellowCard':
            yellowCards++;
          case 'redCard':
            redCards++;
        }
      }

      // Count hat-tricks (3+ goals in a match)
      final goalsByMatch = <String, int>{};
      for (final event in events) {
        if (event.type == 'goal') {
          goalsByMatch[event.matchId] = (goalsByMatch[event.matchId] ?? 0) + 1;
        }
      }
      final hatTricks = goalsByMatch.values.where((g) => g >= 3).length;

      // Calculate match results based on which team user was on
      int wins = 0;
      int draws = 0;
      int losses = 0;
      int cleanSheets = 0;

      for (final match in matches) {
        final homeScore = match.homeScore;
        final awayScore = match.awayScore;

        // Determine which side the user was on
        final isHome = match.homeTeamId == userId;
        final isAway = match.awayTeamId == userId;

        if (isHome || (match.createdBy == userId && !isAway)) {
          // User is on home side
          if (homeScore > awayScore) {
            wins++;
          } else if (homeScore < awayScore) {
            losses++;
          } else {
            draws++;
          }
          if (awayScore == 0) cleanSheets++;
        } else if (isAway) {
          // User is on away side
          if (awayScore > homeScore) {
            wins++;
          } else if (awayScore < homeScore) {
            losses++;
          } else {
            draws++;
          }
          if (homeScore == 0) cleanSheets++;
        }
      }

      // Calculate avgRating from per-match event-based ratings
      double totalRating = 0;
      int ratedMatchCount = 0;

      for (final match in matches) {
        final matchEvents = eventsByMatch[match.matchId];
        if (matchEvents == null || matchEvents.isEmpty) continue;

        // Per-match rating: start at 6.0, adjust for goals/assists/cards
        double matchRating = 6.0;
        for (final event in matchEvents) {
          switch (event.type) {
            case 'goal':
              matchRating += 1.0;
            case 'assist':
              matchRating += 0.5;
            case 'yellowCard':
              matchRating -= 1.0;
            case 'redCard':
              matchRating -= 2.0;
          }
        }
        matchRating = matchRating.clamp(1.0, 10.0);
        totalRating += matchRating;
        ratedMatchCount++;
      }

      final avgRating = ratedMatchCount > 0 ? totalRating / ratedMatchCount : 6.0;

      // Get user's position and team
      String primaryPosition = '';
      String? secondaryPosition;
      String? teamName;

      try {
        final userDoc = await _appwrite.tablesDB.getRow(
          databaseId: Environment.appwriteDatabaseId,
          tableId: Environment.usersCollectionId,
          rowId: userId,
        );
        primaryPosition = userDoc.data['primaryPosition'] ?? '';
        secondaryPosition = userDoc.data['secondaryPosition'];
      } catch (_) {
        // User might not exist or position not set
      }

      return CareerStats(
        goals: goals,
        assists: assists,
        appearances: matches.length,
        wins: wins,
        draws: draws,
        losses: losses,
        avgRating: avgRating,
        yellowCards: yellowCards,
        redCards: redCards,
        cleanSheets: cleanSheets,
        hatTricks: hatTricks,
        motmAwards: 0,
        primaryPosition: primaryPosition,
        secondaryPosition: secondaryPosition,
        teamName: teamName,
      );
    } catch (e) {
      return const CareerStats();
    }
  }

  /// Get recent matches for a player (matches they participated in).
  Future<List<MatchModel>> getRecentMatches(String userId, {int limit = 10}) async {
    try {
      // Fetch matches where user is homeTeamId, awayTeamId, or createdBy
      final homeResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('homeTeamId', [userId]), Query.orderDesc('matchDate')],
      );
      final awayResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('awayTeamId', [userId]), Query.orderDesc('matchDate')],
      );
      final createdResponse = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [Query.equal('createdBy', [userId]), Query.orderDesc('matchDate')],
      );

      // Deduplicate by matchId
      final matchMap = <String, MatchModel>{};
      for (final row in [...homeResponse.rows, ...awayResponse.rows, ...createdResponse.rows]) {
        final m = MatchModel.fromJson(row.data);
        matchMap[m.matchId] = m;
      }

      final matches = matchMap.values.toList();
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
      return matches.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get last 5 match ratings for form chart — computed from match events.
  Future<List<double>> getLast5Ratings(String userId) async {
    try {
      // Try stored ratings from user document first
      final userDoc = await _appwrite.tablesDB.getRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: userId,
      );

      final storedRatings = userDoc.data['last5Ratings'] as List?;
      if (storedRatings != null && storedRatings.isNotEmpty) {
        return storedRatings.map((r) => (r as num).toDouble()).toList();
      }
    } catch (_) {}

    // Fallback: compute from recent match events
    try {
      final recentMatches = await getRecentMatches(userId, limit: 5);
      if (recentMatches.isEmpty) return [];

      final ratings = <double>[];
      for (final match in recentMatches) {
        final eventsResponse = await _appwrite.tablesDB.listRows(
          databaseId: Environment.appwriteDatabaseId,
          tableId: Environment.matchEventsCollectionId,
          queries: [
            Query.equal('matchId', [match.matchId]),
            Query.equal('playerId', [userId]),
          ],
        );

        final events = eventsResponse.rows
            .map((row) => MatchEventModel.fromJson(row.data))
            .toList();

        if (events.isEmpty) continue;

        double matchRating = 6.0;
        for (final event in events) {
          switch (event.type) {
            case 'goal':
              matchRating += 1.0;
            case 'assist':
              matchRating += 0.5;
            case 'yellowCard':
              matchRating -= 1.0;
            case 'redCard':
              matchRating -= 2.0;
          }
        }
        ratings.add(matchRating.clamp(1.0, 10.0));
      }
      return ratings;
    } catch (_) {
      return [];
    }
  }

  /// Get earned badges for a player.
  Future<List<PlayerBadge>> getEarnedBadges(String userId) async {
    final stats = await getCareerStats(userId);
    return BadgeDefinitions.calculateEarnedBadges(stats);
  }

  /// Update user's profile information.
  Future<void> updateProfile({
    required String userId,
    String? primaryPosition,
    String? secondaryPosition,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (primaryPosition != null) data['primaryPosition'] = primaryPosition;
    if (secondaryPosition != null) data['secondaryPosition'] = secondaryPosition;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    if (data.isEmpty) return;

    await _appwrite.tablesDB.updateRow(
      databaseId: Environment.appwriteDatabaseId,
      tableId: Environment.usersCollectionId,
      rowId: userId,
      data: data,
    );
  }

  /// Calculate and store win streak for badges.
  Future<int> getWinStreak(String userId) async {
    try {
      final response = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.matchesCollectionId,
        queries: [
          Query.equal('createdBy', [userId]),
          Query.orderDesc('matchDate'),
        ],
      );

      int streak = 0;
      for (final row in response.rows) {
        final homeScore = row.data['homeScore'] as int? ?? 0;
        final awayScore = row.data['awayScore'] as int? ?? 0;
        // Simplified - would need to check if user was on winning team
        if (homeScore > awayScore) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Award a badge to a user if not already earned.
  Future<bool> awardBadge(String userId, String badgeId) async {
    try {
      // Get current user document
      final userDoc = await _appwrite.tablesDB.getRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: userId,
      );

      // Get current badges
      final currentBadges = List<String>.from(userDoc.data['badges'] ?? []);

      // Add badge if not already present
      if (!currentBadges.contains(badgeId)) {
        currentBadges.add(badgeId);
        await _appwrite.tablesDB.updateRow(
          databaseId: Environment.appwriteDatabaseId,
          tableId: Environment.usersCollectionId,
          rowId: userId,
          data: {'badges': currentBadges},
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get badge IDs earned by a user.
  Future<List<String>> getEarnedBadgeIds(String userId) async {
    try {
      final userDoc = await _appwrite.tablesDB.getRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: userId,
      );
      return List<String>.from(userDoc.data['badges'] ?? []);
    } catch (e) {
      return [];
    }
  }
}

/// Provider for PlayerProfileRepository.
final playerProfileRepositoryProvider = Provider<PlayerProfileRepository>((ref) {
  return PlayerProfileRepository(ref.watch(appwriteServiceProvider));
});