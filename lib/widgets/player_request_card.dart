import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

class PlayerRequestCard extends StatelessWidget {
  final String playerName;
  final String position;
  final String? photoUrl;
  final int? rating;
  final String? clubName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const PlayerRequestCard({
    super.key,
    required this.playerName,
    required this.position,
    this.photoUrl,
    this.rating,
    this.clubName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final initials = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardSurfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColorAlt),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1000458E),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.heroCtaGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.badgeShadow,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTheme.bebasDisplay.copyWith(fontSize: 20, color: AppTheme.parchment),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName.toUpperCase(), style: AppTheme.bodyBold),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(position, style: AppTheme.labelSmall),
                    if (rating != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: AppTheme.accentBlue),
                      const SizedBox(width: 2),
                      Text('${rating!}', style: AppTheme.labelSmall.copyWith(color: AppTheme.accentBlue)),
                    ],
                  ],
                ),
                if (clubName != null)
                  Text(clubName!, style: AppTheme.dmSans.copyWith(fontSize: 10, color: AppTheme.mutedParchment)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDecline,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.feedbackError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: AppTheme.feedbackError, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.heroCtaGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: AppTheme.parchment, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
