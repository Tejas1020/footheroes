import 'dart:ui';

/// Data models for the live match screen.
/// Designed for offline-first use — all state lives locally
/// and can be synced to the backend later.

/// Type of event that can be logged during a match.
enum MatchEventType {
  goal,
  assist,
  yellowCard,
  redCard,
  subOn,
  subOff;

  /// Short display string.
  String get displayShort => switch (this) {
        goal => 'G',
        assist => 'A',
        yellowCard => 'YC',
        redCard => 'RC',
        subOn => 'SO',
        subOff => 'SF',
      };

  /// Full display string.
  String get displayFull => switch (this) {
        goal => 'Goal',
        assist => 'Assist',
        yellowCard => 'Yellow Card',
        redCard => 'Red Card',
        subOn => 'Sub On',
        subOff => 'Sub Off',
      };
}

/// A single event logged during a match.
class MatchEvent {
  final MatchEventType type;
  final int minute;
  final String playerId;

  const MatchEvent({
    required this.type,
    required this.minute,
    required this.playerId,
  });

  MatchEvent copyWith({
    MatchEventType? type,
    int? minute,
    String? playerId,
  }) {
    return MatchEvent(
      type: type ?? this.type,
      minute: minute ?? this.minute,
      playerId: playerId ?? this.playerId,
    );
  }
}

/// A player participating in a match.
class MatchPlayer {
  final String id;
  final String name;
  final String position;
  final String? avatarUrl;
  final bool isInactive;

  const MatchPlayer({
    required this.id,
    required this.name,
    required this.position,
    this.avatarUrl,
    this.isInactive = false,
  });

  /// Build a short summary of events for this player (e.g. "2G 1A", "1 Yellow Card").
  String eventSummary(List<MatchEvent> events) {
    final playerEvents = events.where((e) => e.playerId == id).toList();
    if (playerEvents.isEmpty) return 'No events logged';

    final goals = playerEvents.where((e) => e.type == MatchEventType.goal).length;
    final assists = playerEvents.where((e) => e.type == MatchEventType.assist).length;
    final yellows = playerEvents.where((e) => e.type == MatchEventType.yellowCard).length;
    final reds = playerEvents.where((e) => e.type == MatchEventType.redCard).length;

    final parts = <String>[];
    if (goals > 0) parts.add('${goals}G');
    if (assists > 0) parts.add('${assists}A');
    if (yellows > 0) parts.add('$yellows Yellow Card${yellows > 1 ? 's' : ''}');
    if (reds > 0) parts.add('$reds Red Card${reds > 1 ? 's' : ''}');

    return parts.isEmpty ? 'No events logged' : parts.join(' ');
  }

  /// Whether the player has a red card (sent off).
  bool hasRedCard(List<MatchEvent> events) {
    return events.any((e) => e.playerId == id && e.type == MatchEventType.redCard);
  }

  /// Whether the player has a yellow card.
  bool hasYellowCard(List<MatchEvent> events) {
    return events.any((e) => e.playerId == id && e.type == MatchEventType.yellowCard);
  }
}

/// Team info displayed in the scoreboard.
class MatchTeam {
  final String name;
  final String abbreviation;
  final Color accentColor;

  const MatchTeam({
    required this.name,
    required this.abbreviation,
    required this.accentColor,
  });
}

/// Full match state — all data needed for the live match screen.
class LiveMatch {
  final MatchTeam teamA;
  final MatchTeam teamB;
  final int scoreA;
  final int scoreB;
  final String matchDay;
  final List<MatchPlayer> players;
  final List<MatchEvent> events;
  final Duration elapsed;
  final bool isRunning;

  const LiveMatch({
    required this.teamA,
    required this.teamB,
    this.scoreA = 0,
    this.scoreB = 0,
    this.matchDay = 'Match Day 1',
    this.players = const [],
    this.events = const [],
    this.elapsed = Duration.zero,
    this.isRunning = true,
  });

  LiveMatch copyWith({
    MatchTeam? teamA,
    MatchTeam? teamB,
    int? scoreA,
    int? scoreB,
    String? matchDay,
    List<MatchPlayer>? players,
    List<MatchEvent>? events,
    Duration? elapsed,
    bool? isRunning,
  }) {
    return LiveMatch(
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      matchDay: matchDay ?? this.matchDay,
      players: players ?? this.players,
      events: events ?? this.events,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// Formatted elapsed time as MM:SS.
  String get timerDisplay {
    final minutes = elapsed.inMinutes.remainder(100);
    final seconds = elapsed.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}