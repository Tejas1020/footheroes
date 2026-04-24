import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../models/match_model.dart';
import '../../../models/career_stats.dart';
import '../../../providers/player_profile_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../widgets/shareable_cards.dart';

/// Player Roster Profile screen — redesigned for a premium Dark Colour System experience.
class PlayerRosterProfileScreen extends ConsumerWidget {
  final String playerId;
  final VoidCallback? onBack;

  const PlayerRosterProfileScreen({
    super.key,
    required this.playerId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(playerId));

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          data: (profile) => _buildContent(context, ref, profile),
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cardinal)),
          error: (err, stack) => Center(child: Text('Error: $err', style: AppTheme.bodyReg)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PlayerProfileState profile) {
    final stats = profile.careerStats;
    final recentForm = profile.recentMatches.take(5).map((m) => _getMatchResult(m)).toList();
    final earnedBadges = _getEarnedBadges(stats);

    return Column(
      children: [
        _buildTopBar(context, stats?.primaryPosition ?? '??'),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unified Identity Card
                PlayerShareCard(
                  playerName: stats?.teamName ?? 'Player',
                  position: stats?.primaryPosition ?? 'ST',
                  goals: stats?.goals ?? 0,
                  assists: stats?.assists ?? 0,
                  appearances: stats?.appearances ?? 0,
                  avgRating: stats?.avgRating ?? 0.0,
                  cleanSheets: stats?.cleanSheets ?? 0,
                  recentForm: recentForm,
                  earnedBadges: earnedBadges,
                ),
                
                const SizedBox(height: 40),
                
                _buildSectionHeader('RATING TREND'),
                const SizedBox(height: 20),
                _buildRatingTrend(profile.last5Ratings),
                
                const SizedBox(height: 40),
                
                _buildSectionHeader('ROSTER ACTIONS'),
                const SizedBox(height: 20),
                _buildCompareButton(context),
                
                const SizedBox(height: 40),
                
                _buildSectionHeader('COACH NOTES'),
                const SizedBox(height: 20),
                _buildCoachNotes(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMatchResult(MatchModel match) {
    if (match.status != 'completed') return '-';
    if (match.homeScore > match.awayScore) return 'W';
    if (match.homeScore < match.awayScore) return 'L';
    return 'D';
  }

  List<IconData> _getEarnedBadges(CareerStats? stats) {
    if (stats == null) return [];
    final List<IconData> badges = [];
    if (stats.hatTricks > 0) badges.add(Icons.military_tech);
    if (stats.assists > 10) badges.add(Icons.assistant_rounded);
    if (stats.appearances > 50) badges.add(Icons.bolt_outlined);
    if (stats.goals > 20) badges.add(Icons.emoji_events_outlined);
    if (stats.motmAwards > 0) badges.add(Icons.workspace_premium_outlined);
    return badges;
  }

  Widget _buildTopBar(BuildContext context, String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.abyss,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorderColor)),
      ),
      child: Row(
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.parchment, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            'PLAYER ROSTER',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 18, letterSpacing: 1),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardinal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3)),
            ),
            child: Text(
              position,
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 12,
                color: AppTheme.cardinal,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingTrend(List<double> ratings) {
    if (ratings.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: AppTheme.standardCard,
        child: Text(
          'INSUFFICIENT DATA FOR TREND',
          style: AppTheme.labelSmall,
        ),
      );
    }

    final normalizedData = ratings.map((r) => (r / 10).clamp(0.0, 1.0)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.standardCard,
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _RatingTrendPainter(normalizedData),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EARLIER', style: AppTheme.labelSmall.copyWith(fontSize: 8)),
              Text('LATEST', style: AppTheme.labelSmall.copyWith(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.compare_arrows_rounded, size: 18),
        label: const Text('COMPARE WITH TEAMMATES'),
        style: AppTheme.primaryButton,
      ),
    );
  }

  Widget _buildCoachNotes() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppTheme.standardCard,
      child: TextField(
        maxLines: 4,
        style: AppTheme.bodyReg,
        decoration: InputDecoration(
          hintText: 'Add private scouting notes...',
          hintStyle: AppTheme.dmSans.copyWith(
            color: AppTheme.gold.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppTheme.elevatedSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        AppTheme.accentBar(),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.labelSmall,
        ),
      ],
    );
  }
}

class _RatingTrendPainter extends CustomPainter {
  final List<double> data;

  const _RatingTrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.cardinal
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = AppTheme.cardinal
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = AppTheme.cardinal.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.cardinal.withValues(alpha: 0.1),
          AppTheme.cardinal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stepX = size.width / (data.length > 1 ? data.length - 1 : 1);
    final padding = 10.0;

    if (data.length == 1) {
      final x = size.width / 2;
      final y = size.height - (data[0] * (size.height - padding * 2)) - padding;
      canvas.drawCircle(Offset(x, y), 8, dotGlowPaint);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      return;
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * (size.height - padding * 2)) - padding;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * (size.height - padding * 2)) - padding;
      canvas.drawCircle(Offset(x, y), 10, dotGlowPaint);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) => data != oldDelegate.data;
}
