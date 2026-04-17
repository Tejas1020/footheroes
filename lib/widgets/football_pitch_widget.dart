import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/formation_model.dart';

/// Football pitch CustomPainter with proper markings.
class FootballPitchPainter extends CustomPainter {
  final Color pitchColor;
  final Color lineColor;
  final bool showGrassPattern;

  FootballPitchPainter({
    this.pitchColor = const Color(0xFF2E7D32),
    this.lineColor = Colors.white,
    this.showGrassPattern = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pitchColor
      ..style = PaintingStyle.fill;

    // Draw pitch background with grass pattern
    if (showGrassPattern) {
      _drawGrassPattern(canvas, size, paint);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    // Draw pitch markings
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _drawPitchMarkings(canvas, size, linePaint);
  }

  void _drawGrassPattern(Canvas canvas, Size size, Paint paint) {
    // Draw base color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw alternating grass stripes
    final stripeWidth = size.width / 12;
    final darkerGreen = Paint()..color = const Color(0xFF27642A);
    final lighterGreen = Paint()..color = const Color(0xFF358A3A);

    for (int i = 0; i < 12; i++) {
      final rect = Rect.fromLTWH(
        i * stripeWidth,
        0,
        stripeWidth,
        size.height,
      );
      canvas.drawRect(rect, i.isEven ? darkerGreen : lighterGreen);
    }
  }

  void _drawPitchMarkings(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final padding = 8.0;

    // Outer boundary
    canvas.drawRect(
      Rect.fromLTWH(padding, padding, w - 2 * padding, h - 2 * padding),
      paint,
    );

    // Center line (horizontal in our case, since goal is at bottom)
    canvas.drawLine(
      Offset(padding, h / 2),
      Offset(w - padding, h / 2),
      paint,
    );

    // Center circle
    final centerCircleRadius = (h * 0.091).clamp(20.0, 50.0); // ~9.1% of height
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      centerCircleRadius,
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      3.0,
      paint..style = PaintingStyle.fill,
    );
    paint.style = PaintingStyle.stroke;

    // Top penalty area (attacking side)
    final penaltyAreaHeight = h * 0.165;
    final penaltyAreaWidth = w * 0.44;
    final penaltyAreaLeft = (w - penaltyAreaWidth) / 2;
    canvas.drawRect(
      Rect.fromLTWH(
        penaltyAreaLeft,
        padding,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Top goal area
    final goalAreaHeight = h * 0.082;
    final goalAreaWidth = w * 0.22;
    final goalAreaLeft = (w - goalAreaWidth) / 2;
    canvas.drawRect(
      Rect.fromLTWH(
        goalAreaLeft,
        padding,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Top penalty spot
    final penaltySpotY = padding + penaltyAreaHeight * 0.73;
    canvas.drawCircle(
      Offset(w / 2, penaltySpotY),
      3.0,
      paint..style = PaintingStyle.fill,
    );
    paint.style = PaintingStyle.stroke;

    // Top penalty arc
    final arcRect = Rect.fromCircle(
      center: Offset(w / 2, penaltySpotY),
      radius: centerCircleRadius,
    );
    canvas.drawArc(
      arcRect,
      0.6 * 3.14159,
      0.8 * 3.14159,
      false,
      paint,
    );

    // Bottom penalty area (defending/goal side)
    canvas.drawRect(
      Rect.fromLTWH(
        penaltyAreaLeft,
        h - padding - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      paint,
    );

    // Bottom goal area
    canvas.drawRect(
      Rect.fromLTWH(
        goalAreaLeft,
        h - padding - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      paint,
    );

    // Bottom penalty spot
    final bottomPenaltySpotY = h - padding - penaltyAreaHeight * 0.73;
    canvas.drawCircle(
      Offset(w / 2, bottomPenaltySpotY),
      3.0,
      paint..style = PaintingStyle.fill,
    );
    paint.style = PaintingStyle.stroke;

    // Bottom penalty arc
    final bottomArcRect = Rect.fromCircle(
      center: Offset(w / 2, bottomPenaltySpotY),
      radius: centerCircleRadius,
    );
    canvas.drawArc(
      bottomArcRect,
      -0.2 * 3.14159,
      0.8 * 3.14159,
      false,
      paint,
    );

    // Corner arcs
    final cornerRadius = 10.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(padding, padding), radius: cornerRadius),
      0,
      1.5708,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - padding, padding), radius: cornerRadius),
      1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(padding, h - padding), radius: cornerRadius),
      -1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - padding, h - padding), radius: cornerRadius),
      3.14159,
      1.5708,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant FootballPitchPainter oldDelegate) {
    return pitchColor != oldDelegate.pitchColor ||
        lineColor != oldDelegate.lineColor ||
        showGrassPattern != oldDelegate.showGrassPattern;
  }
}

/// Widget displaying a football pitch with player positions.
class FootballPitchWidget extends StatelessWidget {
  final List<PlayerPositionSlot> slots;
  final void Function(PlayerPositionSlot slot)? onSlotTap;
  final void Function(PlayerPositionSlot slot)? onSlotLongPress;
  final double? width;
  final double? height;
  final bool showLabels;
  final Color pitchColor;
  final Color lineColor;

  const FootballPitchWidget({
    super.key,
    required this.slots,
    this.onSlotTap,
    this.onSlotLongPress,
    this.width,
    this.height,
    this.showLabels = true,
    this.pitchColor = const Color(0xFF2E7D32),
    this.lineColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? (width != null ? width! * 1.52 : null),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pitchWidth = constraints.maxWidth;
          final pitchHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Pitch background
              CustomPaint(
                size: Size(pitchWidth, pitchHeight),
                painter: FootballPitchPainter(
                  pitchColor: pitchColor,
                  lineColor: lineColor,
                ),
              ),
              // Player positions
              ...slots.map((slot) => _buildPlayerSlot(
                slot,
                pitchWidth,
                pitchHeight,
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerSlot(PlayerPositionSlot slot, double width, double height) {
    final x = slot.xPercent * width;
    final y = slot.yPercent * height;
    final isAssigned = slot.isAssigned;

    return Positioned(
      left: x - 22,
      top: y - 22,
      child: GestureDetector(
        onTap: onSlotTap != null ? () => onSlotTap!(slot) : null,
        onLongPress: onSlotLongPress != null ? () => onSlotLongPress!(slot) : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isAssigned ? Colors.blue.shade700 : Colors.white.withValues(alpha: (0.8)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAssigned ? Colors.white : Colors.grey.shade400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: (0.3)),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: showLabels
                ? Text(
                    isAssigned
                        ? (slot.assignedPlayerName?.isNotEmpty ?? false)
                            ? slot.assignedPlayerName!.split(' ').last.substring(0, 3).toUpperCase()
                            : slot.positionLabel
                        : slot.positionLabel,
                    style: TextStyle(
                      color: isAssigned ? Colors.white : Colors.grey.shade700,
                      fontSize: isAssigned ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// GlobalKey holder for capturing pitch widget as image.
class PitchCaptureKey {
  final GlobalKey key = GlobalKey();

  Future<ui.Image?> captureImage() async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 2.0);
    } catch (_) {
      return null;
    }
  }

  Future<ByteData?> capturePngBytes() async {
    final image = await captureImage();
    if (image == null) return null;
    return await image.toByteData(format: ui.ImageByteFormat.png);
  }
}

/// Widget wrapper for capturing pitch as image.
class CapturablePitchWidget extends StatelessWidget {
  final Widget child;
  final GlobalKey boundaryKey;

  const CapturablePitchWidget({
    super.key,
    required this.child,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: child,
    );
  }
}