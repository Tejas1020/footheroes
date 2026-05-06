import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Premium multi-layered abstract background — "Aurora Stadium".
/// Flowing ribbons, diamond pitch-grid, art-deco corners,
/// stadium-light rings, and glowing intersection nodes in warm brand tones.
class LuxuryBackground extends StatelessWidget {
  const LuxuryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _AuroraStadiumPainter()),
      ),
    );
  }
}

class _AuroraStadiumPainter extends CustomPainter {
  final math.Random _rng = math.Random(77);

  // ── Color helpers ──
  Color _orange(int a) => AppTheme.brandOrange.withAlpha(a);
  Color _gold(int a) => const Color(0xFFD4A74A).withAlpha(a);
  Color _dark(int a) => AppTheme.warmDark.withAlpha(a);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBaseGrain(canvas, size);
    _drawDiamondGrid(canvas, size);
    _drawFlowRibbons(canvas, size);
    _drawStadiumRings(canvas, size);
    _drawDiagonalEnergyLines(canvas, size);
    _drawIntersectionNodes(canvas, size);
    _drawCornerOrnaments(canvas, size);
    _drawFloatingHexagons(canvas, size);
  }

  // ── 1. Fine grain texture ──
  void _drawBaseGrain(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 200; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final r = 0.3 + _rng.nextDouble() * 0.7;
      final alpha = 4 + _rng.nextInt(10);
      paint.color = _rng.nextBool() ? _orange(alpha) : _dark(alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  // ── 2. Rotated diamond / pitch grid ──
  void _drawDiamondGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    final spacing = 32.0;
    final diagonal = spacing * 1.414;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      paint.color = _orange(6 + _rng.nextInt(4));
      final path = Path();
      for (double y = -size.height; y < size.height * 2; y += diagonal) {
        final cx = x + y * 0.5;
        final cy = y * 0.5;
        if (cx > -40 && cx < size.width + 40) {
          if (y == -size.height) {
            path.moveTo(cx, cy.clamp(-20, size.height + 20));
          } else {
            path.lineTo(cx, cy.clamp(-20, size.height + 20));
          }
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  // ── 3. Bold flowing bezier ribbons ──
  void _drawFlowRibbons(Canvas canvas, Size size) {
    // Thick ribbons
    for (int i = 0; i < 5; i++) {
      final w = 0.8 + _rng.nextDouble() * 1.8;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

      final startX = -40 + _rng.nextDouble() * 60;
      final endX = size.width + 40 - _rng.nextDouble() * 60;
      final startY = size.height * (0.05 + _rng.nextDouble() * 0.9);
      final endY = size.height * (0.05 + _rng.nextDouble() * 0.9);
      final cp1x = size.width * (0.15 + _rng.nextDouble() * 0.25);
      final cp1y = startY - 70 + _rng.nextDouble() * 140;
      final cp2x = size.width * (0.55 + _rng.nextDouble() * 0.25);
      final cp2y = endY - 70 + _rng.nextDouble() * 140;

      final path = Path()
        ..moveTo(startX, startY)
        ..cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);

      paint.color = _orange(22 + _rng.nextInt(28));
      canvas.drawPath(path, paint);
    }

    // Whisper-thin accent ribbons
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round;

      final startY = size.height * (0.08 + _rng.nextDouble() * 0.84);
      final midY = size.height * (0.12 + _rng.nextDouble() * 0.76);
      final endY = size.height * (0.08 + _rng.nextDouble() * 0.84);

      final path = Path()
        ..moveTo(-30, startY)
        ..cubicTo(
          size.width * 0.22, midY - 60 + _rng.nextDouble() * 120,
          size.width * 0.78, midY + 60 - _rng.nextDouble() * 120,
          size.width + 30, endY,
        );

      paint.color = _gold(28 + _rng.nextInt(22));
      canvas.drawPath(path, paint);
    }
  }

  // ── 4. Concentric stadium-light rings ──
  void _drawStadiumRings(Canvas canvas, Size size) {
    for (int i = 0; i < 6; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 + _rng.nextDouble() * 1.0
        ..strokeCap = StrokeCap.round;

      final cx = size.width * (0.1 + _rng.nextDouble() * 0.8);
      final cy = size.height * (0.1 + _rng.nextDouble() * 0.8);
      final radius = size.width * (0.25 + _rng.nextDouble() * 0.7);
      final startAngle = _rng.nextDouble() * math.pi * 2;
      final sweepAngle = math.pi * (0.3 + _rng.nextDouble() * 0.55);

      paint.color = _orange(12 + _rng.nextInt(16));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Double ring effect — offset arc slightly larger
      if (_rng.nextBool()) {
        paint.color = _orange(6 + _rng.nextInt(8));
        paint.strokeWidth = 0.4;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius + 14),
          startAngle + 0.3,
          sweepAngle * 0.8,
          false,
          paint,
        );
      }
    }
  }

  // ── 5. Bold diagonal energy sweeps ──
  void _drawDiagonalEnergyLines(Canvas canvas, Size size) {
    for (int i = 0; i < 6; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7 + _rng.nextDouble() * 1.4
        ..strokeCap = StrokeCap.round;

      final leftToRight = _rng.nextBool();
      double startX, startY, endX, endY;
      if (leftToRight) {
        startX = size.width * _rng.nextDouble() * 0.5;
        startY = -20;
        endX = size.width * (0.5 + _rng.nextDouble() * 0.5);
        endY = size.height + 20;
      } else {
        startX = size.width * (0.5 + _rng.nextDouble() * 0.5);
        startY = -20;
        endX = size.width * _rng.nextDouble() * 0.5;
        endY = size.height + 20;
      }

      final path = Path()..moveTo(startX, startY);
      final midX = (startX + endX) / 2 + (-30 + _rng.nextDouble() * 60);
      final midY = size.height * 0.5 + (-40 + _rng.nextDouble() * 80);
      path.quadraticBezierTo(midX, midY, endX, endY);

      paint.color = _orange(15 + _rng.nextInt(22));
      canvas.drawPath(path, paint);
    }
  }

  // ── 6. Glowing intersection / constellation nodes ──
  void _drawIntersectionNodes(Canvas canvas, Size size) {
    // Filled accent dots
    final fillPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final x = size.width * (0.05 + _rng.nextDouble() * 0.9);
      final y = size.height * (0.05 + _rng.nextDouble() * 0.9);
      final radius = 2.0 + _rng.nextDouble() * 4.5;

      fillPaint.color = _orange(50 + _rng.nextInt(50));
      fillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), radius, fillPaint);

      // Sharp core
      fillPaint.maskFilter = null;
      fillPaint.color = _orange(80 + _rng.nextInt(60));
      canvas.drawCircle(Offset(x, y), radius * 0.35, fillPaint);
    }

    // Hollow diamond markers
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final cx = size.width * (0.08 + _rng.nextDouble() * 0.84);
      final cy = size.height * (0.08 + _rng.nextDouble() * 0.84);
      final r = 6 + _rng.nextDouble() * 14;

      strokePaint.color = _gold(20 + _rng.nextInt(20));
      final diamond = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r * 0.6, cy)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r * 0.6, cy)
        ..close();
      canvas.drawPath(diamond, strokePaint);
    }
  }

  // ── 7. Art-deco corner ornaments ──
  void _drawCornerOrnaments(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Top-right — stepped geometric
    paint.color = _orange(22);
    _drawSteppedCorner(canvas, size, true, true, paint);
    // Bottom-left — stepped geometric
    paint.color = _orange(16);
    _drawSteppedCorner(canvas, size, false, false, paint);
    // Top-left — subtle
    paint.color = _orange(10);
    _drawSteppedCorner(canvas, size, true, false, paint);
    // Bottom-right — subtle
    paint.color = _orange(10);
    _drawSteppedCorner(canvas, size, false, true, paint);
  }

  void _drawSteppedCorner(
      Canvas canvas, Size size, bool top, bool right, Paint paint) {
    final offsetX = right ? size.width : 0.0;
    final dirX = right ? -1.0 : 1.0;
    final offsetY = top ? 0.0 : size.height;
    final dirY = top ? 1.0 : -1.0;

    final steps = [80.0, 140.0, 180.0, 205.0];
    final stepSize = 30.0;

    for (final stepLength in steps) {
      final path = Path()
        ..moveTo(offsetX, offsetY + dirY * stepLength)
        ..lineTo(offsetX + dirX * stepSize, offsetY + dirY * stepLength)
        ..lineTo(offsetX + dirX * stepSize, offsetY + dirY * (stepLength - 60));
      canvas.drawPath(path, paint);
    }

    // Corner accent triangle
    final trianglePath = Path()
      ..moveTo(offsetX, offsetY)
      ..lineTo(offsetX + dirX * 130, offsetY)
      ..lineTo(offsetX, offsetY + dirY * 90)
      ..close();
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _orange(top == right ? 14 : 8);
    canvas.drawPath(trianglePath, fillPaint);
  }

  // ── 8. Floating hexagon accents ──
  void _drawFloatingHexagons(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final cx = size.width * (0.15 + _rng.nextDouble() * 0.7);
      final cy = size.height * (0.15 + _rng.nextDouble() * 0.7);
      final r = 18 + _rng.nextDouble() * 35;

      paint.color = _orange(14 + _rng.nextInt(14));
      paint.strokeWidth = 0.5 + _rng.nextDouble() * 0.8;

      final hex = Path();
      for (int j = 0; j < 6; j++) {
        final angle = j * math.pi / 3;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (j == 0) {
          hex.moveTo(x, y);
        } else {
          hex.lineTo(x, y);
        }
      }
      hex.close();
      canvas.drawPath(hex, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraStadiumPainter old) => false;
}
