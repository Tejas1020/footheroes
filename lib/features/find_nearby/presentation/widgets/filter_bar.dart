import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/playing_position.dart';

class FilterBar extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;
  final String? selectedFormat;
  final ValueChanged<String?> onFormatChanged;
  final PlayingPosition? selectedPosition;
  final ValueChanged<PlayingPosition?> onPositionChanged;
  final VoidCallback onDiscover;

  const FilterBar({
    super.key,
    required this.radiusKm,
    required this.onRadiusChanged,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.selectedPosition,
    required this.onPositionChanged,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorderColorLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              Text('FILTERS', style: AppTheme.labelSmall),
              const Spacer(),
              GestureDetector(
                onTap: onDiscover,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('DISCOVER', style: AppTheme.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.directions_run, size: 16, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text('${radiusKm.toInt()} km', style: AppTheme.bodyReg.copyWith(fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppTheme.sparkBlue,
                    inactiveTrackColor: AppTheme.elevatedSurface,
                    thumbColor: AppTheme.sparkBlue,
                    overlayColor: AppTheme.sparkBlue.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: radiusKm,
                    min: 1,
                    max: 50,
                    onChanged: onRadiusChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sports_soccer, size: 16, color: AppTheme.gold),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['5-a-side', '7-a-side', '11-a-side'].map((f) {
                      final isSelected = selectedFormat == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => onFormatChanged(isSelected ? null : f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.heroCtaGradient : null,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected ? null : Border.all(color: AppTheme.cardBorderColorLight),
                            ),
                            child: Text(f, style: AppTheme.dmSans.copyWith(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.gold,
                            )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
