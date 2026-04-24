import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Redesigned wavy divider using FootHeroes brand tokens.
class WavyDivider extends StatefulWidget {
  final double height;
  final List<Color> colors;
  final Duration duration;

  const WavyDivider({
    super.key,
    this.height = 10,
    this.colors = const [
      AppTheme.cardinal,
      AppTheme.redMid,
    ],
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<WavyDivider> createState() => _WavyDividerState();
}

class _WavyDividerState extends State<WavyDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
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
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavyPainter(
              phase: _controller.value * 2 * math.pi,
              colors: widget.colors,
            ),
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double phase;
  final List<Color> colors;

  _WavyPainter({required this.phase, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i].withValues(alpha: 0.2 + (0.1 * i));
      final path = Path();
      
      final frequency = 1.5 + (i * 0.5);
      final layerPhase = phase + (i * math.pi / 3);
      final amplitude = size.height * (0.3 + (i * 0.1));
      final yCenter = size.height / 2;

      path.moveTo(0, yCenter);

      for (double x = 0; x <= size.width; x += 1) {
        final normalizedX = x / size.width;
        final y = yCenter + math.sin((normalizedX * frequency * math.pi) + layerPhase) * amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
    
    // Solid accent line
    final linePaint = Paint()
      ..color = colors[0].withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = x / size.width;
      final y = size.height / 2 + math.sin((normalizedX * 1.5 * math.pi) + phase) * (size.height * 0.3);
      linePath.lineTo(x, y);
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
