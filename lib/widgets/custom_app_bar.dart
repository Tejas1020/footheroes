import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Redesigned CustomAppBar using Dark Colour System.
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final VoidCallback? onMenuTap;
  final bool showGlow;
  final double scrollOffset;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.onMenuTap,
    this.showGlow = true,
    this.scrollOffset = 0,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final blurAmount = (widget.scrollOffset * 0.05).clamp(0.0, 15.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          height: widget.preferredSize.height + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: AppTheme.abyss.withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(
                color: AppTheme.cardBorderColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildLeading(),
                      const SizedBox(width: 12),
                      _buildTitle(),
                      const Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
              ),
              // Bottom accent line
              Container(
                height: 2.5,
                decoration: const BoxDecoration(
                  gradient: AppTheme.appBarAccentGradient,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    return GestureDetector(
      onTap: widget.onMenuTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: AppTheme.cardBorder,
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: AppTheme.parchment,
          size: 22,
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
          widget.title.toUpperCase(),
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 20,
            letterSpacing: 1.0,
            color: AppTheme.parchment,
          ),
        ),
        if (widget.showLogo)
          Text(
            'FOOTHEROES',
            style: AppTheme.dmSans.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.cardinal,
              letterSpacing: 1.5,
            ),
          ),
      ],
    );
  }
}
