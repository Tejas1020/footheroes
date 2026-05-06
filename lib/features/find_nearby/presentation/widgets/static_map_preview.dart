import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/venue.dart';

class StaticMapPreview extends StatelessWidget {
  final Venue venue;
  final double height;

  const StaticMapPreview({
    super.key,
    required this.venue,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColorLight),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Center(
                child: Icon(Icons.map, size: 48, color: AppTheme.sparkBlue),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.sparkBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: AppTheme.sparkBlue, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  '${venue.latitude.toStringAsFixed(4)}, ${venue.longitude.toStringAsFixed(4)}',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 10,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.voidBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                venue.name,
                style: AppTheme.dmSans.copyWith(fontSize: 10, color: AppTheme.parchment),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
