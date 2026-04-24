import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Custom bottom navigation using exact Dark Colour System spec.
class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.voidBg,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top line: 2.5px GradientE
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarAccentGradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.sports_soccer_rounded, 'Matches'),
                  _buildNavItem(2, Icons.fitness_center_rounded, 'Drills'),
                  _buildNavItem(3, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pill background for selected
          Container(
            width: 52,
            height: 30,
            decoration: isSelected
                ? BoxDecoration(
                    gradient: AppTheme.verticalPillGradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: AppTheme.navPillShadow,
                  )
                : null,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.parchment
                  : AppTheme.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.dmSans.copyWith(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.cardinal
                  : AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
