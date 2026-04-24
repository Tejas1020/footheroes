import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:footheroes/theme/app_theme.dart';

/// Premium shareable scorecard widget using Dark Colour System.
class ScorecardWidget extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String? topScorer;
  final String? manOfTheMatch;
  final String matchDate;
  final String format;

  const ScorecardWidget({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    this.topScorer,
    this.manOfTheMatch,
    this.matchDate = '',
    this.format = '11-a-side',
  });

  @override
  State<ScorecardWidget> createState() => ScorecardWidgetState();
}

class ScorecardWidgetState extends State<ScorecardWidget> {
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.redDeep,
          gradient: AppTheme.cardSurfaceGradient,
          border: Border.all(color: AppTheme.dividerColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding
            Text(
              'FOOTHEROES',
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 24,
                letterSpacing: 4,
                color: AppTheme.cardinal,
              ),
            ),
            const SizedBox(height: 32),

            // Match details
            Text(
              '${widget.matchDate.toUpperCase()}  •  ${widget.format.toUpperCase()}',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTeamColumn(widget.homeTeam, true),
                Container(
                  width: 100,
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.homeScore} - ${widget.awayScore}',
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 64,
                      height: 1,
                      color: AppTheme.parchment,
                    ),
                  ),
                ),
                _buildTeamColumn(widget.awayTeam, false),
              ],
            ),
            const SizedBox(height: 40),

            // Stats
            if (widget.topScorer != null) ...[
              _buildStatRow('TOP SCORER', widget.topScorer!),
              const SizedBox(height: 12),
            ],

            if (widget.manOfTheMatch != null) ...[
              _buildStatRow('MAN OF THE MATCH', widget.manOfTheMatch!, isHighlight: true),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 32),

            // Watermark
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 20, height: 1, color: AppTheme.cardinal.withValues(alpha: 0.3)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'FOOTHEROES.COM',
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 12,
                      color: AppTheme.gold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Container(width: 20, height: 1, color: AppTheme.cardinal.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String name, bool isHome) {
    final color = isHome ? AppTheme.cardinal : AppTheme.navy;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isHome ? 'HOME' : 'AWAY',
              style: AppTheme.dmSans.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 18,
              color: AppTheme.parchment,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.cardinal.withValues(alpha: 0.1)
            : AppTheme.elevatedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight 
              ? AppTheme.cardinal.withValues(alpha: 0.2) 
              : AppTheme.cardBorderColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.dmSans.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.gold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 16,
              color: isHighlight ? AppTheme.cardinal : AppTheme.parchment,
            ),
          ),
        ],
      ),
    );
  }
}