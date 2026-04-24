import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../models/match_event_model.dart';

/// Rating badge background color based on performance tier.
Color _ratingBgColor(double rating) {
  if (rating >= 7.5) return AppTheme.cardinal.withValues(alpha: 0.2);
  if (rating >= 6.0) return AppTheme.gold.withValues(alpha: 0.2);
  return AppTheme.rose.withValues(alpha: 0.2);
}

/// Rating badge text color based on performance tier.
Color _ratingTextColor(double rating) {
  if (rating >= 7.5) return AppTheme.cardinal;
  if (rating >= 6.0) return AppTheme.gold;
  return AppTheme.rose;
}

/// Build visual event badges for a player from their match events.
List<_EventBadge> _buildEventBadges(List<MatchEventModel> events) {
  return events.map((event) => _EventBadge(
    type: event.type,
    minute: event.minute,
  )).toList();
}

/// A single player card in the live match roster using Dark Colour System.
class PlayerRowWidget extends StatelessWidget {
  final String playerId;
  final String playerName;
  final String playerPosition;
  final List<MatchEventModel> playerEvents;
  final Map<String, double> playerRatings;
  final bool isRedCarded;
  final bool isCaptain;
  final VoidCallback onTap;
  final VoidCallback? onToggleCaptain;

  const PlayerRowWidget({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerPosition,
    required this.playerEvents,
    required this.playerRatings,
    required this.isRedCarded,
    this.isCaptain = false,
    required this.onTap,
    this.onToggleCaptain,
  });

  @override
  Widget build(BuildContext context) {
    final rating = playerRatings[playerId] ?? 6.0;
    final badges = _buildEventBadges(playerEvents);

    return Opacity(
      opacity: isRedCarded ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: AppTheme.standardCard,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isRedCarded ? null : onTap,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: isCaptain
                      ? Border.all(color: AppTheme.cardinal.withValues(alpha: 0.6), width: 1.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppTheme.elevatedSurface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: isRedCarded
                                  ? const Icon(Icons.no_accounts,
                                      color: AppTheme.cardinal, size: 24)
                                  : Text(
                                      playerName.isNotEmpty
                                          ? playerName[0].toUpperCase()
                                          : '?',
                                      style: AppTheme.bebasDisplay.copyWith(
                                        fontSize: 20,
                                        color: AppTheme.parchment,
                                      ),
                                    ),
                            ),
                            if (isCaptain)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardinal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.cardSurface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(Icons.star, size: 10, color: AppTheme.parchment),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Name + position
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      playerName,
                                      style: AppTheme.bodyBold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (playerPosition.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.elevatedSurface,
                                        borderRadius: BorderRadius.circular(AppTheme.positionBadgeRadius),
                                      ),
                                      child: Text(
                                        playerPosition,
                                        style: AppTheme.labelSmall.copyWith(fontSize: 9),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Rating badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _ratingBgColor(rating),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: AppTheme.bebasDisplay.copyWith(
                                    fontSize: 14,
                                    color: _ratingTextColor(rating),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Captain toggle button
                        if (onToggleCaptain != null)
                          GestureDetector(
                            onTap: onToggleCaptain,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCaptain
                                    ? AppTheme.cardinal.withValues(alpha: 0.2)
                                    : AppTheme.elevatedSurface,
                                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                              ),
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: isCaptain
                                    ? AppTheme.cardinal
                                    : AppTheme.gold.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Tap arrow
                        Icon(
                          isRedCarded ? Icons.block : Icons.chevron_right,
                          color: isRedCarded
                              ? AppTheme.cardinal
                              : AppTheme.gold,
                          size: 24,
                        ),
                      ],
                    ),
                    // Event badges row
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildEventBadgesRow(badges),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventBadgesRow(List<_EventBadge> badges) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.map((badge) {
        final (icon, color) = switch (badge.type) {
          'goal' => (Icons.sports_soccer, AppTheme.cardinal),
          'assist' => (Icons.handshake, AppTheme.gold),
          'yellowCard' => (Icons.square, AppTheme.parchment),
          'redCard' => (Icons.square, AppTheme.cardinal),
          'subOn' => (Icons.keyboard_double_arrow_up, AppTheme.gold),
          'subOff' => (Icons.keyboard_double_arrow_down, AppTheme.cardinal),
          _ => (Icons.circle, AppTheme.gold),
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                "${badge.minute}'",
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EventBadge {
  final String type;
  final int minute;
  const _EventBadge({required this.type, required this.minute});
}