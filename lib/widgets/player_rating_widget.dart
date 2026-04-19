import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../theme/midnight_pitch_theme.dart';

/// Instagram story-ready player rating card.
/// 9:16 aspect ratio for sharing.
class PlayerRatingWidget extends StatefulWidget {
  final String playerName;
  final String position;
  final String teamName;
  final double rating;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;

  const PlayerRatingWidget({
    super.key,
    required this.playerName,
    required this.position,
    required this.teamName,
    required this.rating,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  @override
  State<PlayerRatingWidget> createState() => PlayerRatingWidgetState();
}

class PlayerRatingWidgetState extends State<PlayerRatingWidget> {
  final GlobalKey _boundaryKey = GlobalKey();

  /// Capture the widget as PNG bytes for sharing.
  Future<Uint8List?> captureAsPng() async {
    try {
      final boundary = _boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        width: 360,
        height: 640, // 9:16 aspect ratio
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MidnightPitchTheme.surfaceDim,
              MidnightPitchTheme.surfaceContainerLow,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Branding
            Text(
              'FOOTHEROES',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: MidnightPitchTheme.electricBlue,
              ),
            ),

            // Player info
            Column(
              children: [
                // Avatar circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        MidnightPitchTheme.electricBlue,
                        MidnightPitchTheme.electricBlueDark,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFC107),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.playerName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.position.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MidnightPitchTheme.secondaryText,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            // Rating
            Column(
              children: [
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFC107),
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStarBar(),
              ],
            ),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('⚽', widget.goals.toString()),
                  _buildStatItem('🅰️', widget.assists.toString()),
                  _buildStatItem('🟨', widget.yellowCards.toString()),
                  _buildStatItem('🟥', widget.redCards.toString()),
                ],
              ),
            ),

            // Team and watermark
            Column(
              children: [
                Text(
                  widget.teamName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'footheroes.com',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final parts = widget.playerName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return widget.playerName.isNotEmpty ? widget.playerName[0].toUpperCase() : '?';
  }

  Widget _buildStarBar() {
    final fullStars = widget.rating.floor();
    final hasHalfStar = (widget.rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Color(0xFFFFC107), size: 24)),
        if (hasHalfStar) const Icon(Icons.star_half, color: Color(0xFFFFC107), size: 24),
        ...List.generate(emptyStars, (_) => Icon(Icons.star_border, color: MidnightPitchTheme.mutedText, size: 24)),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
      ],
    );
  }
}