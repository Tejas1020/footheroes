import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/match_event_model.dart';

/// Rating badge background color based on performance tier.
Color _ratingBgColor(double rating) {
  if (rating >= 7) return MidnightPitchTheme.electricMint.withValues(alpha: 0.2);
  if (rating >= 5) return MidnightPitchTheme.championGold.withValues(alpha: 0.2);
  return MidnightPitchTheme.liveRed.withValues(alpha: 0.2);
}

/// Rating badge text color based on performance tier.
Color _ratingTextColor(double rating) {
  if (rating >= 7) return MidnightPitchTheme.electricMint;
  if (rating >= 5) return MidnightPitchTheme.championGold;
  return MidnightPitchTheme.liveRed;
}

/// Build visual event badges for a player from their match events.
List<_EventBadge> _buildEventBadges(List<MatchEventModel> events) {
  final badges = <_EventBadge>[];
  for (final event in events) {
    badges.add(_EventBadge(
      type: event.type,
      minute: event.minute,
    ));
  }
  return badges;
}

/// A single player card in the live match roster.
/// Tap to open event logging sheet.
class PlayerRowWidget extends StatelessWidget {
  final String playerId;
  final String playerName;
  final String playerPosition;
  final List<MatchEventModel> playerEvents;
  final Map<String, double> playerRatings;
  final bool isRedCarded;
  final VoidCallback onTap;

  const PlayerRowWidget({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerPosition,
    required this.playerEvents,
    required this.playerRatings,
    required this.isRedCarded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = playerRatings[playerId] ?? 6.0;
    final badges = _buildEventBadges(playerEvents);

    return Opacity(
      opacity: isRedCarded ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: MidnightPitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isRedCarded ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isRedCarded
                            ? Icon(Icons.no_accounts,
                                color: MidnightPitchTheme.liveRed, size: 24)
                            : Text(
                                playerName.isNotEmpty
                                    ? playerName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: MidnightPitchTheme.primaryText,
                                ),
                              ),
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
                                    style: TextStyle(
                                      fontFamily: MidnightPitchTheme.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: MidnightPitchTheme.primaryText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (playerPosition.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MidnightPitchTheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      playerPosition,
                                      style: TextStyle(
                                        fontFamily: MidnightPitchTheme.fontFamily,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: MidnightPitchTheme.mutedText,
                                      ),
                                    ),
                                  ),
                                if (isRedCarded) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.no_accounts,
                                      color: MidnightPitchTheme.liveRed, size: 14),
                                ],
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
                                style: TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _ratingTextColor(rating),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tap arrow
                      Icon(
                        isRedCarded ? Icons.block : Icons.chevron_right,
                        color: isRedCarded
                            ? MidnightPitchTheme.liveRed
                            : MidnightPitchTheme.mutedText,
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
    );
  }

  Widget _buildEventBadgesRow(List<_EventBadge> badges) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.map((badge) {
        final (icon, bgColor, textColor) = switch (badge.type) {
          'goal' => (Icons.sports_soccer, MidnightPitchTheme.electricMint.withValues(alpha: 0.15), MidnightPitchTheme.electricMint),
          'assist' => (Icons.handshake, MidnightPitchTheme.skyBlue.withValues(alpha: 0.15), MidnightPitchTheme.skyBlue),
          'yellowCard' => (Icons.square, MidnightPitchTheme.championGold.withValues(alpha: 0.2), MidnightPitchTheme.championGold),
          'redCard' => (Icons.square, MidnightPitchTheme.liveRed.withValues(alpha: 0.2), MidnightPitchTheme.liveRed),
          'subOn' => (Icons.keyboard_double_arrow_up, MidnightPitchTheme.electricMint.withValues(alpha: 0.15), MidnightPitchTheme.electricMint),
          'subOff' => (Icons.keyboard_double_arrow_down, MidnightPitchTheme.liveRed.withValues(alpha: 0.15), MidnightPitchTheme.liveRed),
          _ => (Icons.circle, MidnightPitchTheme.surfaceContainerHighest, MidnightPitchTheme.mutedText),
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 14),
              const SizedBox(width: 4),
              Text(
                "${badge.minute}'",
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
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