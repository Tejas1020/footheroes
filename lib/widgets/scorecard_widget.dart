import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Premium shareable scorecard widget.
/// Captured via RepaintBoundary for sharing.
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding
            Text(
              'FOOTHEROES',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),

            // Match date and format
            Text(
              '${widget.matchDate} • ${widget.format}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 16),

            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTeamColumn(widget.homeTeam, true),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.homeScore} - ${widget.awayScore}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ),
                _buildTeamColumn(widget.awayTeam, false),
              ],
            ),
            const SizedBox(height: 24),

            // Top scorer
            if (widget.topScorer != null) ...[
              _buildStatRow('TOP SCORER', widget.topScorer!),
              const SizedBox(height: 12),
            ],

            // Man of the match
            if (widget.manOfTheMatch != null) ...[
              _buildStatRow('MAN OF THE MATCH', widget.manOfTheMatch!, isHighlight: true),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 24),

            // Watermark
            Text(
              'footheroes.com',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String name, bool isHome) {
    return Expanded(
      child: Column(
        children: [
          Text(
            isHome ? 'HOME' : 'AWAY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFFFC107).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isHighlight ? const Color(0xFFFFC107) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}