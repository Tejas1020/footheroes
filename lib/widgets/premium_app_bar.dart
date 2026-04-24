import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Premium AppBar using exact Dark Colour System spec.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final double scrollOffset;
  final bool showBackButton;
  final VoidCallback? onBack;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.scrollOffset = 0,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final blurAmount = (scrollOffset * 0.05).clamp(0.0, 15.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          height: preferredSize.height + topPadding,
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 20),
          decoration: const BoxDecoration(
            color: AppTheme.voidBg,
          ),
          child: Stack(
            children: [
              // Football watermark behind text
              Positioned(
                left: 60,
                top: 8,
                child: Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: AppTheme.cardinal.withValues(alpha: 0.03),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (showBackButton) ...[
                          GestureDetector(
                            onTap: onBack ?? () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: AppTheme.cardBorder,
                              ),
                              child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.parchment, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        _buildTitle(),
                        const Spacer(),
                        _buildBellIcon(),
                        const SizedBox(width: 8),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOOTHEROES',
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 22,
            letterSpacing: 2.0,
            color: AppTheme.parchment,
          ),
        ),
        Text(
          title.toUpperCase(),
          style: AppTheme.dmSans.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.gold,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBellIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.cardinal,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppTheme.bellIconShadow,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.notifications_none_rounded,
        color: AppTheme.gold,
        size: 20,
      ),
    );
  }
}
