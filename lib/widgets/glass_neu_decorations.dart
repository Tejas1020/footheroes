import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/midnight_pitch_theme.dart';

/// Neumorphic raised container — cool clay gray (#E0E5EC) with dual white/dark shadows.
/// Use for stat tiles, cards, and interactive elements that need soft 3D depth.
/// Set isPressed=true to animate to the concave (pressed) state.
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isPressed;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.isPressed = false,
    this.padding,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? MidnightPitchTheme.neuBase,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isPressed
              ? MidnightPitchTheme.neuPressed
              : MidnightPitchTheme.neuRaised,
        ),
        child: child,
      ),
    );
  }
}

/// Glassmorphic frosted card — uses BackdropFilter blur over a semi-transparent fill.
/// Use for elevated overlays, live match cards, hero sections.
/// The blur creates the frosted glass depth effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.blurSigma = 15,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tintColor != null
                ? tintColor!.withValues(alpha: 0.25)
                : MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Color(0xFFFFFFFF).withValues(alpha: 0.40),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glassmorphic icon badge — frosted circle for stat icons inside neumorphic tiles.
class GlassIconBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? tintColor;
  final double size;

  const GlassIconBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    this.tintColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tintColor?.withValues(alpha: 0.20) ??
                iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: Color(0xFFFFFFFF).withValues(alpha: 0.50),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }
}

/// Neumorphic stat tile — raised tile for grid-based stat displays.
class NeumorphicStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const NeumorphicStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MidnightPitchTheme.neuRaised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? MidnightPitchTheme.electricMint, size: 20),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 0.05,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic result badge — frosted badge for W/L/D results.
class GlassBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showGlow;
  final double size;

  const GlassBadge({
    super.key,
    required this.label,
    required this.color,
    this.showGlow = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(size / 4),
            border: Border.all(
              color: color.withValues(alpha: 0.50),
            ),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient avatar badge — used in headers for user initials.
class GlassAvatarBadge extends StatelessWidget {
  final String initials;
  final double size;
  final Color? gradientStart;
  final Color? gradientEnd;

  const GlassAvatarBadge({
    super.key,
    required this.initials,
    this.size = 56,
    this.gradientStart,
    this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientStart ?? MidnightPitchTheme.electricMintLight,
            gradientEnd ?? MidnightPitchTheme.electricMintDark,
          ],
        ),
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: MidnightPitchTheme.neuBase,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials.isNotEmpty ? initials[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: size * 0.40,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.electricMint,
          ),
        ),
      ),
    );
  }
}

/// Count-up animation widget for stat values.
class AnimatedStatValue extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedStatValue({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedStatValue> createState() => _AnimatedStatValueState();
}

class _AnimatedStatValueState extends State<AnimatedStatValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          widget.value,
          style: widget.style,
        );
      },
    );
  }
}

/// Pulsing dot indicator for live status.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: widget.size * 1.5,
                spreadRadius: widget.size * 0.2,
              ),
            ],
          ),
        );
      },
    );
  }
}
