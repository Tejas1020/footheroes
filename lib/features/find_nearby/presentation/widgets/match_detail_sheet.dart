import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';

/// Bottom sheet displaying match details and join action.
class MatchDetailSheet extends StatelessWidget {
  final NearbyMatch match;
  final VoidCallback onRequestToJoin;

  const MatchDetailSheet({
    super.key,
    required this.match,
    required this.onRequestToJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.abyss,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mutedParchment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.cardinal
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.format,
                          style: AppTheme.dmSans.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cardinal,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${match.distanceKm?.toStringAsFixed(1) ?? '?'} km away',
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 12,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    match.venueName ?? 'Unknown venue',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time,
                    text: _formatDateTime(match.startTime),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.people_outline,
                    text:
                        '${match.slotsRemaining} of ${match.slotsNeeded} spots remaining',
                  ),
                  if (match.requestsCloseAt != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      text:
                          'Requests close at ${_formatTime(match.requestsCloseAt!)}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Positions needed',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: match.requiredPositions
                        .map((p) => _PositionChip(position: p))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: match.openToNearby ? onRequestToJoin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardinal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    match.openToNearby ? 'Request to Join' : 'Match Full',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]} ${dt.day}/${dt.month} at $h:$m';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.gold),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.dmSans.copyWith(
            fontSize: 14,
            color: AppTheme.parchment,
          ),
        ),
      ],
    );
  }
}

class _PositionChip extends StatelessWidget {
  final PlayingPosition position;

  const _PositionChip({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        position.value,
        style: AppTheme.dmSans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.parchment,
        ),
      ),
    );
  }
}
