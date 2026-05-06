import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/nearby_match.dart';

class MatchCard extends StatelessWidget {
  final NearbyMatch match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final joined = match.slotsNeeded - match.slotsRemaining;
    final isFull = match.slotsRemaining <= 0;
    final timeStr = DateFormat('HH:mm').format(match.startTime);

    return GestureDetector(
      onTap: isFull ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardSurfaceGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFull ? AppTheme.cardBorderColorLight : AppTheme.cardBorderColorAlt,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1000458E),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.sparkBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.format,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.sparkBlue,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.gold),
                    const SizedBox(width: 4),
                    Text(
                      match.distanceKm != null
                          ? '${match.distanceKm!.toStringAsFixed(1)} km'
                          : 'Nearby',
                      style: AppTheme.dmSans.copyWith(fontSize: 12, color: AppTheme.gold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (match.venueName != null)
              Text(
                match.venueName!,
                style: AppTheme.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.people, '$joined/${match.slotsNeeded}'),
                const SizedBox(width: 12),
                _chip(Icons.schedule, timeStr),
                const Spacer(),
                if (isFull)
                  Text('FULL', style: AppTheme.labelSmall.copyWith(color: AppTheme.feedbackError))
                else
                  const Icon(Icons.chevron_right, color: AppTheme.gold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.gold),
        const SizedBox(width: 3),
        Text(text, style: AppTheme.dmSans.copyWith(fontSize: 10, color: AppTheme.gold)),
      ],
    );
  }
}
