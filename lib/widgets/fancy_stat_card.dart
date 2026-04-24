import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Redesigned FancyStatCard using Dark Colour System.
class FancyStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FancyStatItem> stats;
  final Color? glowColor;

  const FancyStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.standardCard.copyWith(
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppTheme.cardinal).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            // Abstract background elements
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (glowColor ?? AppTheme.cardinal).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: AppTheme.bebasDisplay.copyWith(
                              fontSize: 16,
                              color: AppTheme.parchment,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle.toUpperCase(),
                            style: AppTheme.labelSmall,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (glowColor ?? AppTheme.cardinal).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: glowColor ?? AppTheme.cardinal,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: stats.map((stat) => _buildStatItem(stat)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(FancyStatItem stat) {
    return Column(
      children: [
        Text(
          stat.value,
          style: AppTheme.bebasDisplay.copyWith(
            color: stat.color,
            fontSize: 42,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(fontSize: 8),
        ),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class FancyStatItem {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  FancyStatItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}
