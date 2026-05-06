import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:footheroes/theme/app_theme.dart';

/// Redesigned PlayerRatingWidget using High Contrast System.
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
        height: 640,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Branding
            Text(
              'KIXXON',
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 20,
                letterSpacing: 4,
                color: AppTheme.brandOrange,
              ),
            ),

            // Player identity
            Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.heroCtaGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(),
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.playerName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 32,
                    color: AppTheme.parchment,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.position.toUpperCase(),
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            // Main Rating
            Column(
              children: [
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 110,
                    color: AppTheme.parchment,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStarBar(),
                const SizedBox(height: 4),
                Text(
                  'MATCH RATING',
                  style: AppTheme.labelSmall.copyWith(letterSpacing: 2, color: AppTheme.parchment),
                ),
              ],
            ),

            // Stats grid
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.cardBorderColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('⚽', widget.goals.toString(), 'GOALS'),
                  _buildStatItem('🅰️', widget.assists.toString(), 'ASSISTS'),
                  _buildStatItem('🟨', widget.yellowCards.toString(), 'YELLOW'),
                ],
              ),
            ),

            // Team and footer
            Column(
              children: [
                Text(
                  widget.teamName.toUpperCase(),
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 18,
                    color: AppTheme.parchment,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 20, height: 1, color: AppTheme.cardBorderColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'KIXXON.COM',
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 10,
                          color: AppTheme.mutedParchment,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Container(width: 20, height: 1, color: AppTheme.cardBorderColor),
                  ],
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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.playerName.isNotEmpty ? widget.playerName[0].toUpperCase() : '?';
  }

  Widget _buildStarBar() {
    final fullStars = widget.rating.floor().clamp(0, 5);
    final hasHalfStar = (widget.rating - fullStars) >= 0.5 && fullStars < 5;
    final emptyStars = (5 - fullStars - (hasHalfStar ? 1 : 0)).clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star_rounded, color: AppTheme.brandOrange, size: 28)),
        if (hasHalfStar) const Icon(Icons.star_half_rounded, color: AppTheme.brandOrange, size: 28),
        ...List.generate(emptyStars, (_) => Icon(Icons.star_outline_rounded, color: AppTheme.cardBorderColor, size: 28)),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 24,
            color: AppTheme.parchment,
          ),
        ),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(fontSize: 7, color: AppTheme.mutedParchment),
        ),
      ],
    );
  }
}