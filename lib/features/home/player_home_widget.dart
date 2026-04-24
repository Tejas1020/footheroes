import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/live_match_provider.dart';
import '../../providers/match_timer_provider.dart';
import '../../providers/player_stats_provider.dart';
import '../../models/match_model.dart';
import '../../core/router/app_router.dart';
import '../../widgets/motion_card.dart';

/// Player Home Widget — Full Visual Upgrade per spec.
class PlayerHomeWidget extends ConsumerStatefulWidget {
  const PlayerHomeWidget({super.key});

  @override
  ConsumerState<PlayerHomeWidget> createState() => _PlayerHomeWidgetState();
}

class _PlayerHomeWidgetState extends ConsumerState<PlayerHomeWidget>
    with TickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Live, 1 = Upcoming, 2 = History

  late AnimationController _entryController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _staggerAnimations = List.generate(8, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            i * 0.08,
            0.4 + (i * 0.08),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) return;

    ref.read(matchProvider.notifier).loadMyActiveMatches(userId);
    ref.read(teamProvider.notifier).loadUserTeams(userId).then((_) {
      final teamState = ref.read(teamProvider);
      final currentTeam = teamState.currentTeam;
      if (currentTeam != null) {
        ref
            .read(matchProvider.notifier)
            .loadUpcomingMatches(currentTeam.teamId);
      }
    });
    ref.read(matchProvider.notifier).loadRecentMatches();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 20),
            // QUICK ACTIONS STRIP
            Opacity(
              opacity: _staggerAnimations[1].value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _staggerAnimations[1].value)),
                child: _buildQuickActions(),
              ),
            ),

            // SEASON SNAPSHOT CARD
            Opacity(
              opacity: _staggerAnimations[2].value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - _staggerAnimations[2].value)),
                child: _buildSeasonStats(),
              ),
            ),

            // TABS
            Opacity(
              opacity: _staggerAnimations[3].value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _staggerAnimations[3].value)),
                child: _buildTabBar(),
              ),
            ),

            // TAB CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildTabContent(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // QUICK ACTIONS — Horizontal scroll, no clipping
  // ─────────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        clipBehavior: Clip.none,
        children: [
          // "New Match" — border 1.5px #C1121F, bg transparent, icon+text #C1121F, radius 20px
          _buildActionChip(
            icon: Icons.add_circle_rounded,
            label: 'New Match',
            isPrimaryOutline: true,
            onTap: () => context.go(AppRoutes.matchCreation),
          ),
          const SizedBox(width: 10),
          // "Tournaments" — GradientA bg, text+icon #F5ECD8, radius 20px, shadow
          _buildActionChip(
            icon: Icons.emoji_events_rounded,
            label: 'Tournaments',
            isGradient: true,
            onTap: () => context.go(AppRoutes.tournaments),
          ),

          const SizedBox(width: 10),
          _buildActionChip(
            icon: Icons.leaderboard_rounded,
            label: 'Leaderboard',
            isSecondaryOutline: true,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimaryOutline = false,
    bool isSecondaryOutline = false,
    bool isGradient = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: isGradient ? AppTheme.heroCtaGradient : null,
          color: isGradient ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isPrimaryOutline
              ? Border.all(color: AppTheme.cardinal, width: 1.5)
              : isSecondaryOutline
              ? Border.all(color: AppTheme.redMid, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isGradient
                  ? AppTheme.parchment
                  : isPrimaryOutline
                  ? AppTheme.cardinal
                  : AppTheme.redMid,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGradient
                    ? AppTheme.parchment
                    : isPrimaryOutline
                    ? AppTheme.cardinal
                    : AppTheme.redMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SEASON SNAPSHOT CARD
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSeasonStats() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: statsAsync.when(
        loading: () => _buildLoadingCard(),
        error: (err, stack) => _buildEmptyStats(),
        data: (stats) {
          if (stats == null) return _buildEmptyStats();
          return _buildStatsCard(stats);
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      decoration: AppTheme.standardCard,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.cardinal),
      ),
    );
  }

  Widget _buildEmptyStats() {
    return MotionCard(
      staggerIndex: 0,
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: AppTheme.gold.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No Stats Yet',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Play matches to see your stats here',
            style: AppTheme.bodyReg.copyWith(
              fontSize: 12,
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(dynamic stats) {
    return Column(
      children: [
        // Main Season Snapshot card with GradientB + radial glow
        Stack(
          children: [
            Container(
              decoration: AppTheme.standardCard,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: label + rating badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SEASON SNAPSHOT label with accent bar
                          Row(
                            children: [
                              AppTheme.accentBar(),
                              const SizedBox(width: 8),
                              Text(
                                'SEASON SNAPSHOT',
                                style: AppTheme.dmSans.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.gold,
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.appearances} Matches Played',
                            style: AppTheme.dmSans.copyWith(
                              fontSize: 12,
                              color: AppTheme.mutedParchment,
                            ),
                          ),
                        ],
                      ),
                      // Rating badge: GradientA bg, shadow, star + number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroCtaGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.badgeShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stats.avgRating.toStringAsFixed(1),
                              style: AppTheme.bebasDisplay.copyWith(
                                fontSize: 18,
                                color: AppTheme.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Main stat boxes: Goals / Assists / Wins / Win Rate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeroStatBox(
                        '${stats.goals}',
                        'GOALS',
                        Icons.sports_soccer_rounded,
                      ),
                      _buildHeroStatBox(
                        '${stats.assists}',
                        'ASSISTS',
                        Icons.assistant_navigation,
                      ),
                      _buildHeroStatBox(
                        '${stats.wins}',
                        'WINS',
                        Icons.emoji_events_rounded,
                      ),
                      _buildHeroStatBox(
                        '${stats.winRate.toStringAsFixed(0)}%',
                        'WIN RATE',
                        Icons.trending_up_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // GradientF radial glow overlay
            Positioned.fill(
              child: Container(decoration: AppTheme.radialGlowOverlay),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Secondary stats row: Draws / Losses / CS / Yellow / Red
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: AppTheme.secondaryRowDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStat('${stats.draws}', 'DRAWS', AppTheme.parchment),
              _buildCompactStat('${stats.losses}', 'LOSSES', AppTheme.cardinal),
              _buildCompactStat('${stats.cleanSheets}', 'CS', AppTheme.gold),
              _buildCompactStat(
                '${stats.yellowCards}',
                'YELLOW',
                AppTheme.redMid,
              ),
              _buildCompactStat('${stats.redCards}', 'RED', AppTheme.cardinal),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recent Form
        _buildRecentForm(stats),
      ],
    );
  }

  Widget _buildHeroStatBox(String value, String label, IconData icon) {
    return Column(
      children: [
        // Icon circle: 38px, GradientA opacity 0.8, icon #F5ECD8
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppTheme.heroCtaGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.gold, size: 18),
        ),
        const SizedBox(height: 8),
        // Top edge: 2px GradientA line
        Container(
          width: 24,
          height: 2,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroCtaGradient,
            borderRadius: BorderRadius.all(Radius.circular(1)),
          ),
        ),
        const SizedBox(height: 6),
        // Number: Bebas Neue 30sp #C1121F
        Text(
          value,
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 30,
            color: AppTheme.cardinal,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        // Label: DM Sans 10sp #669BBC uppercase
        Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 22,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentForm(dynamic stats) {
    final matchState = ref.watch(matchProvider);
    final userId = ref.read(authProvider).userId;

    final results = <String>[];
    for (final match in matchState.recentMatches) {
      if (match.status != 'completed') continue;
      final m = match;
      final isHome =
          m.homeTeamId == userId ||
          (m.createdBy == userId && m.awayTeamId != userId);
      final isAway = m.awayTeamId == userId;
      if (m.homeScore == m.awayScore) {
        results.add('D');
      } else {
        final userWon =
            (isHome && m.homeScore > m.awayScore) ||
            (isAway && m.awayScore > m.homeScore);
        results.add(userWon ? 'W' : 'L');
      }
      if (results.length >= 5) break;
    }

    if (results.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'RECENT FORM',
          style: AppTheme.dmSans.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: results.map((r) {
            final bg = r == 'W'
                ? const Color(0xFF2E7D32)
                : r == 'L'
                ? AppTheme.cardinal
                : const Color(0xFFF9A825);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  r,
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 15,
                    color: r == 'D' ? AppTheme.voidBg : AppTheme.parchment,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TABS — Container #1F000D bg, radius 30px, border #C1121F15
  // ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = ['LIVE', 'UPCOMING', 'HISTORY'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(30),
          border: AppTheme.cardBorderLight,
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: AppTheme.heroCtaGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x50C1121F),
                              blurRadius: 12,
                            ),
                          ],
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? AppTheme.parchment : AppTheme.redMid,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB CONTENT
  // ─────────────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildLiveSection();
      case 1:
        return _buildUpcomingSection();
      case 2:
        return _buildHistorySection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLiveSection() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) {
      return _buildEmptyState(
        Icons.sports_soccer_rounded,
        'NO LIVE MATCH',
        'Start or join a match to see it here',
      );
    }

    return LiveMatchCard(
      homeTeam: currentMatch.homeTeamName,
      awayTeam: currentMatch.awayTeamName ?? 'Opponent',
      homeScore: liveState.homeScore,
      awayScore: liveState.awayScore,
      timeDisplay: timerState.displayTime,
      isLive: true,
      onTap: () => context.push(AppRoutes.liveMatch, extra: currentMatch),
    );
  }

  Widget _buildUpcomingSection() {
    final matchState = ref.watch(matchProvider);
    final upcoming = matchState.upcomingMatches
        .where((m) => m.status == 'upcoming')
        .toList();

    if (upcoming.isEmpty) {
      return _buildEmptyState(
        Icons.event_outlined,
        'NO UPCOMING MATCHES',
        'Schedule a match to get started',
      );
    }

    return Column(children: upcoming.map((m) => _buildMatchRow(m)).toList());
  }

  Widget _buildHistorySection() {
    final matchState = ref.watch(matchProvider);
    final completed = matchState.recentMatches
        .where((m) => m.status == 'completed')
        .toList();

    if (completed.isEmpty) {
      return _buildEmptyState(
        Icons.history_rounded,
        'NO HISTORY',
        'Completed matches will appear here',
      );
    }

    return Column(
      children: completed
          .map((m) => _buildMatchRow(m, isHistory: true))
          .toList(),
    );
  }

  Widget _buildMatchRow(MatchModel m, {bool isHistory = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MotionCard(
        onTap: () => context.push(
          isHistory ? AppRoutes.matchSummary : AppRoutes.matchDetail,
          extra: m,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${m.matchDate.day}',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.homeTeamName} vs ${m.awayTeamName}',
                    style: AppTheme.bodyBold,
                  ),
                  Text(
                    _formatDate(m.matchDate),
                    style: AppTheme.labelSmall.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            if (isHistory)
              Text(
                '${m.homeScore}-${m.awayScore}',
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 18,
                  color: AppTheme.cardinal,
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.gold),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
          Text(sub, style: AppTheme.labelSmall),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
