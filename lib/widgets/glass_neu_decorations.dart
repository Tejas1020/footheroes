import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Glassmorphic frosted card using Dark Colour System.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final Color? tintColor;

  const GlassCard({
    super.key,
    this.padding,
    this.radius = 20,
    this.blurSigma = 15,
    this.tintColor,
    required this.child,
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
                : AppTheme.abyss.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: AppTheme.cardBorderColor,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A premium section label with brand accent bar.
class BrandSectionLabel extends StatelessWidget {
  final String label;
  const BrandSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppTheme.accentBar(),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AppTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Pulsing dot indicator for live status using brand tokens.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppTheme.cardinal,
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
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Redesigned premium stat card using Dark Colour System.
class PremiumStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  const PremiumStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.cardinal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.standardCard,
      child: Column(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveColor, size: 20),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            value,
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 32,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
