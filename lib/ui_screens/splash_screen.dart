import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  static const Color _red = MidnightPitchTheme.electricMint;
  static const Color _redDark = MidnightPitchTheme.electricMintDark;
  static const Color _redLight = MidnightPitchTheme.electricMintLight;

  late Animation<double> _ballScale;
  late Animation<double> _slashReveal;
  late Animation<double> _slashFill;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loaderProgress;
  late Animation<double> _bgReveal;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _setupAnimations();
    _mainController.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });
    _handleNavigation();
  }

  void _setupAnimations() {
    _ballScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.12),
    ));

    _slashReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.25, curve: Curves.easeOutExpo),
      ),
    );

    _slashFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.35, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeIn),
      ),
    );

    _loaderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _bgReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    await ref.read(authProvider.notifier).checkSession();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Red abstract elements on white background
          _buildAbstractBackground(),
          // Red diagonal slash fills in
          _buildSlashBackground(),
          // White abstract elements on the red slash area
          _buildWhiteOverlayOnSlash(),
          Column(
            children: [
              const Spacer(flex: 3),
              _buildBall(),
              const SizedBox(height: 48),
              _buildWordmark(),
              const Spacer(flex: 2),
              _buildLoader(),
              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbstractBackground() {
    return AnimatedBuilder(
      animation: _bgReveal,
      builder: (context, child) {
        return Opacity(
          opacity: _bgReveal.value,
          child: CustomPaint(
            painter: _AbstractBackgroundPainter(_red),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSlashBackground() {
    return AnimatedBuilder(
      animation: _slashReveal,
      builder: (context, child) {
        return ClipPath(
          clipper: _DiagonalSlashClipper(
            reveal: _slashReveal.value,
            fill: _slashFill.value,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [_redLight, _red, _redDark],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhiteOverlayOnSlash() {
    return AnimatedBuilder(
      animation: _slashFill,
      builder: (context, child) {
        if (_slashFill.value < 0.1) return const SizedBox.shrink();
        return ClipPath(
          clipper: _DiagonalSlashClipper(
            reveal: 1.0,
            fill: _slashFill.value,
          ),
          child: Opacity(
            opacity: (_slashFill.value * 1.5).clamp(0.0, 1.0),
            child: CustomPaint(
              painter: _WhiteSlashOverlayPainter(),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBall() {
    return AnimatedBuilder(
      animation: _ballScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _ballScale.value,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = 1.0 + _pulseController.value * 0.03;
              return Transform.scale(
                scale: _mainController.isCompleted ? pulse : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _red.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 90,
                    color: _red,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWordmark() {
    return AnimatedBuilder(
      animation: _titleOpacity,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _titleSlide,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _titleSlide.value),
              child: Opacity(
                opacity: _titleOpacity.value,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _slashFill,
                      builder: (context, child) {
                        final onRed = _slashFill.value > 0.3;
                        return Text(
                          'FOOT\nHEROES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rosnoc',
                            fontSize: 68,
                            fontWeight: FontWeight.w400,
                            color: onRed ? Colors.white : _red,
                            letterSpacing: 6,
                            height: 0.95,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _taglineOpacity,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _taglineSlide.value),
                          child: Opacity(
                            opacity: _taglineOpacity.value,
                            child: AnimatedBuilder(
                              animation: _slashFill,
                              builder: (context, child) {
                                final onRed = _slashFill.value > 0.3;
                                return Text(
                                  'THE RED PITCH IS YOURS',
                                  style: TextStyle(
                                    fontFamily: MidnightPitchTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: onRed
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : _red.withValues(alpha: 0.5),
                                    letterSpacing: 6,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoader() {
    return AnimatedBuilder(
      animation: _loaderProgress,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _slashFill,
          builder: (context, child) {
            final onRed = _slashFill.value > 0.3;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: onRed
                          ? Colors.white.withValues(alpha: 0.3)
                          : _red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loaderProgress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: onRed ? Colors.white : _red,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: (onRed ? Colors.white : _red)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Red abstract elements on the white background area.
class _AbstractBackgroundPainter extends CustomPainter {
  final Color red;

  _AbstractBackgroundPainter(this.red);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Large gradient circle — top-left
    final bigCirclePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [
          red.withValues(alpha: 0.25),
          red.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(-size.width * 0.15, -size.height * 0.1),
        radius: size.width * 0.6,
      ));
    canvas.drawCircle(
      Offset(-size.width * 0.15, -size.height * 0.1),
      size.width * 0.6,
      bigCirclePaint,
    );

    // 2. Ring — bottom-right
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.82),
      size.width * 0.22,
      Paint()
        ..color = red.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 3. Smaller ring — top-right
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.08),
      size.width * 0.08,
      Paint()
        ..color = red.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Hexagon — left side
    _drawHexagon(canvas, Offset(size.width * 0.08, size.height * 0.65),
        size.width * 0.08, red.withValues(alpha: 0.15), 2.0);

    // 5. Hexagon — right side
    _drawHexagon(canvas, Offset(size.width * 0.92, size.height * 0.4),
        size.width * 0.06, red.withValues(alpha: 0.12), 1.5);

    // 6. Diagonal accent lines
    final linePaint = Paint()
      ..color = red.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 5; i++) {
      final offset = i * size.width * 0.12;
      canvas.drawLine(
        Offset(size.width * 0.6 + offset, -20),
        Offset(size.width * 0.3 + offset, size.height + 20),
        linePaint,
      );
    }

    // 7. Scattered dots
    final dotPaint = Paint()..color = red.withValues(alpha: 0.2);
    for (final dot in [
      Offset(size.width * 0.15, size.height * 0.12),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.25, size.height * 0.85),
      Offset(size.width * 0.7, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.12, size.height * 0.42),
      Offset(size.width * 0.88, size.height * 0.68),
      Offset(size.width * 0.4, size.height * 0.92),
    ]) {
      canvas.drawCircle(dot, 4, dotPaint);
    }

    // 8. Large arc — bottom-left
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(-size.width * 0.3, size.height * 1.2),
        radius: size.width * 0.7,
      ),
      -0.4,
      0.8,
      false,
      Paint()
        ..color = red.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 9. Dashed circle — center
    _drawDashedCircle(
      canvas,
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.48),
        radius: size.width * 0.35,
      ),
      Paint()
        ..color = red.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
      24,
      6.0,
    );

    // 10. Filled hexagons
    _drawHexagonFilled(canvas,
        Offset(size.width * 0.18, size.height * 0.22), 12, red.withValues(alpha: 0.15));
    _drawHexagonFilled(canvas,
        Offset(size.width * 0.82, size.height * 0.88), 10, red.withValues(alpha: 0.18));

    // 11. Mid-left ring
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.35),
      size.width * 0.12,
      Paint()
        ..color = red.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 12. Large soft dots
    final bigDotPaint = Paint()..color = red.withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.5), 20, bigDotPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.9), 16, bigDotPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Color color, double stroke) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagonFilled(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDashedCircle(Canvas canvas, Rect rect, Paint paint, int segments, double gapAngle) {
    final step = (2 * math.pi) / segments;
    final sweep = step - (gapAngle * math.pi / 180);
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_AbstractBackgroundPainter oldDelegate) => red != oldDelegate.red;
}

/// White abstract elements painted ON TOP of the red slash area.
/// These only appear where the red diagonal fill has covered.
class _WhiteSlashOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const white = Colors.white;

    // 1. Large faint ring — top-right corner of slash
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.12),
      size.width * 0.18,
      Paint()
        ..color = white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 2. Small ring — bottom-left area
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.88),
      size.width * 0.1,
      Paint()
        ..color = white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Hexagon outline — mid-right
    _drawHexagon(canvas, Offset(size.width * 0.75, size.height * 0.55),
        size.width * 0.07, white.withValues(alpha: 0.12), 1.5);

    // 4. Hexagon outline — bottom-left
    _drawHexagon(canvas, Offset(size.width * 0.2, size.height * 0.75),
        size.width * 0.05, white.withValues(alpha: 0.1), 1.0);

    // 5. Filled hexagon accents
    _drawHexagonFilled(canvas,
        Offset(size.width * 0.9, size.height * 0.25), 14, white.withValues(alpha: 0.08));
    _drawHexagonFilled(canvas,
        Offset(size.width * 0.08, size.height * 0.95), 10, white.withValues(alpha: 0.1));

    // 6. Diagonal white lines (opposite angle to red ones)
    final linePaint = Paint()
      ..color = white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final offset = i * size.width * 0.15;
      canvas.drawLine(
        Offset(-20 + offset, size.height * 0.3),
        Offset(size.width * 0.4 + offset, -20),
        linePaint,
      );
    }

    // 7. Scattered white dots
    final dotPaint = Paint()..color = white.withValues(alpha: 0.15);
    for (final dot in [
      Offset(size.width * 0.82, size.height * 0.08),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.88, size.height * 0.4),
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.25, size.height * 0.92),
      Offset(size.width * 0.6, size.height * 0.65),
    ]) {
      canvas.drawCircle(dot, 3, dotPaint);
    }

    // 8. Large arc — top area
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 1.1, -size.height * 0.2),
        radius: size.width * 0.5,
      ),
      2.5,
      1.2,
      false,
      Paint()
        ..color = white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 9. Dashed circle — right area
    _drawDashedCircle(
      canvas,
      Rect.fromCircle(
        center: Offset(size.width * 0.78, size.height * 0.38),
        radius: size.width * 0.2,
      ),
      Paint()
        ..color = white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
      18,
      8.0,
    );

    // 10. Soft glow blobs
    final blobPaint = Paint()..color = white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.15), 30, blobPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.98), 24, blobPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Color color, double stroke) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagonFilled(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDashedCircle(Canvas canvas, Rect rect, Paint paint, int segments, double gapAngle) {
    final step = (2 * math.pi) / segments;
    final sweep = step - (gapAngle * math.pi / 180);
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteSlashOverlayPainter oldDelegate) => false;
}

class _DiagonalSlashClipper extends CustomClipper<Path> {
  final double reveal;
  final double fill;

  _DiagonalSlashClipper({required this.reveal, required this.fill});

  @override
  Path getClip(Size size) {
    if (reveal <= 0) return Path();

    final path = Path();

    if (fill <= 0) {
      final thickness = 6.0;
      final endX = size.width * reveal;
      final endY = size.height * reveal;
      path.moveTo(0, 0);
      path.lineTo(endX + thickness, endY - thickness);
      path.lineTo(endX, endY);
      path.lineTo(0, 0);
      path.close();
    } else {
      final progress = fill;
      path.moveTo(size.width, 0);
      path.lineTo(size.width * (1 - progress), 0);
      path.lineTo(0, size.height * progress);
      path.lineTo(0, size.height);
      path.lineTo(size.width * progress, size.height);
      path.lineTo(size.width, size.height * (1 - progress));
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(_DiagonalSlashClipper oldClipper) =>
      reveal != oldClipper.reveal || fill != oldClipper.fill;
}