import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:footheroes/theme/app_theme.dart';
import '../models/formation_model.dart';
import '../models/match_roster_model.dart';

/// Football pitch CustomPainter with proper markings using Dark Colour System.
class FootballPitchPainter extends CustomPainter {
  final Color pitchColor;
  final Color lineColor;
  final bool showGrassPattern;
  final bool isFlipped; // true = away team view (GK at top)

  FootballPitchPainter({
    this.pitchColor = const Color(0xFF1B5E20),
    Color? lineColor,
    this.showGrassPattern = true,
    this.isFlipped = false,
  }) : lineColor = lineColor ?? AppTheme.parchment.withValues(alpha: 0.25);

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
      ..strokeWidth = 1.5;

    if (isFlipped) {
      // Flip canvas for away team view
      canvas.save();
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }

    _drawPitchMarkings(canvas, size, linePaint);

    if (isFlipped) {
      canvas.restore();
    }
  }

  void _drawGrassPattern(Canvas canvas, Size size, Paint paint) {
    // Draw base color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw alternating grass stripes
    final stripeWidth = size.width / 12;
    final color1 = pitchColor;
    final color2 = pitchColor.withValues(alpha: 0.85);

    for (int i = 0; i < 12; i++) {
      final rect = Rect.fromLTWH(
        i * stripeWidth,
        0,
        stripeWidth,
        size.height,
      );
      canvas.drawRect(rect, i.isEven ? (Paint()..color = color1) : (Paint()..color = color2));
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

    // Center line
    canvas.drawLine(
      Offset(padding, h / 2),
      Offset(w - padding, h / 2),
      paint,
    );

    // Center circle
    final centerCircleRadius = (h * 0.091).clamp(20.0, 50.0);
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      centerCircleRadius,
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      2.0,
      Paint()..color = paint.color.withValues(alpha: 0.5)..style = PaintingStyle.fill,
    );

    // Top penalty area
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
      2.0,
      Paint()..color = paint.color.withValues(alpha: 0.5)..style = PaintingStyle.fill,
    );

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

    // Bottom penalty area
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
      2.0,
      Paint()..color = paint.color.withValues(alpha: 0.5)..style = PaintingStyle.fill,
    );

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
    const cornerRadius = 10.0;
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
        showGrassPattern != oldDelegate.showGrassPattern ||
        isFlipped != oldDelegate.isFlipped;
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
  final Color? pitchColor;
  final Color? lineColor;
  final bool isHomeTeam;

  const FootballPitchWidget({
    super.key,
    required this.slots,
    this.onSlotTap,
    this.onSlotLongPress,
    this.width,
    this.height,
    this.showLabels = true,
    this.pitchColor,
    this.lineColor,
    this.isHomeTeam = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePitchColor = pitchColor ?? const Color(0xFF1B5E20);
    final effectiveLineColor = lineColor ?? AppTheme.parchment.withValues(alpha: 0.25);

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
                  pitchColor: effectivePitchColor,
                  lineColor: effectiveLineColor,
                  isFlipped: !isHomeTeam,
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
      left: x - 26,
      top: y - 32,
      child: GestureDetector(
        onTap: onSlotTap != null ? () => onSlotTap!(slot) : null,
        onLongPress: onSlotLongPress != null ? () => onSlotLongPress!(slot) : null,
        child: _PlayerPositionCard(
          slot: slot,
          isAssigned: isAssigned,
          showLabels: showLabels,
          isHomeTeam: isHomeTeam,
        ),
      ),
    );
  }
}

/// UCL-style player position card with brand-consistent colors.
class _PlayerPositionCard extends StatelessWidget {
  final PlayerPositionSlot slot;
  final bool isAssigned;
  final bool showLabels;
  final bool isHomeTeam;

  const _PlayerPositionCard({
    required this.slot,
    required this.isAssigned,
    required this.showLabels,
    required this.isHomeTeam,
  });

  @override
  Widget build(BuildContext context) {
    final positionColor = isHomeTeam ? AppTheme.cardinal : AppTheme.navy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isAssigned
                ? positionColor
                : AppTheme.abyss.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAssigned
                  ? AppTheme.parchment
                  : AppTheme.gold.withValues(alpha: 0.5),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: showLabels
                ? isAssigned && slot.assignedPlayerName != null
                    ? Text(
                        _getInitials(slot.assignedPlayerName!),
                        style: AppTheme.bebasDisplay.copyWith(
                          color: AppTheme.gold,
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        slot.positionLabel,
                        style: AppTheme.bebasDisplay.copyWith(
                          color: isAssigned ? AppTheme.gold : AppTheme.gold,
                          fontSize: 11,
                        ),
                      )
                : null,
          ),
        ),
        // Position label below
        if (showLabels)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.voidBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAssigned ? _getShortName(slot.assignedPlayerName!) : slot.positionLabel,
              style: AppTheme.dmSans.copyWith(
                color: isAssigned ? AppTheme.gold : AppTheme.gold,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _getShortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts.last.length > 8 ? parts.last.substring(0, 8) : parts.last;
    }
    return name.length > 8 ? name.substring(0, 8) : name;
  }
}

/// Beautiful lineup pitch using brand tokens.
class MatchLineupPitch extends StatelessWidget {
  final List<MatchRosterEntry> players;
  final bool isHomeTeam;
  final double? height;
  final String teamName;

  const MatchLineupPitch({
    super.key,
    required this.players,
    required this.isHomeTeam,
    this.height,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = isHomeTeam ? AppTheme.cardinal : AppTheme.navy;

    return Column(
      children: [
        // Team header
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              teamName.toUpperCase(),
              style: AppTheme.dmSans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: brandColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Pitch
        SizedBox(
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: AppTheme.cardBorder,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: FootballPitchPainter(
                      pitchColor: AppTheme.redDeep,
                      isFlipped: !isHomeTeam,
                    ),
                  ),
                  if (players.isEmpty)
                    Center(
                      child: Text(
                        'No players',
                        style: AppTheme.labelSmall,
                      ),
                    )
                  else
                    ..._buildPlayerMarkersStack(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${players.length} players',
            style: AppTheme.labelSmall.copyWith(color: brandColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlayerMarkersStack() {
    if (players.isEmpty) return [];

    final byPos = <String, List<MatchRosterEntry>>{};
    for (final p in players) {
      byPos.putIfAbsent(p.position.trim().toUpperCase(), () => []).add(p);
    }

    final markers = <Widget>[];
    const pitchH = 200.0;

    for (final entry in byPos.entries) {
      final label = entry.key;
      final group = entry.value;

      for (var i = 0; i < group.length; i++) {
        final player = group[i];
        final pos = rosterEntryPosition(player);
        final offset = group.length > 1 ? (i - (group.length - 1) / 2) * 0.07 : 0.0;
        final x = (pos[0] + offset).clamp(0.08, 0.92);
        final y = pos[1];

        markers.add(_PlayerPinMarker(
          key: ValueKey('pin_${player.playerId}'),
          player: player,
          x: x * 200,
          y: y * pitchH,
          positionLabel: label,
          isHomeTeam: isHomeTeam,
        ));
      }
    }

    return markers;
  }
}

class _PlayerPinMarker extends StatelessWidget {
  final MatchRosterEntry player;
  final double x;
  final double y;
  final String positionLabel;
  final bool isHomeTeam;

  const _PlayerPinMarker({
    super.key,
    required this.player,
    required this.x,
    required this.y,
    required this.positionLabel,
    required this.isHomeTeam,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = isHomeTeam ? AppTheme.cardinal : AppTheme.navy;
    return Positioned(
      left: x - 28,
      top: y - 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameTag(),
          Text('📍', style: TextStyle(fontSize: 20, color: brandColor)),
          _buildPositionChip(brandColor),
        ],
      ),
    );
  }

  Widget _buildNameTag() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.voidBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.parchment.withValues(alpha: 0.2)),
      ),
      child: Text(
        _shortName(player.playerName),
        style: AppTheme.dmSans.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.parchment,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPositionChip(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        positionLabel,
        style: AppTheme.bebasDisplay.copyWith(
          fontSize: 8,
          color: AppTheme.parchment,
        ),
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts.last.length > 8 ? parts.last.substring(0, 8) : parts.last;
    }
    return name.length > 8 ? name.substring(0, 8) : name;
  }
}

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
