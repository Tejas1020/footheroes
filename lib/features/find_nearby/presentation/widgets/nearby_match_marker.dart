import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

class NearbyMatchMarker extends StatelessWidget {
  final int count;
  final bool isSelected;
  final double size;

  const NearbyMatchMarker({
    super.key,
    this.count = 1,
    this.isSelected = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isSelected ? AppTheme.heroCtaGradient : AppTheme.awayDataGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.parchment : AppTheme.sparkBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppTheme.sparkBlue : AppTheme.sparkLight).withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 1 ? '$count' : '',
        style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.parchment),
      ),
    );
  }
}
