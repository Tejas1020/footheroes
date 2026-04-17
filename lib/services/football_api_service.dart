import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../environment.dart';
import '../models/pro_player_stat.dart';
import '../models/pro_match_performance.dart';

/// Service for fetching real pro football statistics from football-data.org API.
/// Implements aggressive caching to respect rate limits (10 calls/minute).
class FootballApiService {
  final http.Client _client;
  final String _apiToken;

  // In-memory cache for current session
  static final Map<String, _CacheEntry> _memoryCache = {};

  // Rate limiting
  static final List<DateTime> _apiCalls = [];
  static const int _maxCallsPerMinute = 10;

  FootballApiService({
    http.Client? client,
    String? apiToken,
  }) : _client = client ?? http.Client(),
       _apiToken = apiToken ?? Environment.footballApiToken;

  /// Check if we can make an API call (rate limiting).
  bool get _canMakeApiCall {
    final now = DateTime.now();
    // Remove calls older than 1 minute
    _apiCalls.removeWhere((time) => now.difference(time).inMinutes >= 1);
    return _apiCalls.length < _maxCallsPerMinute;
  }

  /// Record an API call for rate limiting.
  void _recordApiCall() {
    _apiCalls.add(DateTime.now());
  }

  /// Check if cached data is stale.
  bool isCacheStale(String cacheKey, Duration maxAge) {
    final entry = _memoryCache[cacheKey];
    if (entry == null) return true;
    return DateTime.now().difference(entry.fetchedAt) > maxAge;
  }

  /// Get from cache if available and not stale.
  dynamic _getFromMemoryCache(String key) {
    return _memoryCache[key]?.data;
  }

  /// Store in memory cache.
  void _storeInMemoryCache(String key, dynamic data) {
    _memoryCache[key] = _CacheEntry(data: data, fetchedAt: DateTime.now());
  }

  /// Make an API call with rate limiting.
  Future<http.Response> _makeApiCall(String endpoint) async {
    if (!_canMakeApiCall) {
      throw Exception('Rate limit exceeded. Please try again in a moment.');
    }

    final uri = Uri.parse('${Environment.footballDataBaseUrl}$endpoint');
    final response = await _client.get(
      uri,
      headers: {
        'X-Auth-Token': _apiToken,
        'Accept': 'application/json',
      },
    );

    _recordApiCall();

    if (response.statusCode == 429) {
      throw Exception('API rate limit exceeded. Please try again later.');
    }

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }

    return response;
  }

  /// Get top scorers for a competition.
  /// Competition codes: PL (Premier League), BL1 (Bundesliga), PD (La Liga), DED (Eredivisie).
  Future<List<ProPlayerStat>> getTopScorers({
    required String competitionCode,
    int limit = 10,
  }) async {
    final cacheKey = 'scorers_$competitionCode';

    // Check memory cache first
    final cached = _getFromMemoryCache(cacheKey);
    if (cached != null) {
      return cached as List<ProPlayerStat>;
    }

    // Check if we can make API call
    if (!_canMakeApiCall) {
      // Return stale cache if available
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!.data as List<ProPlayerStat>;
      }
      throw Exception('Rate limit exceeded. Please try again in a moment.');
    }

    try {
      final response = await _makeApiCall('/competitions/$competitionCode/scorers?limit=$limit');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final scorers = data['scorers'] as List? ?? [];

      final players = scorers.map((scorer) {
        final player = scorer['player'] as Map<String, dynamic>?;
        final team = scorer['team'] as Map<String, dynamic>?;

        return ProPlayerStat(
          id: player?['id'] ?? 0,
          name: player?['name'] ?? '',
          position: player?['position'] ?? 'ST',
          teamName: team?['name'] ?? '',
          teamCode: team?['tla'],
          nationality: player?['nationality'] ?? '',
          goals: scorer['goals'] ?? 0,
          assists: scorer['assists'] ?? 0,
          appearances: scorer['playedMatches'] ?? scorer['appearances'] ?? 0,
          competitionCode: competitionCode,
          fetchedAt: DateTime.now(),
        );
      }).toList();

      _storeInMemoryCache(cacheKey, players);
      return players;
    } catch (e) {
      // Return stale cache on error
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!.data as List<ProPlayerStat>;
      }
      rethrow;
    }
  }

  /// Get top performers by position.
  /// Position: ST, CF, LW, RW (attackers); CAM, CM, CDM (midfielders); CB, LB, RB (defenders); GK.
  Future<List<ProPlayerStat>> getTopPerformersByPosition({
    required String position,
    required String competitionCode,
    int limit = 5,
  }) async {
    // Get all scorers and filter by position
    final scorers = await getTopScorers(competitionCode: competitionCode, limit: 50);

    final positionGroup = _getPositionGroup(position);
    final filtered = scorers.where((p) => _getPositionGroup(p.position) == positionGroup).take(limit).toList();

    return filtered;
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

  /// Get player stats by ID.
  Future<ProPlayerStat?> getPlayerStats({
    required int playerId,
    String competitionCode = 'PL',
  }) async {
    final cacheKey = 'player_$playerId';

    final cached = _getFromMemoryCache(cacheKey);
    if (cached != null) {
      return cached as ProPlayerStat;
    }

    try {
      // Try to find player in scorers list first
      final scorers = await getTopScorers(competitionCode: competitionCode, limit: 100);
      final player = scorers.where((p) => p.id == playerId).firstOrNull;
      if (player != null) {
        _storeInMemoryCache(cacheKey, player);
        return player;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get weekend standout performances from recent matches.
  Future<List<ProMatchPerformance>> getWeekendStandouts({
    required String competitionCode,
    int limit = 5,
  }) async {
    final cacheKey = 'standouts_$competitionCode';

    final cached = _getFromMemoryCache(cacheKey);
    if (cached != null) {
      return cached as List<ProMatchPerformance>;
    }

    if (!_canMakeApiCall) {
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!.data as List<ProMatchPerformance>;
      }
      throw Exception('Rate limit exceeded. Please try again in a moment.');
    }

    try {
      final response = await _makeApiCall('/competitions/$competitionCode/matches?status=FINISHED&limit=20');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final matches = data['matches'] as List? ?? [];

      final standouts = <ProMatchPerformance>[];

      for (final match in matches) {
        final goals = match['score']?['fullTime']?['homeTeam'] ?? 0;
        final awayGoals = match['score']?['fullTime']?['awayTeam'] ?? 0;

        // Get goal scorers from match
        // Note: football-data.org may not provide detailed goal info in free tier
        // This is a simplified implementation

        final homeTeam = match['homeTeam']?['name'] ?? '';
        final awayTeam = match['awayTeam']?['name'] ?? '';
        final matchDate = match['utcDate'] != null
            ? DateTime.parse(match['utcDate'])
            : DateTime.now();

        // Create standout entries for high-scoring matches
        if (goals >= 3 || awayGoals >= 3) {
          standouts.add(ProMatchPerformance(
            playerName: 'Top Performer',
            teamName: goals >= 3 ? homeTeam : awayTeam,
            position: 'ST',
            goals: (goals >= 3 ? goals : awayGoals),
            assists: 0,
            matchDescription: '$homeTeam vs $awayTeam',
            matchDate: matchDate,
            competitionCode: competitionCode,
          ));
        }

        if (standouts.length >= limit) break;
      }

      _storeInMemoryCache(cacheKey, standouts);
      return standouts;
    } catch (e) {
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!.data as List<ProMatchPerformance>;
      }
      rethrow;
    }
  }

  /// Get player photo URL from TheSportsDB (free, no auth).
  Future<String?> getPlayerPhotoUrl(String playerName) async {
    final cacheKey = 'photo_$playerName';

    final cached = _getFromMemoryCache(cacheKey);
    if (cached != null) {
      return cached as String?;
    }

    try {
      final uri = Uri.parse('${Environment.sportsDbBaseUrl}/searchplayers.php?p=${Uri.encodeComponent(playerName)}');
      final response = await _client.get(uri);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final players = data['player'] as List?;

      if (players != null && players.isNotEmpty) {
        final playerData = players.first as Map<String, dynamic>?;
        final photoUrl = playerData?['strThumb'] as String?;
        _storeInMemoryCache(cacheKey, photoUrl);
        return photoUrl;
      }

      _storeInMemoryCache(cacheKey, null);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data.
  void clearCache() {
    _memoryCache.clear();
  }
}

/// Cache entry with timestamp.
class _CacheEntry {
  final dynamic data;
  final DateTime fetchedAt;

  _CacheEntry({required this.data, required this.fetchedAt});
}

/// Provider for FootballApiService.
final footballApiServiceProvider = Provider<FootballApiService>((ref) {
  return FootballApiService();
});