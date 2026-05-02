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
import '../../models/career_stats.dart';
import '../../core/router/app_router.dart';
import '../../widgets/motion_card.dart';
import '../../widgets/cards.dart';

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
                  ? Colors.white
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
                    ? Colors.white
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

  Widget _buildStatsCard(CareerStats stats) {
    final auth = ref.watch(authProvider);
    final name = auth.name ?? 'Player';

    // Build recent form results with day labels
    final matchState = ref.watch(matchProvider);
    final userId = ref.read(authProvider).userId;
    final formResults = <FormResult>[];
    final days = ['SUN', 'SAT', 'SUN', 'SAT', 'SUN'];
    int dayIdx = 0;

    for (final match in matchState.recentMatches) {
      if (match.status != 'completed') continue;
      final m = match;
      final isHome = m.homeTeamId == userId || (m.createdBy == userId && m.awayTeamId != userId);
      final isAway = m.awayTeamId == userId;
      final FormResultType type;
      if (m.homeScore == m.awayScore) {
        type = FormResultType.draw;
      } else {
        final userWon = (isHome && m.homeScore > m.awayScore) || (isAway && m.awayScore > m.homeScore);
        type = userWon ? FormResultType.win : FormResultType.loss;
      }
      formResults.add(FormResult(
        type: type,
        dayLabel: days.length > dayIdx ? days[dayIdx] : '',
      ));
      dayIdx++;
      if (formResults.length >= 5) break;
    }

    final wins = formResults.where((f) => f.type == FormResultType.win).length;
    final streakLabel = wins >= 3 ? '🔥 $wins WIN STREAK' : null;

    return Column(
      children: [
        // 1) Hero Card — Season Snapshot
        GestureDetector(
          onTap: () => context.go(AppRoutes.seasonStats),
          child: HeroCard(
            sectionLabel: 'SEASON SNAPSHOT ›',
            playerName: name,
            position: stats.primaryPosition.isNotEmpty ? stats.primaryPosition : 'Forward',
            league: stats.teamName ?? 'Sunday League',
            matchesPlayed: stats.appearances,
            avgRating: stats.avgRating,
            stats: [
              HeroStatData(label: 'GOALS', value: '${stats.goals}'),
              HeroStatData(label: 'ASSISTS', value: '${stats.assists}'),
              HeroStatData(label: 'WINS', value: '${stats.wins}'),
              HeroStatData(label: 'WIN RATE', value: '${stats.winRate.toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 2) Stat Grid — Glass + Accent
        Row(
          children: [
            Expanded(
              child: GlassCard(
                label: 'Goals',
                value: '${stats.goals}',
                trend: '+2 this month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AccentCard(
                label: 'Win Rate',
                value: '${stats.winRate.toStringAsFixed(0)}%',
                progress: stats.winRate / 100,
                subLabel: '${stats.wins} of ${stats.appearances} played',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Dark Card — Recent Form
        if (formResults.isNotEmpty)
          DarkCard(
            label: 'Recent Form',
            form: formResults,
            streak: streakLabel,
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
                      color: isSelected ? Colors.white : AppTheme.redMid,
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
