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
import '../../widgets/premium_app_bar.dart';
import '../../widgets/cards.dart';

/// Player Dashboard — Built on the FootHeroes 5-Card Design Language.
/// Follows Rhythm Rule: Light–Light–Dark–Light pattern.
class PlayerDashboard extends ConsumerStatefulWidget {
  const PlayerDashboard({super.key});

  @override
  ConsumerState<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends ConsumerState<PlayerDashboard> {
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    ref.read(matchProvider.notifier).loadMyActiveMatches(userId);
    ref.read(teamProvider.notifier).loadUserTeams(userId).then((_) {
      final team = ref.read(teamProvider).currentTeam;
      if (team != null) {
        ref.read(matchProvider.notifier).loadUpcomingMatches(team.teamId);
      }
    });
    ref.read(matchProvider.notifier).loadRecentMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: Stack(
        children: [
          // Page background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),

              // ① HERO CARD — Season Snapshot
              SliverToBoxAdapter(child: _buildHeroSection()),

              // ② GLASS + ACCENT row (2-column grid)
              SliverToBoxAdapter(child: _buildStatGrid()),

              // ③ BREAKDOWN CARD
              SliverToBoxAdapter(child: _buildBreakdown()),

              // ④ DARK CARD — Recent Form (contrast break)
              SliverToBoxAdapter(child: _buildFormCard()),

              // ⑤ LIVE / UPCOMING / HISTORY tabs
              SliverToBoxAdapter(child: _buildTabs()),
              SliverToBoxAdapter(child: _buildTabContent()),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: PremiumAppBar(
              title: 'DASHBOARD',
              scrollOffset: _scrollOffset,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ① HERO CARD
  // ============================================================
  Widget _buildHeroSection() {
    final statsAsync = ref.watch(currentUserStatsProvider);
    final auth = ref.watch(authProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: statsAsync.when(
        loading: () => const _LoadingCard(),
        error: (_, _) => const _LoadingCard(),
        data: (stats) {
          final name = auth.name ?? 'Player';
          final position = stats?.primaryPosition ?? 'Forward';
          final league = stats?.teamName ?? 'Sunday League';

          return HeroCard(
            sectionLabel: 'SEASON SNAPSHOT',
            playerName: name,
            position: position,
            league: league,
            matchesPlayed: stats?.appearances ?? 0,
            avgRating: stats?.avgRating,
            stats: [
              HeroStatData(label: 'GOALS', value: '${stats?.goals ?? 0}'),
              HeroStatData(label: 'ASSISTS', value: '${stats?.assists ?? 0}'),
              HeroStatData(label: 'WINS', value: '${stats?.wins ?? 0}'),
              HeroStatData(label: 'WIN RATE', value: '${(stats?.winRate ?? 0).toStringAsFixed(0)}%'),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ② GLASS + ACCENT GRID
  // ============================================================
  Widget _buildStatGrid() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: statsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (stats) {
          if (stats == null) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: AppTheme.cardGap),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      label: 'Goals',
                      value: '${stats.goals}',
                      trend: '+2 this month',
                    ),
                  ),
                  const SizedBox(width: AppTheme.colGap),
                  Expanded(
                    child: AccentCard(
                      label: 'Win Rate',
                      value: '${(stats.winRate).toInt()}%',
                      progress: stats.winRate / 100,
                      subLabel: '${stats.wins} of ${stats.appearances} played',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ③ BREAKDOWN CARD
  // ============================================================
  Widget _buildBreakdown() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: statsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (stats) {
          if (stats == null) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: AppTheme.cardGap),
              BreakdownCard(
                label: 'Match Breakdown',
                subtitle: 'Last ${stats.appearances} matches',
                stats: [
                  BreakdownStat(label: 'WINS', value: '${stats.wins}'),
                  BreakdownStat(label: 'DRAWS', value: '${stats.draws}'),
                  BreakdownStat(label: 'LOSSES', value: '${stats.appearances - stats.wins - stats.draws}'),
                  BreakdownStat(label: 'MOTM', value: '${stats.motmAwards}'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ④ DARK CARD — Form (contrast break)
  // ============================================================
  Widget _buildFormCard() {
    final matchState = ref.watch(matchProvider);
    final recent = matchState.recentMatches;

    if (recent.isEmpty) {
      return const SizedBox(height: AppTheme.cardGap);
    }

    final form = recent.take(5).map((m) {
      if (m.status != 'completed') return const FormResult(type: FormResultType.draw);
      final isHome = m.homeTeamId == ref.read(authProvider).userId;
      final score = isHome ? m.homeScore : m.awayScore;
      final oppScore = isHome ? m.awayScore : m.homeScore;
      if (score > oppScore) return const FormResult(type: FormResultType.win);
      if (score < oppScore) return const FormResult(type: FormResultType.loss);
      return const FormResult(type: FormResultType.draw);
    }).toList();

    final wins = form.where((f) => f.type == FormResultType.win).length;
    final streakLabel = wins >= 3 ? '🔥 $wins WIN STREAK' : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.cardGap),
          DarkCard(
            label: 'Recent Form',
            form: form,
            streak: streakLabel,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================
  Widget _buildTabs() {
    final tabs = ['LIVE', 'UPCOMING', 'HISTORY'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabs[i],
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppTheme.warmGrey,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 16,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildLiveSection();
      case 1: return _buildUpcomingSection();
      case 2: return _buildHistorySection();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildLiveSection() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
        child: EmptyStateCard(
          icon: Icons.sports_soccer_rounded,
          title: 'No live match',
          subtitle: 'Start scoring',
          ctaLabel: 'Start Match',
          onCta: () => context.go(AppRoutes.matchCreation),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: _LiveMatchRow(
        homeTeam: currentMatch.homeTeamName,
        awayTeam: currentMatch.awayTeamName ?? 'Opponent',
        homeScore: liveState.homeScore,
        awayScore: liveState.awayScore,
        timeDisplay: timerState.displayTime,
        onTap: () => context.push(AppRoutes.liveMatch, extra: currentMatch),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final matchState = ref.watch(matchProvider);
    final upcoming = matchState.upcomingMatches.where((m) => m.status == 'upcoming').toList();

    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
        child: EmptyStateCard(
          icon: Icons.event_rounded,
          title: 'No upcoming matches',
          subtitle: 'Plan your next match now',
          ctaLabel: 'Schedule Match',
          onCta: () => context.go(AppRoutes.matchCreation),
        ),
      );
    }

    return _MatchList(matches: upcoming, onTap: (m) => context.push(AppRoutes.matchDetail, extra: m));
  }

  Widget _buildHistorySection() {
    final matchState = ref.watch(matchProvider);
    final completed = matchState.recentMatches.where((m) => m.status == 'completed').toList();

    if (completed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
        child: EmptyStateCard(
          icon: Icons.history_rounded,
          title: 'No match history',
          subtitle: 'Finish matches to see stats',
        ),
      );
    }

    return _MatchList(
      matches: completed,
      onTap: (m) => context.push(AppRoutes.matchSummary, extra: m),
      showScore: true,
    );
  }
}

// ============================================================
// Support widgets
// ============================================================

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.heroRadius),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _LiveMatchRow extends StatelessWidget {
  final String homeTeam, awayTeam, timeDisplay;
  final int homeScore, awayScore;
  final VoidCallback onTap;

  const _LiveMatchRow({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.timeDisplay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.cardBorderColorLight, width: 0.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            _LiveBadge(time: timeDisplay),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TeamChip(name: homeTeam, isHome: true),
                Text(
                  '$homeScore - $awayScore',
                  style: AppTheme.dmSans.copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.parchment),
                ),
                _TeamChip(name: awayTeam, isHome: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String name;
  final bool isHome;
  const _TeamChip({required this.name, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: isHome ? AppTheme.heroGradient : AppTheme.awayDataGradient,
            shape: BoxShape.circle,
            boxShadow: isHome ? AppTheme.shieldShadow : AppTheme.awayShieldShadow,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.shield, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(name.toUpperCase(), style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.parchment)),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final String time;
  const _LiveBadge({required this.time});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandOrange.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppTheme.brandOrange.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.brandOrange.withAlpha(102 + (153 * _ctrl.value).round()),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text('LIVE  ${widget.time}', style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.brandOrange)),
        ],
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<MatchModel> matches;
  final void Function(MatchModel) onTap;
  final bool showScore;

  const _MatchList({required this.matches, required this.onTap, this.showScore = false});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final m = matches[i];
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.cardGap),
          child: _MatchTile(match: m, onTap: () => onTap(m), showScore: showScore),
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  final bool showScore;

  const _MatchTile({required this.match, required this.onTap, this.showScore = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.cardBorderColorLight, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.brandOrange.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${match.matchDate.day}',
                style: AppTheme.dmSans.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.brandOrange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.homeTeamName} vs ${match.awayTeamName}',
                    style: AppTheme.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.parchment),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(match.matchDate),
                    style: AppTheme.dmSans.copyWith(fontSize: 10, color: AppTheme.warmGrey),
                  ),
                ],
              ),
            ),
            if (showScore)
              Text(
                '${match.homeScore}-${match.awayScore}',
                style: AppTheme.dmSans.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.parchment),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.warmGrey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[d.weekday - 1]}, ${d.day}/${d.month}';
  }
}
