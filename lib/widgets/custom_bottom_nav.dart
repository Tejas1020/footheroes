import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Premium floating bottom navigation — 5 tabs with animated pill indicator.
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
  final List<GlobalKey> _itemKeys = List.generate(5, (_) => GlobalKey());
  late AnimationController _rippleController;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandOrange.withAlpha(25),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(235),
                  Colors.white.withAlpha(200),
                ],
              ),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: Colors.white.withAlpha(120),
                width: 1.4,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabCount = 5;
                final tabWidth = constraints.maxWidth / tabCount;
                final pillWidth = tabWidth * 0.72;
                final pillLeft = widget.currentIndex * tabWidth +
                    (tabWidth - pillWidth) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Sliding pill indicator with glow
                    AnimatedPositioned(
                      left: pillLeft,
                      top: 8,
                      bottom: 8,
                      width: pillWidth,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutExpo,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.brandOrange.withAlpha(28),
                              AppTheme.brandOrangeLight.withAlpha(14),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.brandOrange.withAlpha(55),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandOrange.withAlpha(20),
                              blurRadius: 14,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nav items
                    Positioned.fill(
                      child: Row(
                        children: [
                          _buildNavItem(0, Icons.home_rounded, 'Home'),
                          _buildNavItem(1, Icons.sports_soccer_rounded, 'Match'),
                          _buildNavItem(2, Icons.fitness_center_rounded, 'Drills'),
                          _buildNavItem(3, Icons.emoji_events_rounded, 'Ranks'),
                          _buildNavItem(4, Icons.person_rounded, 'Profile'),
                        ],
                      ),
                    ),
                    // Ripple overlay
                    if (_pressedIndex != null)
                      Positioned(
                        left: _pressedIndex! * tabWidth,
                        top: 0,
                        width: tabWidth,
                        height: 72,
                        child: IgnorePointer(child: _buildRipple()),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRipple() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _RipplePainter(_rippleController.value),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        key: _itemKeys[index],
        onTapDown: (_) {
          setState(() => _pressedIndex = index);
          _rippleController.forward(from: 0);
        },
        onTapUp: (_) {
          setState(() => _pressedIndex = null);
          _rippleController.reset();
        },
        onTapCancel: () {
          setState(() => _pressedIndex = null);
          _rippleController.reset();
        },
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isSelected ? 1.18 : 1.0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? AppTheme.brandOrange
                        : AppTheme.brandOrange.withAlpha(55),
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: Text(
                label,
                style: AppTheme.dmSans.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandOrange,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = progress * size.width * 0.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brandOrange.withAlpha(40),
          AppTheme.brandOrange.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
