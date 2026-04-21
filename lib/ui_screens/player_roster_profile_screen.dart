import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../widgets/glass_neu_decorations.dart';

/// Player Roster Profile screen — detailed player view with season stats,
/// rating trend, position history, comparison action, and coach notes.
class PlayerRosterProfileScreen extends StatelessWidget {
  final String playerId;
  final VoidCallback? onBack;

  const PlayerRosterProfileScreen({
    super.key,
    required this.playerId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.neuBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayerHero(),
                    const SizedBox(height: 24),
                    _buildSeasonStats(),
                    const SizedBox(height: 24),
                    _buildRatingTrend(),
                    const SizedBox(height: 24),
                    _buildPositionHistory(),
                    const SizedBox(height: 24),
                    _buildCompareButton(context),
                    const SizedBox(height: 24),
                    _buildCoachNotes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // TOP BAR
  // =============================================================================

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.neuLight,
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: MidnightPitchTheme.neuDark.withValues(alpha: 0.15),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.neuBase,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: MidnightPitchTheme.neuRaised,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: MidnightPitchTheme.electricBlue, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Marcus V.',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                  letterSpacing: -0.44,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _sharePlayerProfile(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.neuBase,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: MidnightPitchTheme.neuRaised,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.share, color: MidnightPitchTheme.mutedText, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPlayerOptions(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.neuBase,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: MidnightPitchTheme.neuRaised,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.more_vert, color: MidnightPitchTheme.mutedText, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // PLAYER HERO
  // =============================================================================

  Widget _buildPlayerHero() {
    return NeumorphicContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Neumorphic avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              shape: BoxShape.circle,
              border: Border.all(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: MidnightPitchTheme.neuLight,
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: MidnightPitchTheme.neuDark.withValues(alpha: 0.5),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'MV',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.electricBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Marcus V.',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.neuBase,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: MidnightPitchTheme.neuLight,
                            offset: const Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: MidnightPitchTheme.neuDark.withValues(alpha: 0.4),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'ST',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MidnightPitchTheme.electricBlue,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      color: MidnightPitchTheme.mutedText,
                    ),
                    children: const [
                      TextSpan(text: 'Reliability: '),
                      TextSpan(
                        text: '87%',
                        style: TextStyle(fontWeight: FontWeight.w700, color: MidnightPitchTheme.electricBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: MidnightPitchTheme.neuLight,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: MidnightPitchTheme.neuDark.withValues(alpha: 0.4),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
              border: Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: MidnightPitchTheme.electricBlue, size: 14),
                const SizedBox(width: 6),
                Text(
                  'IMPROVING',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.electricBlue,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // SEASON STATS GRID
  // =============================================================================

  Widget _buildSeasonStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            MidnightPitchTheme.sectionLabel('Season Stats'),
            Text(
              '2023/24 CAMPAIGN',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('Goals', '18'),
            _buildStatCard('Assists', '7'),
            _buildStatCard('Appearances', '24'),
            _buildStatCard('Avg Rating', '7.9', suffix: '/ 10'),
            _buildStatCard('Win Rate', '62%'),
            _buildStatCard('Clean Sheets', '0', dimmed: true),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {String? suffix, bool dimmed = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MidnightPitchTheme.neuRaised,
      ),
      child: Opacity(
        opacity: dimmed ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.primaryText,
                    letterSpacing: -1,
                  ),
                ),
                if (suffix != null)
                  Text(
                    suffix,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      color: MidnightPitchTheme.electricBlue,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // RATING TREND CHART
  // =============================================================================

  Widget _buildRatingTrend() {
    const data = [0.60, 0.75, 0.55, 0.90, 0.80, 0.85, 0.70, 0.95];
    const matchLabels = ['Match 1', 'Match 4', 'Match 8'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            MidnightPitchTheme.sectionLabel('Rating Trend'),
            Text(
              'LAST 8 MATCHES',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.neuBase.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFFFFF).withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      size: const Size(double.infinity, 160),
                      painter: _RatingTrendPainter(data),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: matchLabels
                        .map((label) => Text(
                              label,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 10,
                                color: MidnightPitchTheme.mutedText,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // POSITION HISTORY
  // =============================================================================

  Widget _buildPositionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Has played'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.electricBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: MidnightPitchTheme.surfaceDim, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'ST (32 apps)',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.surfaceDim,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.electricBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CAM (8 apps)',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlueDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =============================================================================
  // COMPARE BUTTON
  // =============================================================================

  Widget _buildCompareButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCompareOptions(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows, color: MidnightPitchTheme.electricBlueLight, size: 20),
            const SizedBox(width: 8),
            Text(
              'Compare with another player',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.electricBlueLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // COACH NOTES
  // =============================================================================

  Widget _buildCoachNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Your notes'),
        const SizedBox(height: 16),
        Stack(
          children: [
            TextField(
              maxLines: 5,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                color: MidnightPitchTheme.primaryText,
              ),
              decoration: InputDecoration(
                hintText: 'Add private notes about this player...',
                hintStyle: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: MidnightPitchTheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Icon(Icons.edit_note, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3), size: 20),
            ),
          ],
        ),
      ],
    );
  }

  void _sharePlayerProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Player profile link copied to clipboard'),
        backgroundColor: MidnightPitchTheme.electricBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlayerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: MidnightPitchTheme.electricBlue),
              title: const Text('Send Message', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messaging coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: MidnightPitchTheme.liveRed),
              title: const Text('Report Player', style: TextStyle(color: MidnightPitchTheme.liveRed)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Player',
              style: MidnightPitchTheme.titleMD.copyWith(
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people, color: MidnightPitchTheme.electricBlue),
              title: const Text('Compare with teammate', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a teammate to compare')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: MidnightPitchTheme.championGold),
              title: const Text('Compare with pro player', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pro comparison coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RATING TREND PAINTER
// =============================================================================

class _RatingTrendPainter extends CustomPainter {
  final List<double> data;

  const _RatingTrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = MidnightPitchTheme.electricBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = MidnightPitchTheme.electricBlue
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = MidnightPitchTheme.electricBlue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = MidnightPitchTheme.ghostBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final stepX = size.width / (data.length - 1);
    final padding = 12.0;

    // Draw vertical grid lines
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw connecting line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * (size.height - padding * 2)) - padding;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw dots with glow
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * (size.height - padding * 2)) - padding;
      canvas.drawCircle(Offset(x, y), 8, dotGlowPaint);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) => data != oldDelegate.data;
}

