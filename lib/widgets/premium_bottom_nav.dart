import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Redesigned premium bottom navigation using Dark Colour System.
class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(icon: Icons.grid_view_rounded, label: 'Home'),
    _NavItemData(icon: Icons.explore_rounded, label: 'Find'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
    _NavItemData(icon: Icons.leaderboard_rounded, label: 'Ranks'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.abyss,
        border: Border(
          top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isActive = i == currentIndex;
              final color = isActive ? AppTheme.cardinal : AppTheme.gold;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[i].icon,
                          size: 24,
                          color: color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          style: AppTheme.dmSans.copyWith(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.cardinal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}
