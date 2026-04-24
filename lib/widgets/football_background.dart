import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// A premium, football-themed animated background using Dark Colour System.
class FootballBackground extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final List<Color>? colors;

  const FootballBackground({
    super.key,
    required this.child,
    this.backgroundColor = AppTheme.abyss,
    this.colors,
  });

  @override
  State<FootballBackground> createState() => _FootballBackgroundState();
}

class _FootballBackgroundState extends State<FootballBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColors = widget.colors ?? [
      AppTheme.redDeep,
      AppTheme.cardinal,
      AppTheme.navy,
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Scrolling Pitch Stripes
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(
                    painter: _PitchPainter(
                      progress: _controller.value,
                      color: AppTheme.redDeep,
                    ),
                  ),
                ),
              ),

              // 2. Animated Footballs
              _buildMovingFootball(
                size: 52,
                initialOffset: const Offset(-60, 45),
                speed: 1.0,
                color: effectiveColors[1], // cardinal
                opacity: 0.12,
              ),
              _buildMovingFootball(
                size: 38,
                initialOffset: const Offset(180, 25),
                speed: 0.7,
                color: effectiveColors[2], // navy
                opacity: 0.1,
              ),

              // 3. Grass Particles
              ...List.generate(6, (index) => _buildGrassParticle(index, effectiveColors[0])),

              // 4. Main Content (Always on top)
              widget.child,

              // 5. Jagged Grass Edge at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 20,
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    painter: _GrassEdgePainter(
                      phase: _controller.value * 2 * math.pi,
                      color: effectiveColors[0], // redDeep
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovingFootball({
    required double size,
    required Offset initialOffset,
    required double speed,
    required Color color,
    required double opacity,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalRange = screenWidth + size * 2;
    final xPos = (initialOffset.dx + (_controller.value * speed * totalRange)) % totalRange - size;
    
    return Positioned(
      left: xPos,
      top: initialOffset.dy + math.sin(_controller.value * 2 * math.pi + initialOffset.dx) * 15,
      child: Transform.rotate(
        angle: _controller.value * 2 * math.pi * 3,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.sports_soccer_rounded,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildGrassParticle(int index, Color color) {
    final random = math.Random(index);
    final screenWidth = MediaQuery.of(context).size.width;
    final speed = 0.5 + random.nextDouble();
    final xPos = (random.nextDouble() * screenWidth + (_controller.value * speed * 200)) % screenWidth;
    final yPos = 30 + random.nextDouble() * 80;

    return Positioned(
      left: xPos,
      top: yPos,
      child: Transform.rotate(
        angle: _controller.value * math.pi * 4,
        child: Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final double progress;
  final Color color;
  _PitchPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double stripeWidth = 70.0;
    double offset = (progress * stripeWidth * 2) % (stripeWidth * 2);

    for (double x = -stripeWidth * 2; x < size.width + stripeWidth; x += stripeWidth * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x + offset, 0, stripeWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) => oldDelegate.progress != progress;
}

class _GrassEdgePainter extends CustomPainter {
  final double phase;
  final Color color;

  _GrassEdgePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    double bladeWidth = 14.0;
    for (double x = 0; x <= size.width; x += bladeWidth) {
      double variation = math.cos((x / 10) + phase) * 10;
      path.lineTo(x + bladeWidth / 2, variation);
      path.lineTo(x + bladeWidth, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GrassEdgePainter oldDelegate) => oldDelegate.phase != phase;
}
