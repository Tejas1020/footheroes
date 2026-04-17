import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service for offline-first match data using Hive.
/// Boxes must be opened in main() before using this class.
class LocalMatchStorage {
  static const String _pendingEventsBox = 'pending_events';
  static const String _activeMatchBox = 'active_match';
  static const String _localRatingsBox = 'local_ratings';

  /// Get the pending events box (opened in main()).
  Box<Map> get _pendingEvents => Hive.box<Map>(_pendingEventsBox);

  /// Get the active match box (opened in main()).
  Box<Map> get _activeMatch => Hive.box<Map>(_activeMatchBox);

  /// Get the local ratings box (opened in main()).
  Box<Map> get _localRatings => Hive.box<Map>(_localRatingsBox);

  // ========================================
  // ACTIVE MATCH
  // ========================================

  /// Save the current active match to survive app kills.
  Future<void> saveActiveMatch(Map<String, dynamic> matchData) async {
    await _activeMatch.put('current', matchData);
  }

  /// Get the current active match if any.
  Map<String, dynamic>? getActiveMatch() {
    return _activeMatch.get('current')?.cast<String, dynamic>();
  }

  /// Clear the active match (after match ends).
  Future<void> clearActiveMatch() async {
    await _activeMatch.delete('current');
  }

  // ========================================
  // PENDING EVENTS (NOT YET SYNCED)
  // ========================================

  /// Save an event locally BEFORE attempting Appwrite sync.
  /// Returns the generated event ID.
  Future<String> saveEventLocally(Map<String, dynamic> eventData) async {
    final eventId = eventData['eventId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final eventWithSync = {
      ...eventData,
      'eventId': eventId,
      'synced': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _pendingEvents.put(eventId, eventWithSync);
    return eventId;
  }

  /// Get all pending events that haven't been synced.
  List<Map<String, dynamic>> getPendingEvents() {
    return _pendingEvents.values
        .where((e) => e['synced'] == false)
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  /// Get all events for a specific match (synced or not).
  List<Map<String, dynamic>> getMatchEvents(String matchId) {
    final events = _pendingEvents.values
        .where((e) => e['matchId'] == matchId)
        .map((e) => e.cast<String, dynamic>())
        .toList();
    events.sort((a, b) => (a['minute'] as int).compareTo(b['minute'] as int));
    return events;
  }

  /// Mark an event as synced after successful Appwrite write.
  Future<void> markEventSynced(String eventId) async {
    final event = _pendingEvents.get(eventId);
    if (event != null) {
      await _pendingEvents.put(eventId, {
        ...event.cast<String, dynamic>(),
        'synced': true,
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Clear all synced events (cleanup).
  Future<void> clearSyncedEvents() async {
    final keysToDelete = _pendingEvents.keys
        .where((key) => _pendingEvents.get(key)?['synced'] == true)
        .toList();
    for (final key in keysToDelete) {
      await _pendingEvents.delete(key);
    }
  }

  /// Delete a specific event (for undo/corrections).
  Future<void> deleteEvent(String eventId) async {
    await _pendingEvents.delete(eventId);
  }

  // ========================================
  // LOCAL PLAYER RATINGS
  // ========================================

  /// Save a player's rating.
  Future<void> saveRating(String playerId, double rating) async {
    await _localRatings.put(playerId, {
      'playerId': playerId,
      'rating': rating,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get all player ratings for current match.
  Map<String, double> getAllRatings() {
    final ratings = <String, double>{};
    for (final key in _localRatings.keys) {
      final data = _localRatings.get(key);
      if (data != null && data['rating'] != null) {
        ratings[key.toString()] = (data['rating'] as num).toDouble();
      }
    }
    return ratings;
  }

  /// Get a specific player's rating.
  double? getRating(String playerId) {
    final data = _localRatings.get(playerId);
    if (data != null && data['rating'] != null) {
      return (data['rating'] as num).toDouble();
    }
    return null;
  }

  /// Clear all ratings (end of match).
  Future<void> clearRatings() async {
    await _localRatings.clear();
  }

  /// Calculate and update rating based on events.
  double calculateRating({
    required int goals,
    required int assists,
    required int yellowCards,
    required int redCards,
  }) {
    double rating = 6.0; // Base rating
    rating += goals * 1.0;  // +1 per goal
    rating += assists * 0.5; // +0.5 per assist
    rating -= yellowCards * 1.0; // -1 per yellow
    rating -= redCards * 2.0; // -2 per red
    return rating.clamp(1.0, 10.0); // Min 1.0, Max 10.0
  }

  // ========================================
  // TIMER STATE PERSISTENCE
  // ========================================

  /// Save timer state for crash recovery.
  Future<void> saveTimerState({
    required String matchId,
    required int elapsedSeconds,
    required int currentHalf,
    required int stoppageSeconds,
    required String status,
  }) async {
    await _activeMatch.put('timer_$matchId', {
      'matchId': matchId,
      'elapsedSeconds': elapsedSeconds,
      'currentHalf': currentHalf,
      'stoppageSeconds': stoppageSeconds,
      'status': status,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get timer state for recovery.
  Map<String, dynamic>? getTimerState(String matchId) {
    return _activeMatch.get('timer_$matchId')?.cast<String, dynamic>();
  }

  /// Clear timer state.
  Future<void> clearTimerState(String matchId) async {
    await _activeMatch.delete('timer_$matchId');
  }
}