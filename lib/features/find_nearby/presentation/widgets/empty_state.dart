import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

class NearbyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NearbyEmptyState({
    super.key,
    this.icon = Icons.sports_soccer,
    this.title = 'No Matches Found',
    this.subtitle = 'Try expanding your search radius or check back later',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(title, style: AppTheme.bebasDisplay.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.dmSans.copyWith(
                fontSize: 13,
                color: AppTheme.gold,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
