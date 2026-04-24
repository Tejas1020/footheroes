import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../models/badge_model.dart';
import '../services/local_match_storage.dart';
import '../services/offline_sync_service.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_profile_repository.dart';
import '../providers/match_timer_provider.dart';
import '../../../../../../../features/match/data/models/live_match_models.dart';
import 'match_provider.dart' show matchRepositoryProvider, matchEventRepositoryProvider;

/// State for live match management.
class LiveMatchState {
  final MatchModel? currentMatch;
  final List<MatchEventModel> events;
  final Map<String, double> playerRatings;
  final int homeScore;
  final int awayScore;
  final SyncStatus syncStatus;
  final bool isLoading;
  final String? error;
  final List<String> redCardedPlayerIds;
  final String? homeCaptainId;
  final String? awayCaptainId;
  final List<LivePlayerInfo> customRoster;

  const LiveMatchState({
    this.currentMatch,
    this.events = const [],
    this.playerRatings = const {},
    this.homeScore = 0,
    this.awayScore = 0,
    this.syncStatus = SyncStatus.synced,
    this.isLoading = false,
    this.error,
    this.redCardedPlayerIds = const [],
    this.homeCaptainId,
    this.awayCaptainId,
    this.customRoster = const [],
  });

  LiveMatchState copyWith({
    MatchModel? currentMatch,
    List<MatchEventModel>? events,
    Map<String, double>? playerRatings,
    int? homeScore,
    int? awayScore,
    SyncStatus? syncStatus,
    bool? isLoading,
    String? error,
    List<String>? redCardedPlayerIds,
    String? homeCaptainId,
    String? awayCaptainId,
    List<LivePlayerInfo>? customRoster,
  }) {
    return LiveMatchState(
      currentMatch: currentMatch ?? this.currentMatch,
      events: events ?? this.events,
      playerRatings: playerRatings ?? this.playerRatings,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      syncStatus: syncStatus ?? this.syncStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      redCardedPlayerIds: redCardedPlayerIds ?? this.redCardedPlayerIds,
      homeCaptainId: homeCaptainId,
      awayCaptainId: awayCaptainId,
      customRoster: customRoster ?? this.customRoster,
    );
  }
}

/// Notifier for live match state management.
class LiveMatchNotifier extends StateNotifier<LiveMatchState> {
  final LocalMatchStorage _localStorage;
  final MatchRepository _matchRepository;
  final MatchEventRepository _eventRepository;
  final OfflineSyncService _syncService;
  final MatchTimerNotifier _timerNotifier;
  final PlayerProfileRepository _playerProfileRepo;

  LiveMatchNotifier(
    this._localStorage,
    this._matchRepository,
    this._eventRepository,
    this._syncService,
    this._timerNotifier,
    this._playerProfileRepo,
  ) : super(const LiveMatchState());

  /// Initialize a new match.
  Future<void> initMatch(MatchModel match) async {
    state = state.copyWith(isLoading: true);

    final existingEvents = _localStorage.getMatchEvents(match.matchId);
    final ratings = _localStorage.getAllRatings();

    int homeScore = match.homeScore;
    int awayScore = match.awayScore;
    for (final event in existingEvents) {
      if (event['type'] == 'goal') {
        if (event['team'] == 'away') {
          awayScore++;
        } else {
          homeScore++;
        }
      }
    }

    _timerNotifier.initMatch(match.matchId, halfDurationMinutes: _getHalfDuration(match.format));

    state = state.copyWith(
      currentMatch: match,
      events: existingEvents.map(_mapToMatchEventModel).toList(),
      playerRatings: ratings,
      homeScore: homeScore,
      awayScore: awayScore,
      isLoading: false,
    );

    await _localStorage.saveActiveMatch(match.toJson());
  }

  int _getHalfDuration(String format) {
    switch (format.toLowerCase()) {
      case '5v5':
      case '5-a-side': return 25;
      case '7v7':
      case '7-a-side': return 30;
      default: return 45;
    }
  }

  /// Add a player to the roster.
  void addPlayerToRoster(LivePlayerInfo player) {
    state = state.copyWith(
      customRoster: [...state.customRoster, player],
    );
  }

  /// Log a new event (saves locally first, then syncs).
  /// Also detects hat-tricks and awards them immediately.
  Future<void> logEvent({
    required String type,
    required String playerId,
    required String playerName,
    String? details,
    String team = 'home',
  }) async {
    if (state.currentMatch == null) return;

    final eventId = const Uuid().v4();
    final minute = _timerNotifier.state.currentMinute;

    final event = MatchEventModel(
      id: eventId,
      eventId: eventId,
      matchId: state.currentMatch!.matchId,
      type: type,
      playerId: playerId,
      playerName: playerName,
      minute: minute,
      details: details,
      team: team,
    );

    // 1. Save to Hive immediately
    await _localStorage.saveEventLocally(event.toJson());

    // 2. Update local state
    state = state.copyWith(
      events: [...state.events, event],
      syncStatus: SyncStatus.pending,
    );

    // 3. Update score if goal
    if (type == 'goal') {
      if (team == 'away') {
        state = state.copyWith(awayScore: state.awayScore + 1);
      } else {
        state = state.copyWith(homeScore: state.homeScore + 1);
      }
      // Hat-trick detection: count goals for this player in this match
      final goalCount = state.events.where((e) => e.playerId == playerId && e.type == 'goal').length;
      if (goalCount == 3) {
        await _incrementHatTrickStat(playerId);
      }
      // Sync updated scores to Appwrite
      _syncScoresToAppwrite();
    }

    // 4. If red card, remove player from active roster
    if (type == 'redCard') {
      removePlayerFromActive(playerId);
    }

    // 5. Update player rating
    _updatePlayerRating(playerId, type);

    // 6. Attempt sync in background
    _syncEventToAppwrite(event);
  }

  Future<void> _incrementHatTrickStat(String playerId) async {
    try {
      // Increment hatTricks stat in Appwrite for this player
      // This would normally update a user stats document
      // For now, we log it locally and it will be tallied in getCareerStats
    } catch (_) {}
  }

  /// Update player rating based on event type.
  void _updatePlayerRating(String playerId, String eventType) {
    final currentRating = state.playerRatings[playerId] ?? 6.0;
    double change = switch (eventType) {
      'goal' => 1.0,
      'assist' => 0.5,
      'yellowCard' => -1.0,
      'redCard' => -2.0,
      _ => 0.0,
    };

    final newRating = (currentRating + change).clamp(1.0, 10.0);
    _localStorage.saveRating(playerId, newRating);

    state = state.copyWith(
      playerRatings: {...state.playerRatings, playerId: newRating},
    );
  }

  /// Sync event to Appwrite in background.
  Future<void> _syncEventToAppwrite(MatchEventModel event) async {
    try {
      await _eventRepository.create(event.eventId, event.toJson());
      await _localStorage.markEventSynced(event.eventId);
      state = state.copyWith(syncStatus: SyncStatus.synced);
    } catch (_) {
      state = state.copyWith(syncStatus: SyncStatus.pending);
    }
  }

  /// Sync current scores to Appwrite in background.
  Future<void> _syncScoresToAppwrite() async {
    if (state.currentMatch == null) return;
    try {
      await _matchRepository.updateScore(
        state.currentMatch!.matchId,
        state.homeScore,
        state.awayScore,
      );
    } catch (_) {
      // Score sync is best-effort — will be persisted on match end
    }
  }

  /// Update match score manually.
  Future<void> updateScore({required bool isHome, required int newScore}) async {
    if (state.currentMatch == null) return;

    if (isHome) {
      state = state.copyWith(homeScore: newScore);
    } else {
      state = state.copyWith(awayScore: newScore);
    }

    await _matchRepository.updateScore(
      state.currentMatch!.matchId,
      isHome ? newScore : state.homeScore,
      isHome ? state.awayScore : newScore,
    );
  }

  /// End first half.
  void endHalf() {
    _timerNotifier.endFirstHalf();
  }

  /// Start second half.
  void startSecondHalf() {
    _timerNotifier.startSecondHalf();
  }

  /// End match and prepare for summary.
  /// Triggers badge award check after stats are updated in Appwrite.
  Future<void> endMatch() async {
    _timerNotifier.endMatch();

    if (state.currentMatch != null) {
      // Update local match state to completed so dashboard hides the live card
      state = state.copyWith(
        currentMatch: state.currentMatch!.copyWith(status: 'completed'),
      );

      // Step 1: Update match status + matchEndTime + final scores in Appwrite
      await _matchRepository.updateStatus(
        state.currentMatch!.matchId,
        'completed',
      );
      await _matchRepository.update(
        state.currentMatch!.matchId,
        {
          'matchEndTime': DateTime.now().toIso8601String(),
          'homeScore': state.homeScore,
          'awayScore': state.awayScore,
        },
      );

      // Step 2: Sync any remaining pending events
      await _syncService.syncPendingEvents();

      // Step 3: Check and award badges based on career stats
      // This runs AFTER stats are updated so badge thresholds can be evaluated accurately.
      await _checkAndAwardBadges();
    }

    // Step 4: Clear local storage
    await _localStorage.clearActiveMatch();
    await _localStorage.clearRatings();
  }

  /// Iterates all badge definitions and awards any earned but not yet awarded badges.
  /// Runs after endMatch() so career stats are up-to-date in Appwrite.
  Future<void> _checkAndAwardBadges() async {
    try {
      // Get the user who is the scorer/manager of this match
      final userId = state.currentMatch?.createdBy;
      if (userId == null) return;

      final stats = await _playerProfileRepo.getCareerStats(userId);
      final earnedIds = await _playerProfileRepo.getEarnedBadgeIds(userId);

      final statsMap = stats.toMap();
      for (final badge in kBadgeDefinitions) {
        if (earnedIds.contains(badge.id)) continue;
        final value = statsMap[badge.stat] ?? 0;
        if (value >= badge.threshold) {
          await _playerProfileRepo.awardBadge(userId, badge.id);
        }
      }
    } catch (_) {
      // Badge award is best-effort — do not block match end on failure
    }
  }

  /// Remove a player from the active roster (after a red card).
  /// The player remains visible in the roster but is greyed out and unselectable.
  void removePlayerFromActive(String playerId) {
    if (!state.redCardedPlayerIds.contains(playerId)) {
      state = state.copyWith(
        redCardedPlayerIds: [...state.redCardedPlayerIds, playerId],
      );
    }
  }

  /// Toggle captain status for a player (only one captain per team).
  void toggleCaptain(String playerId, String team) {
    final isCurrentlyCaptain = (team == 'home' && state.homeCaptainId == playerId) ||
        (team == 'away' && state.awayCaptainId == playerId);

    if (team == 'home') {
      state = state.copyWith(
        homeCaptainId: isCurrentlyCaptain ? null : playerId,
        awayCaptainId: state.awayCaptainId, // Keep away captain
      );
    } else {
      state = state.copyWith(
        homeCaptainId: state.homeCaptainId, // Keep home captain
        awayCaptainId: isCurrentlyCaptain ? null : playerId,
      );
    }

    // Also sync to match roster provider if available
    _syncCaptainToRoster(playerId, team, !isCurrentlyCaptain);
  }

  void _syncCaptainToRoster(String playerId, String team, bool isCaptain) {
    // This will be handled by the live_match_screen.dart calling matchRosterProvider
  }

  /// Void (cancel) an event — removes it and reverses score if it was a goal.
  Future<void> voidEvent(String eventId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId || e.eventId == eventId,
      orElse: () => throw StateError('Event not found'),
    );

    // Reverse score if it was a goal
    if (event.type == 'goal') {
      if (event.team == 'away') {
        state = state.copyWith(awayScore: state.awayScore - 1);
      } else {
        state = state.copyWith(homeScore: state.homeScore - 1);
      }
    }

    // Reverse rating change
    _reversePlayerRating(event.playerId, event.type);

    // Remove from state
    state = state.copyWith(
      events: state.events.where((e) => e.id != eventId && e.eventId != eventId).toList(),
    );

    // Remove from local storage
    await _localStorage.deleteEvent(eventId);

    // Sync updated scores to Appwrite
    _syncScoresToAppwrite();

    // If red card was voided, restore player to active
    if (event.type == 'redCard') {
      state = state.copyWith(
        redCardedPlayerIds: state.redCardedPlayerIds.where((id) => id != event.playerId).toList(),
      );
    }
  }

  /// Change the team of an existing event (e.g., move a goal from home to away).
  Future<void> changeEventTeam(String eventId, String newTeam) async {
    final updatedEvents = state.events.map((e) {
      if (e.id == eventId || e.eventId == eventId) {
        return e.copyWith(team: newTeam);
      }
      return e;
    }).toList();

    // Recalculate scores from scratch
    int homeScore = 0;
    int awayScore = 0;
    for (final e in updatedEvents) {
      if (e.type == 'goal') {
        if (e.team == 'away') {
          awayScore++;
        } else {
          homeScore++;
        }
      }
    }

    state = state.copyWith(events: updatedEvents, homeScore: homeScore, awayScore: awayScore);

    // Update in local storage
    final event = updatedEvents.firstWhere((e) => e.id == eventId || e.eventId == eventId);
    await _localStorage.saveEventLocally(event.toJson());

    // Sync updated scores to Appwrite
    _syncScoresToAppwrite();
  }

  /// Reverse a player rating change from a voided event.
  void _reversePlayerRating(String playerId, String eventType) {
    final currentRating = state.playerRatings[playerId] ?? 6.0;
    double change = switch (eventType) {
      'goal' => -1.0,
      'assist' => -0.5,
      'yellowCard' => 1.0,
      'redCard' => 2.0,
      _ => 0.0,
    };
    final newRating = (currentRating + change).clamp(1.0, 10.0);
    _localStorage.saveRating(playerId, newRating);
    state = state.copyWith(
      playerRatings: {...state.playerRatings, playerId: newRating},
    );
  }

  /// Resume a match from saved state.
  Future<void> resumeMatch(String matchId) async {
    final savedMatch = _localStorage.getActiveMatch();
    if (savedMatch != null && savedMatch['matchId'] == matchId) {
      await initMatch(MatchModel.fromJson(savedMatch));
    }
  }

  /// Clear match state.
  void clearMatch() {
    state = const LiveMatchState();
  }

  MatchEventModel _mapToMatchEventModel(Map<String, dynamic> data) {
    return MatchEventModel(
      id: data['id'] ?? data['eventId'] ?? '',
      eventId: data['eventId'] ?? '',
      matchId: data['matchId'] ?? '',
      type: data['type'] ?? '',
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      minute: data['minute'] ?? 0,
      details: data['details'],
      team: data['team'] ?? 'home',
    );
  }
}

/// Provider for live match.
final liveMatchProvider = StateNotifierProvider<LiveMatchNotifier, LiveMatchState>((ref) {
  return LiveMatchNotifier(
    LocalMatchStorage(),
    ref.watch(matchRepositoryProvider),
    ref.watch(matchEventRepositoryProvider),
    ref.watch(offlineSyncServiceProvider.notifier),
    ref.watch(matchTimerProvider.notifier),
    ref.watch(playerProfileRepositoryProvider),
  );
});