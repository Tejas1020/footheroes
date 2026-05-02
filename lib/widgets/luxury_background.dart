import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Abstract luxury geometric background — flowing lines, arcs, and accent
/// shapes in warm brand tones across the full canvas.
class LuxuryBackground extends StatelessWidget {
  const LuxuryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _LuxuryPainter()),
      ),
    );
  }
}

class _LuxuryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);

    _drawBoldFlowLines(canvas, size, rng);
    _drawGeometricDots(canvas, size, rng);
    _drawLargeArcs(canvas, size, rng);
    _drawCornerTriangles(canvas, size);
  }

  // ── Bold sweeping bezier flow lines ──
  void _drawBoldFlowLines(Canvas canvas, Size size, math.Random rng) {
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      final startY = size.height * (0.1 + rng.nextDouble() * 0.8);
      final midY = size.height * (0.15 + rng.nextDouble() * 0.7);
      final endY = size.height * (0.1 + rng.nextDouble() * 0.8);

      final path = Path()
        ..moveTo(-30, startY)
        ..cubicTo(
          size.width * 0.2, midY - 80 + rng.nextDouble() * 160,
          size.width * 0.8, midY + 80 - rng.nextDouble() * 160,
          size.width + 30, endY,
        );

      paint.color = AppTheme.brandOrange.withAlpha(30 + rng.nextInt(30));
      canvas.drawPath(path, paint);
    }
  }

  // ── Cluster dots, geometric placement ──
  void _drawGeometricDots(Canvas canvas, Size size, math.Random rng) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Filled dots
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble() < 0.5
          ? 20 + rng.nextDouble() * size.width * 0.3
          : size.width * 0.7 + rng.nextDouble() * size.width * 0.28;
      final y = rng.nextDouble() < 0.5
          ? 20 + rng.nextDouble() * size.height * 0.25
          : size.height * 0.75 + rng.nextDouble() * size.height * 0.22;
      final radius = 1.5 + rng.nextDouble() * 3.5;

      fillPaint.color = AppTheme.brandOrange.withAlpha(35 + rng.nextInt(45));
      canvas.drawCircle(Offset(x, y), radius, fillPaint);
    }

    // Hollow accent rings (2-3)
    for (int i = 0; i < 3; i++) {
      final cx = size.width * (0.15 + rng.nextDouble() * 0.7);
      final cy = size.height * (0.15 + rng.nextDouble() * 0.7);
      final radius = 20 + rng.nextDouble() * 60;

      strokePaint.color = AppTheme.brandOrange.withAlpha(15 + rng.nextInt(15));
      canvas.drawCircle(Offset(cx, cy), radius, strokePaint);
    }
  }

  // ── Large elegant arcs ──
  void _drawLargeArcs(Canvas canvas, Size size, math.Random rng) {
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;

      final centerX = size.width * (0.2 + rng.nextDouble() * 0.6);
      final centerY = size.height * (0.2 + rng.nextDouble() * 0.6);
      final radius = size.width * (0.3 + rng.nextDouble() * 0.6);

      paint.color = AppTheme.brandOrange.withAlpha(18 + rng.nextInt(22));

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        rng.nextDouble() * math.pi * 2,
        math.pi * (0.4 + rng.nextDouble() * 0.4),
        false,
        paint,
      );
    }
  }

  // ── Corner triangle accents ──
  void _drawCornerTriangles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Top-right triangle
    paint.color = AppTheme.brandOrange.withAlpha(18);
    final topRight = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - 120, 0)
      ..lineTo(size.width, 80)
      ..close();
    canvas.drawPath(topRight, paint);

    // Bottom-left triangle
    paint.color = AppTheme.brandOrange.withAlpha(12);
    final bottomLeft = Path()
      ..moveTo(0, size.height)
      ..lineTo(80, size.height)
      ..lineTo(0, size.height - 60)
      ..close();
    canvas.drawPath(bottomLeft, paint);
  }

  @override
  bool shouldRepaint(_LuxuryPainter old) => false;
}
