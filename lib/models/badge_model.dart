/// Badge definition model for achievement badges.
class BadgeDefinition {
  final String id;
  final String label;
  final String description;
  final String stat; // e.g. 'goals', 'cleanSheets', 'appearances'
  final int threshold;
  final String iconName;

  const BadgeDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.stat,
    required this.threshold,
    this.iconName = 'emoji_events',
  });
}

/// All available badge definitions with their unlock criteria.
const List<BadgeDefinition> kBadgeDefinitions = [
  BadgeDefinition(
    id: 'hat_trick_hero',
    label: 'Hat-trick Hero',
    description: 'Score 3+ goals in a single match',
    stat: 'hatTricks',
    threshold: 1,
    iconName: 'sports_soccer',
  ),
  BadgeDefinition(
    id: 'clean_sheet_king',
    label: 'Clean Sheet King',
    description: 'Keep 10+ clean sheets',
    stat: 'cleanSheets',
    threshold: 10,
    iconName: 'shield',
  ),
  BadgeDefinition(
    id: 'fifty_appearances',
    label: '50 Appearances',
    description: 'Play 50 matches',
    stat: 'appearances',
    threshold: 50,
    iconName: 'workspace_premium',
  ),
  BadgeDefinition(
    id: 'century_goals',
    label: 'Century Goals',
    description: 'Score 100+ career goals',
    stat: 'goals',
    threshold: 100,
    iconName: 'emoji_events',
  ),
  BadgeDefinition(
    id: 'golden_boot',
    label: 'Golden Boot',
    description: 'Score 20+ goals in a season',
    stat: 'goals',
    threshold: 20,
    iconName: 'emoji_events',
  ),
  BadgeDefinition(
    id: 'playmaker',
    label: 'Playmaker',
    description: 'Provide 20+ assists career',
    stat: 'assists',
    threshold: 20,
    iconName: 'handshake',
  ),
  BadgeDefinition(
    id: 'unbeaten',
    label: 'Unbeaten',
    description: 'Go unbeaten in 10 consecutive matches',
    stat: 'unbeatenStreak',
    threshold: 10,
    iconName: 'military_tech',
  ),
  BadgeDefinition(
    id: 'the_wall',
    label: 'The Wall',
    description: 'Keep 10+ clean sheets as goalkeeper',
    stat: 'cleanSheets',
    threshold: 10,
    iconName: 'block',
  ),
];

/// Check if a badge is earned based on stat value
bool isBadgeEarned(BadgeDefinition badge, int statValue) {
  return statValue >= badge.threshold;
}
