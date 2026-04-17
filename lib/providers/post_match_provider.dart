import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../repositories/match_repository.dart';
import '../providers/match_provider.dart';

/// State for post-match summary.
class PostMatchState {
  final MatchModel? match;
  final List<MatchEventModel> events;
  final Map<String, PlayerStats> playerStats;
  final String? manOfTheMatchId;
  final bool hasVoted;
  final bool isLoading;
  final String? error;

  const PostMatchState({
    this.match,
    this.events = const [],
    this.playerStats = const {},
    this.manOfTheMatchId,
    this.hasVoted = false,
    this.isLoading = false,
    this.error,
  });

  PostMatchState copyWith({
    MatchModel? match,
    List<MatchEventModel>? events,
    Map<String, PlayerStats>? playerStats,
    String? manOfTheMatchId,
    bool? hasVoted,
    bool? isLoading,
    String? error,
  }) {
    return PostMatchState(
      match: match ?? this.match,
      events: events ?? this.events,
      playerStats: playerStats ?? this.playerStats,
      manOfTheMatchId: manOfTheMatchId ?? this.manOfTheMatchId,
      hasVoted: hasVoted ?? this.hasVoted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get top 3 rated players.
  List<String> getTopRatedPlayers() {
    final sortedPlayers = playerStats.entries.toList()
      ..sort((a, b) => b.value.rating.compareTo(a.value.rating));
    return sortedPlayers.take(3).map((e) => e.key).toList();
  }
}

/// Player statistics for a match.
class PlayerStats {
  final String playerId;
  final String playerName;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final double rating;

  const PlayerStats({
    required this.playerId,
    required this.playerName,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.rating = 6.0,
  });

  PlayerStats copyWith({
    String? playerId,
    String? playerName,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    double? rating,
  }) {
    return PlayerStats(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      rating: rating ?? this.rating,
    );
  }
}

/// Notifier for post-match state.
class PostMatchNotifier extends StateNotifier<PostMatchState> {
  final MatchRepository _matchRepository;
  final MatchEventRepository _eventRepository;

  PostMatchNotifier(this._matchRepository, this._eventRepository) : super(const PostMatchState());

  /// Load match data for summary.
  Future<void> loadMatchSummary(String matchId, {String? currentUserId}) async {
    state = state.copyWith(isLoading: true);

    try {
      final match = await _matchRepository.getById(matchId);
      if (match == null) {
        state = state.copyWith(isLoading: false, error: 'Match not found');
        return;
      }
      final events = await _eventRepository.getEventsForMatch(matchId);

      // Calculate player stats from events
      final playerStats = _calculatePlayerStats(events);

      // Check if current user already voted
      final motmVotes = match.stats?['motmVotes'] as Map<String, dynamic>?;
      bool hasVoted = false;
      if (currentUserId != null && motmVotes != null) {
        hasVoted = motmVotes.containsKey(currentUserId);
      }

      // Determine MOTM winner if voting is closed
      String? motmWinnerId;
      if (match.motmVotingClosed) {
        motmWinnerId = match.stats?['motmWinnerId'] as String?;
      }

      state = state.copyWith(
        match: match,
        events: events,
        playerStats: playerStats,
        hasVoted: hasVoted,
        manOfTheMatchId: motmWinnerId,
        isLoading: false,
      );

      // Check if 24h has passed — close voting if so
      await checkAndCloseMotmVoting(matchId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Calculate stats from events.
  Map<String, PlayerStats> _calculatePlayerStats(List<MatchEventModel> events) {
    final stats = <String, PlayerStats>{};

    for (final event in events) {
      final existing = stats[event.playerId];
      if (existing == null) {
        stats[event.playerId] = PlayerStats(
          playerId: event.playerId,
          playerName: event.playerName,
        );
      }

      final current = stats[event.playerId]!;
      switch (event.type) {
        case 'goal':
          stats[event.playerId] = current.copyWith(
            goals: current.goals + 1,
            rating: (current.rating + 1.0).clamp(1.0, 10.0),
          );
          break;
        case 'assist':
          stats[event.playerId] = current.copyWith(
            assists: current.assists + 1,
            rating: (current.rating + 0.5).clamp(1.0, 10.0),
          );
          break;
        case 'yellowCard':
          stats[event.playerId] = current.copyWith(
            yellowCards: current.yellowCards + 1,
            rating: (current.rating - 1.0).clamp(1.0, 10.0),
          );
          break;
        case 'redCard':
          stats[event.playerId] = current.copyWith(
            redCards: current.redCards + 1,
            rating: (current.rating - 2.0).clamp(1.0, 10.0),
          );
          break;
      }
    }

    return stats;
  }

  /// Delete a match. Only the creator should call this (enforced by UI).
  Future<bool> deleteMatch(String matchId) async {
    try {
      final deleted = await _matchRepository.deleteMatch(matchId);
      if (deleted) {
        state = const PostMatchState();
      }
      return deleted;
    } catch (_) {
      return false;
    }
  }

  /// Vote for man of the match. Stores {votingPlayerId: votedForPlayerId} per voter.
  Future<void> voteManOfTheMatch(String matchId, String votedForPlayerId, String votingPlayerId) async {
    if (state.hasVoted) return;

    await _matchRepository.submitMotmVote(matchId, votedForPlayerId, votingPlayerId);

    state = state.copyWith(
      manOfTheMatchId: votedForPlayerId,
      hasVoted: true,
    );
  }

  /// Check if MOTM voting should close (24h after match end).
  /// If closed, tallies votes, stores winner, and updates state.
  Future<void> checkAndCloseMotmVoting(String matchId) async {
    if (state.match == null) return;
    if (state.match!.motmVotingClosed) return;

    final matchEndTime = state.match!.matchEndTime;
    if (matchEndTime == null) return;

    final deadline = matchEndTime.add(const Duration(hours: 24));
    if (!DateTime.now().isAfter(deadline)) return;

    final winner = await _matchRepository.closeMotmVoting(matchId);
    if (winner != null) {
      state = state.copyWith(manOfTheMatchId: winner);
    }
  }

  /// Get man of the match winner (most votes).
  String? getManOfTheMatchWinner() {
    final stats = state.match?.stats;
    if (stats == null) return null;

    final motmVotes = stats['motmVotes'] as Map<String, dynamic>?;
    if (motmVotes == null || motmVotes.isEmpty) return null;

    final tally = <String, int>{};
    for (final v in motmVotes.values) {
      final key = v.toString();
      tally[key] = (tally[key] ?? 0) + 1;
    }
    if (tally.isEmpty) return null;

    return tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// Provider for post-match state.
final postMatchProvider = StateNotifierProvider<PostMatchNotifier, PostMatchState>((ref) {
  return PostMatchNotifier(
    ref.watch(matchRepositoryProvider),
    ref.watch(matchEventRepositoryProvider),
  );
});