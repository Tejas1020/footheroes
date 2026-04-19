import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/midnight_pitch_theme.dart';

/// Motion-driven AppBar with parallax, glow effects, and animated elements
class MotionAppBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGlow;
  final double scrollOffset;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const MotionAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showGlow = true,
    this.scrollOffset = 0,
    this.onMenuTap,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  State<MotionAppBar> createState() => _MotionAppBarState();
}

class _MotionAppBarState extends State<MotionAppBar>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final parallaxOffset = widget.scrollOffset * 0.3;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _shimmerController]),
      builder: (context, child) {
        return _AnimatedAppBarContent(
          topPadding: topPadding,
          parallaxOffset: parallaxOffset,
          entryValue: _fadeAnim.value,
          slideValue: _slideAnim.value,
          glowValue: _glowAnim.value,
          shimmerValue: _shimmerAnim.value,
          showGlow: widget.showGlow,
          title: widget.title,
          subtitle: widget.subtitle,
          showBackButton: widget.showBackButton,
          onBackTap: widget.onBackTap,
          onMenuTap: widget.onMenuTap,
          actions: widget.actions,
          onBack: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

/// Separate widget so AnimatedBuilder doesn't have nested builder issues
class _AnimatedAppBarContent extends StatelessWidget {
  final double topPadding;
  final double parallaxOffset;
  final double entryValue;
  final double slideValue;
  final double glowValue;
  final double shimmerValue;
  final bool showGlow;
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const _AnimatedAppBarContent({
    required this.topPadding,
    required this.parallaxOffset,
    required this.entryValue,
    required this.slideValue,
    required this.glowValue,
    required this.shimmerValue,
    required this.showGlow,
    required this.title,
    this.subtitle,
    required this.showBackButton,
    this.onBackTap,
    this.onMenuTap,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.9 + (entryValue * 0.1)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.08 + (0.06 * glowValue)),
                  blurRadius: 20 + (10 * glowValue),
                  offset: Offset(0, 4 + (2 * glowValue)),
                ),
              ]
            : null,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Leading
                Transform.translate(
                  offset: Offset(slideValue, 0),
                  child: Opacity(opacity: entryValue, child: _buildLeading()),
                ),
                const SizedBox(width: 12),

                // Title block
                Expanded(
                  child: Transform.translate(
                    offset: Offset(slideValue * 0.7, 0),
                    child: Opacity(
                      opacity: entryValue,
                      child: _buildTitleBlock(),
                    ),
                  ),
                ),

                // Actions
                Transform.translate(
                  offset: Offset(-slideValue, 0),
                  child: Opacity(
                    opacity: entryValue,
                    child: _buildActions(),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Opacity(
                opacity: entryValue * 0.7,
                child: Transform.translate(
                  offset: Offset(slideValue * 0.5, 0),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (showBackButton) {
      return _AppBarIconButton(
        icon: Icons.arrow_back_ios_rounded,
        onTap: onBackTap ?? onBack,
        heroLabel: 'back',
      );
    }
    return _AppBarIconButton(
      icon: Icons.menu_rounded,
      onTap: onMenuTap,
      heroLabel: 'menu',
    );
  }

  Widget _buildActions() {
    final actionList = actions;
    if (actionList == null || actionList.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppBarIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
            heroLabel: 'notif',
          ),
          const SizedBox(width: 4),
          _AppBarIconButton(
            icon: Icons.search_rounded,
            onTap: () {},
            heroLabel: 'search',
          ),
        ],
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: actionList);
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: 0.5,
          ),
        ),
        // Shimmer underline
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 3,
          width: 40 + (30 * entryValue),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MidnightPitchTheme.electricBlue,
                Colors.white.withValues(alpha: 0.9),
                MidnightPitchTheme.electricBlue,
              ],
              stops: [
                shimmerValue.clamp(0.0, 0.5),
                (shimmerValue + 0.5).clamp(0.0, 1.0),
                (shimmerValue + 0.75).clamp(0.5, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4 + (0.4 * glowValue)),
                blurRadius: 6 + (4 * glowValue),
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated icon button for AppBar with hover/press effects
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String heroLabel;

  const _AppBarIconButton({
    required this.icon,
    this.onTap,
    required this.heroLabel,
  });

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.05).animate(
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
    return GestureDetector(
      onTapDown: (_) { setState(() => _isPressed = true); _ctrl.forward(); },
      onTapUp: (_) { setState(() => _isPressed = false); _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () { setState(() => _isPressed = false); _ctrl.reverse(); },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Transform.rotate(
              angle: _rotateAnim.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.1)
                      : MidnightPitchTheme.surfaceContainerLow.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPressed
                        ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.3)
                        : MidnightPitchTheme.ghostBorder,
                  ),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue
                      : MidnightPitchTheme.primaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hero AppBar specifically for player home with animated wave background
class PlayerHomeAppBar extends StatefulWidget {
  final String playerName;
  final String greeting;
  final double scrollOffset;
  final VoidCallback? onMenuTap;
  final bool isConnected;

  const PlayerHomeAppBar({
    super.key,
    required this.playerName,
    required this.greeting,
    this.scrollOffset = 0,
    this.onMenuTap,
    this.isConnected = false,
  });

  @override
  State<PlayerHomeAppBar> createState() => _PlayerHomeAppBarState();
}

class _PlayerHomeAppBarState extends State<PlayerHomeAppBar>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _shimmer2Controller;
  late Animation<double> _shimmerAnim;
  late Animation<double> _shimmer2Anim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shimmer2Controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmer2Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmer2Controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _shimmerController.dispose();
    _shimmer2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final parallax = widget.scrollOffset * 0.4;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 16),
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AppBarIconButton(
                    icon: Icons.menu_rounded,
                    onTap: widget.onMenuTap,
                    heroLabel: 'menu',
                  ),
                  const Spacer(),
                  _AppBarIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                    heroLabel: 'notif',
                  ),
                  const SizedBox(width: 8),
                  _AnimatedAvatar(
                    playerName: widget.playerName,
                    shimmerAnim: _shimmerAnim,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Transform.translate(
                offset: Offset(0, parallax.clamp(0.0, 10.0)),
                child: Opacity(
                  opacity: (1 - (widget.scrollOffset / 200)).clamp(0.0, 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.greeting,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _EnhancedShimmerUnderline(
                        shimmerAnim: _shimmerAnim,
                        shimmer2Anim: _shimmer2Anim,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.playerName,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.headingFontFamily,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.primaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ConnectionDot(isConnected: widget.isConnected),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedAvatar extends StatefulWidget {
  final String playerName;
  final Animation<double>? shimmerAnim;
  const _AnimatedAvatar({required this.playerName, this.shimmerAnim});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
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
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: MidnightPitchTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.playerName.isNotEmpty ? widget.playerName[0].toUpperCase() : 'P',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced shimmer underline with double-layer glow effect
class _EnhancedShimmerUnderline extends StatelessWidget {
  final Animation<double> shimmerAnim;
  final Animation<double> shimmer2Anim;
  final Widget child;

  const _EnhancedShimmerUnderline({
    required this.shimmerAnim,
    required this.shimmer2Anim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        AnimatedBuilder(
          animation: shimmerAnim,
          builder: (context, _) {
            // Primary shimmer - fast bright sweep
            final primaryStop = shimmerAnim.value;
            final primaryStop2 = (shimmerAnim.value + 0.35).clamp(0.0, 1.0);
            final primaryStop3 = (shimmerAnim.value + 0.55).clamp(0.0, 1.0);

            return Column(
              children: [
                // Outer glow layer
                AnimatedBuilder(
                  animation: shimmer2Anim,
                  builder: (context, _) {
                    final glowStop = shimmer2Anim.value;
                    final glowStop2 = (shimmer2Anim.value + 0.4).clamp(0.0, 1.0);
                    final glowStop3 = (shimmer2Anim.value + 0.6).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.0),
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.8),
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
                            MidnightPitchTheme.electricBlue.withValues(alpha: 0.0),
                          ],
                          stops: [
                            (glowStop - 0.1).clamp(0.0, 1.0),
                            glowStop.clamp(0.0, 1.0),
                            glowStop2.clamp(0.0, 1.0),
                            glowStop3.clamp(0.0, 1.0),
                            (glowStop3 + 0.1).clamp(0.0, 1.0),
                            (glowStop3 + 0.2).clamp(0.0, 1.0),
                            (glowStop3 + 0.35).clamp(0.0, 1.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Main shimmer line
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        MidnightPitchTheme.electricBlue,
                        Colors.white.withValues(alpha: 0.95),
                        MidnightPitchTheme.electricBlue,
                      ],
                      stops: [
                        primaryStop.clamp(0.0, 0.4),
                        primaryStop2.clamp(0.0, 1.0),
                        primaryStop3.clamp(0.0, 1.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Connection status dot - green glow when connected, red when not
class _ConnectionDot extends StatefulWidget {
  final bool isConnected;
  const _ConnectionDot({required this.isConnected});

  @override
  State<_ConnectionDot> createState() => _ConnectionDotState();
}

class _ConnectionDotState extends State<_ConnectionDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    final color = widget.isConnected
        ? MidnightPitchTheme.successGreen
        : MidnightPitchTheme.liveRed;
    final label = widget.isConnected ? 'Connected' : 'Offline';

    return Tooltip(
      message: label,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, _) {
          return Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _glowAnim.value * 0.8),
                  blurRadius: 6 + (4 * _glowAnim.value),
                  spreadRadius: 1 + (2 * _glowAnim.value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pulse dot widget
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat();
    _scaleAnim = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricBlue.withValues(alpha: _opacityAnim.value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.electricBlue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
