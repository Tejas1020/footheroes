import 'package:flutter/material.dart';
import '../theme/midnight_pitch_theme.dart';

/// Motion card with entrance animations, shimmer loading, and press feedback
class MotionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? glowColor;
  final double glowIntensity;
  final int staggerIndex;
  final bool enableShimmer;
  final bool isLoading;
  final Border? border;

  const MotionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.glowColor,
    this.glowIntensity = 0.15,
    this.staggerIndex = 0,
    this.enableShimmer = false,
    this.isLoading = false,
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
    if (widget.isLoading) {
      return _buildShimmerCard();
    }

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
            color: widget.backgroundColor ?? MidnightPitchTheme.surfaceContainer,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
            border: widget.border ??
                Border.all(
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.4)
                      : MidnightPitchTheme.ghostBorder,
                  width: _isPressed ? 1.5 : 1,
                ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? (widget.glowColor ?? MidnightPitchTheme.electricBlue).withValues(alpha: widget.glowIntensity * 2)
                    : (widget.glowColor ?? MidnightPitchTheme.deepNavy).withValues(alpha: widget.glowIntensity),
                blurRadius: _isPressed ? 20 : 12,
                offset: Offset(0, _isPressed ? 6 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      child: const _ShimmerPlaceholder(),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBlock(56, 56, borderRadius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBlock(120, 16),
                      const SizedBox(height: 8),
                      _shimmerBlock(80, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _shimmerBlock(double.infinity, 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => _shimmerBlock(48, 48, borderRadius: 12)),
            ),
          ],
        );
      },
    );
  }

  Widget _shimmerBlock(double width, double height, {double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_shimmerAnim.value - 1, 0),
          end: Alignment(_shimmerAnim.value + 1, 0),
          colors: [
            MidnightPitchTheme.surfaceContainerLow,
            MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
            MidnightPitchTheme.surfaceContainerLow,
          ],
        ),
      ),
    );
  }
}

/// Hero stat card with count-up animation and radial gradient background
class HeroStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int staggerIndex;
  final bool animateValue;

  const HeroStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.staggerIndex = 0,
    this.animateValue = true,
  });

  @override
  State<HeroStatCard> createState() => _HeroStatCardState();
}

class _HeroStatCardState extends State<HeroStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _entryAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _countAnim;
  double _displayValue = 0;

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
    _countAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _ctrl.addListener(() {
      if (widget.animateValue) {
        final numValue = double.tryParse(widget.value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        setState(() => _displayValue = numValue * _countAnim.value);
      }
    });
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
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.2),
                width: 1.5,
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
                // Radial glow behind icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.15),
                        widget.color.withValues(alpha: 0.0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Animated value
                Text(
                  widget.animateValue
                      ? _displayValue.toInt().toString()
                      : widget.value,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.headingFontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Match card with live pulse indicator and swipe-to-reveal actions
class LiveMatchCard extends StatefulWidget {
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
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _entryAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
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
          child: Opacity(opacity: _entryAnim.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MidnightPitchTheme.surfaceContainer,
                MidnightPitchTheme.surfaceContainerLow.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isLive
                  ? MidnightPitchTheme.liveRed.withValues(alpha: 0.3)
                  : MidnightPitchTheme.ghostBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isLive
                    ? MidnightPitchTheme.liveRed.withValues(alpha: 0.15)
                    : MidnightPitchTheme.deepNavy.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Live badge + time
              if (widget.isLive) ...[
                _LiveBadge(time: widget.timeDisplay),
                const SizedBox(height: 20),
              ],
              // Score row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TeamBlock(name: widget.homeTeam, score: widget.homeScore, isLeft: true),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text(
                        '${widget.homeScore}',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.headingFontFamily,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.mutedText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${widget.awayScore}',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.headingFontFamily,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  _TeamBlock(name: widget.awayTeam, score: widget.awayScore, isLeft: false),
                ],
              ),
              const SizedBox(height: 16),
              // CTA
              if (widget.isLive)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.onTap,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'RESUME MATCH',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MidnightPitchTheme.electricBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final int score;
  final bool isLeft;

  const _TeamBlock({required this.name, required this.score, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: MidnightPitchTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.shield_outlined,
              color: MidnightPitchTheme.electricBlue,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.secondaryText,
          ),
          overflow: TextOverflow.ellipsis,
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
        color: MidnightPitchTheme.liveRed,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.liveRed.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
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
                  color: Colors.white.withValues(alpha: 0.5 + (0.5 * _ctrl.value)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.time,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// W/L/D result badge with glow effect
class ResultBadge extends StatefulWidget {
  final String result; // W, L, D
  final double size;

  const ResultBadge({super.key, required this.result, this.size = 40});

  @override
  State<ResultBadge> createState() => _ResultBadgeState();
}

class _ResultBadgeState extends State<ResultBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _entryAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.result) {
      case 'W':
        return MidnightPitchTheme.electricBlue;
      case 'L':
        return MidnightPitchTheme.liveRed;
      case 'D':
        return MidnightPitchTheme.championGold;
      default:
        return MidnightPitchTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _entryAnim.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _color.withValues(alpha: 0.3 * _glowAnim.value),
                  _color.withValues(alpha: 0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size - 4,
                height: widget.size - 4,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.3 * _glowAnim.value),
                      blurRadius: 8 * _glowAnim.value,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.result,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.headingFontFamily,
                    fontSize: widget.size * 0.4,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
