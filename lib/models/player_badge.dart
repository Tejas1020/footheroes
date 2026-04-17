import 'career_stats.dart';

/// Achievement badge that can be earned by players.
class PlayerBadge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final bool isLocked;
  final DateTime? earnedAt;
  final int? progressCurrent;
  final int? progressTarget;

  const PlayerBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorHex,
    this.isLocked = false,
    this.earnedAt,
    this.progressCurrent,
    this.progressTarget,
  });

  /// Whether this badge has progress tracking.
  bool get hasProgress => progressTarget != null && progressCurrent != null;

  /// Progress percentage (0-100).
  double get progressPercentage {
    if (!hasProgress) return isLocked ? 0 : 100;
    return (progressCurrent! / progressTarget!) * 100;
  }

  factory PlayerBadge.fromJson(Map<String, dynamic> json) {
    return PlayerBadge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'emoji_events',
      colorHex: json['colorHex'] ?? '#FFC107',
      isLocked: json['isLocked'] ?? true,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])
          : null,
      progressCurrent: json['progressCurrent'],
      progressTarget: json['progressTarget'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'isLocked': isLocked,
      'earnedAt': earnedAt?.toIso8601String(),
      'progressCurrent': progressCurrent,
      'progressTarget': progressTarget,
    };
  }
}

/// All available badges with their unlock criteria.
class BadgeDefinitions {
  /// Hat-trick hero badge - scored 3+ goals in a single match.
  static PlayerBadge hatTrickHero({int current = 0}) => PlayerBadge(
    id: 'hat_trick_hero',
    name: 'Hat-trick Hero',
    description: 'Score 3+ goals in a single match',
    iconName: 'sports_soccer',
    colorHex: '#FFC107',
    isLocked: current < 1,
    progressCurrent: current,
    progressTarget: 1,
  );

  /// Clean sheet king badge - 5+ clean sheets (GK/DEF only).
  static PlayerBadge cleanSheetKing({int current = 0}) => PlayerBadge(
    id: 'clean_sheet_king',
    name: 'Clean Sheet King',
    description: 'Keep 5+ clean sheets',
    iconName: 'shield',
    colorHex: '#4CAF50',
    isLocked: current < 5,
    progressCurrent: current,
    progressTarget: 5,
  );

  /// 50 club badge - 50+ appearances.
  static PlayerBadge fiftyClub({int current = 0}) => PlayerBadge(
    id: 'fifty_club',
    name: '50 Club',
    description: 'Play 50 matches',
    iconName: 'workspace_premium',
    colorHex: '#9C27B0',
    isLocked: current < 50,
    progressCurrent: current,
    progressTarget: 50,
  );

  /// Assist king badge - 10+ assists in a season.
  static PlayerBadge assistKing({int current = 0}) => PlayerBadge(
    id: 'assist_king',
    name: 'Assist King',
    description: 'Provide 10+ assists in a season',
    iconName: 'handshake',
    colorHex: '#00BCD4',
    isLocked: current < 10,
    progressCurrent: current,
    progressTarget: 10,
  );

  /// Unbeaten badge - 10 match win streak.
  static PlayerBadge unbeaten({int current = 0}) => PlayerBadge(
    id: 'unbeaten',
    name: 'Unbeaten',
    description: 'Win 10 matches in a row',
    iconName: 'military_tech',
    colorHex: '#FF9800',
    isLocked: current < 10,
    progressCurrent: current,
    progressTarget: 10,
  );

  /// Golden boot - 20+ goals in a season.
  static PlayerBadge goldenBoot({int current = 0}) => PlayerBadge(
    id: 'golden_boot',
    name: 'Golden Boot',
    description: 'Score 20+ goals in a season',
    iconName: 'emoji_events',
    colorHex: '#FFD700',
    isLocked: current < 20,
    progressCurrent: current,
    progressTarget: 20,
  );

  /// Wall - 10+ clean sheets for GK.
  static PlayerBadge theWall({int current = 0}) => PlayerBadge(
    id: 'the_wall',
    name: 'The Wall',
    description: 'Keep 10+ clean sheets',
    iconName: 'block',
    colorHex: '#607D8B',
    isLocked: current < 10,
    progressCurrent: current,
    progressTarget: 10,
  );

  /// Playmaker - 20+ assists career.
  static PlayerBadge playmaker({int current = 0}) => PlayerBadge(
    id: 'playmaker',
    name: 'Playmaker',
    description: 'Provide 20+ assists career',
    iconName: 'lightbulb',
    colorHex: '#E91E63',
    isLocked: current < 20,
    progressCurrent: current,
    progressTarget: 20,
  );

  /// Calculate badges from career stats.
  static List<PlayerBadge> calculateEarnedBadges(CareerStats stats, {int winStreak = 0}) {
    return [
      hatTrickHero(current: stats.hatTricks),
      cleanSheetKing(current: stats.cleanSheets),
      fiftyClub(current: stats.appearances),
      assistKing(current: stats.assists),
      unbeaten(current: winStreak),
      goldenBoot(current: stats.goals),
      theWall(current: stats.cleanSheets),
      playmaker(current: stats.assists),
    ];
  }
}