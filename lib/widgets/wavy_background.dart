import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// A premium, natively animated liquid wave background using Dark Colour System.
class WavyBackground extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final List<Color> waveColors;
  final double waveHeight;

  const WavyBackground({
    super.key,
    required this.child,
    this.backgroundColor = AppTheme.abyss,
    this.waveColors = const [
      AppTheme.cardinal,
      AppTheme.navy,
    ],
    this.waveHeight = 35,
  });

  @override
  State<WavyBackground> createState() => _WavyBackgroundState();
}

class _WavyBackgroundState extends State<WavyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Skewed Decorative "Speed Bars"
            _buildSpeedBar(
              width: 120,
              height: 200,
              offset: const Offset(-20, -20),
              rotation: -0.2,
              color: widget.waveColors[0].withValues(alpha: 0.05),
            ),
            _buildSpeedBar(
              width: 180,
              height: 250,
              offset: const Offset(200, -50),
              rotation: 0.15,
              color: widget.waveColors[1].withValues(alpha: 0.03),
            ),

            // 2. Solid Background with Curvy Clipping
            ClipPath(
              clipper: _LiquidClipperConcave(
                phase: _controller.value * 2 * math.pi,
                waveHeight: widget.waveHeight,
              ),
              child: Container(
                color: widget.backgroundColor,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 3. Multi-Layered Liquid Waves
            _buildWaveLayer(
              phaseOffset: math.pi,
              speedMultiplier: 0.8,
              opacity: 0.15,
              heightOffset: 4,
              color: widget.waveColors[1],
            ),
            _buildWaveLayer(
              phaseOffset: 0,
              speedMultiplier: 1.1,
              opacity: 0.3,
              heightOffset: 0,
              color: widget.waveColors[0],
            ),

            // 4. Main Content
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildWaveLayer({
    required double phaseOffset,
    required double speedMultiplier,
    required double opacity,
    required double heightOffset,
    required Color color,
  }) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _WavePainterConcave(
          phase: (_controller.value * 2 * math.pi * speedMultiplier) + phaseOffset,
          color: color.withValues(alpha: opacity),
          waveHeight: widget.waveHeight,
          heightOffset: heightOffset,
        ),
      ),
    );
  }

  Widget _buildSpeedBar({
    required double width,
    required double height,
    required Offset offset,
    required double rotation,
    required Color color,
  }) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _WavePainterConcave extends CustomPainter {
  final double phase;
  final Color color;
  final double waveHeight;
  final double heightOffset;

  _WavePainterConcave({
    required this.phase,
    required this.color,
    required this.waveHeight,
    required this.heightOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color,
          color.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, size.height - waveHeight * 2, size.width, waveHeight * 2))
      ..style = PaintingStyle.fill;

    final path = Path();
    final yBaseline = size.height + heightOffset;

    path.moveTo(0, yBaseline);

    for (double x = 0; x <= size.width; x += 1) {
      final relativeX = x / size.width;
      final y = yBaseline - 
                math.sin((relativeX * 1.5 * math.pi) + phase).abs() * waveHeight -
                math.cos((relativeX * 2.5 * math.pi) + phase * 0.4).abs() * (waveHeight / 2);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainterConcave oldDelegate) => oldDelegate.phase != phase;
}

class _LiquidClipperConcave extends CustomClipper<Path> {
  final double phase;
  final double waveHeight;

  _LiquidClipperConcave({required this.phase, required this.waveHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    final yBaseline = size.height;

    path.lineTo(0, yBaseline);

    for (double x = 0; x <= size.width; x += 1) {
      final relativeX = x / size.width;
      final y = yBaseline - 
                math.sin((relativeX * 1.5 * math.pi) + phase).abs() * waveHeight -
                math.cos((relativeX * 2.5 * math.pi) + phase * 0.4).abs() * (waveHeight / 2);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidClipperConcave oldClipper) => oldClipper.phase != phase;
}
