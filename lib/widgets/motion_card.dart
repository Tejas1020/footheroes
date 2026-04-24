import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Motion card using Dark Colour System with GradientB background.
class MotionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? glowColor;
  final double glowIntensity;
  final int staggerIndex;
  final Border? border;

  const MotionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.glowColor,
    this.glowIntensity = 0.08,
    this.staggerIndex = 0,
    this.border,
  });

  @override
  State<MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends State<MotionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 500 + (widget.staggerIndex * 100)),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null
            ? (_) { setState(() => _isPressed = false); widget.onTap?.call(); }
            : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.backgroundColor == null
                ? AppTheme.cardSurfaceGradient
                : null,
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.cardRadius),
            border: widget.border ??
                Border.all(
                  color: _isPressed
                      ? AppTheme.cardinal.withValues(alpha: 0.4)
                      : const Color(0x20C1121F),
                  width: 1,
                ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? (widget.glowColor ?? AppTheme.cardinal).withValues(alpha: widget.glowIntensity * 2)
                    : const Color(0x12C1121F),
                blurRadius: _isPressed ? 20 : 16,
                offset: Offset(0, _isPressed ? 6 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hero stat card with count-up animation and radial glow.
class HeroStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int staggerIndex;

  const HeroStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.staggerIndex = 0,
  });

  @override
  State<HeroStatCard> createState() => _HeroStatCardState();
}

class _HeroStatCardState extends State<HeroStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _entryAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.staggerIndex * 120)),
      vsync: this,
    );
    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _entryAnim.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.cardSurfaceGradient,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.1 * _glowAnim.value),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: AppTheme.parchment, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.value,
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 32,
                    color: widget.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label.toUpperCase(),
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Match card with live pulse indicator.
class LiveMatchCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String timeDisplay;
  final bool isLive;
  final VoidCallback? onTap;

  const LiveMatchCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.timeDisplay,
    this.isLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.standardCard,
        child: Column(
          children: [
            if (isLive) ...[
              _LiveBadge(time: timeDisplay),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TeamBlock(name: homeTeam, isHome: true),
                Text(
                  '$homeScore - $awayScore',
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 48),
                ),
                _TeamBlock(name: awayTeam, isHome: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final bool isHome;

  const _TeamBlock({required this.name, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: isHome ? AppTheme.heroCtaGradient : AppTheme.awayDataGradient,
            shape: BoxShape.circle,
            boxShadow: isHome ? AppTheme.shieldShadow : AppTheme.awayShieldShadow,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.shield, color: AppTheme.parchment, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          style: AppTheme.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isHome ? AppTheme.cardinal : AppTheme.gold,
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final String time;
  const _LiveBadge({required this.time});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0x50C1121F), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.parchment.withValues(alpha: 0.4 + (0.6 * _ctrl.value)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE  ${widget.time}',
            style: AppTheme.dmSans.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.parchment,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ResultBadge extends StatelessWidget {
  final String result; // W, L, D
  final double size;

  const ResultBadge({super.key, required this.result, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.verticalPillGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppTheme.formBadgeShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        result,
        style: AppTheme.bebasDisplay.copyWith(
          fontSize: size * 0.45,
          color: AppTheme.parchment,
        ),
      ),
    );
  }
}
