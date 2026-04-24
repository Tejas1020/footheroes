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
import '../../services/whistle_service.dart';
import '../../widgets/premium_app_bar.dart';
import '../../widgets/motion_card.dart';

/// Player Dashboard - Redesigned for Dark Colour System.
class PlayerDashboard extends ConsumerStatefulWidget {
  const PlayerDashboard({super.key});

  @override
  ConsumerState<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends ConsumerState<PlayerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _scrollController.dispose();
    _tabController.dispose();
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
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for AppBar
              
              // Season Snapshot Hero
              SliverToBoxAdapter(child: _buildSeasonSnapshot()),

              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions()),

              // Tab Bar
              SliverToBoxAdapter(child: _buildTabBar()),

              // Tab Content
              SliverToBoxAdapter(child: _buildTabContent()),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          // Premium AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
  // SEASON SNAPSHOT - Hero Gradient Card
  // ============================================================

  Widget _buildSeasonSnapshot() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              Text('SEASON SNAPSHOT', style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => _buildLoadingCard(),
            error: (err, stack) => _buildLoadingCard(),
            data: (stats) {
              if (stats == null) return _buildLoadingCard();
              return MotionCard(
                backgroundColor: AppTheme.cardSurface,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('APPS', '${stats.appearances}'),
                        _buildStatCol('GOALS', '${stats.goals}', isPrimary: true),
                        _buildStatCol('ASSISTS', '${stats.assists}'),
                        _buildStatCol('RATING', stats.avgRating.toStringAsFixed(1), isGold: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildWinRateBar(stats.winRate / 100),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, {bool isPrimary = false, bool isGold = false}) {
    final color = isPrimary ? AppTheme.cardinal : isGold ? AppTheme.rose : AppTheme.parchment;
    return Column(
      children: [
        Text(value, style: AppTheme.bebasDisplay.copyWith(fontSize: 32, color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 8)),
      ],
    );
  }

  Widget _buildWinRateBar(double rate) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('WIN RATE', style: AppTheme.labelSmall.copyWith(fontSize: 8)),
            Text('${(rate * 100).toInt()}%', style: AppTheme.bebasDisplay.copyWith(fontSize: 12, color: AppTheme.cardinal)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: rate,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroCtaGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() => Container(
    height: 140,
    decoration: AppTheme.standardCard,
    child: const Center(child: CircularProgressIndicator(color: AppTheme.cardinal)),
  );

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _actionBtn(Icons.add_rounded, 'MATCH', AppTheme.cardinal, () => context.go(AppRoutes.matchCreation)),
          const SizedBox(width: 12),
          _actionBtn(Icons.emoji_events_rounded, 'TOURNAMENT', AppTheme.rose, () => context.go(AppRoutes.tournaments)),
          const SizedBox(width: 12),
          _actionBtn(Icons.play_circle_rounded, 'DRILLS', AppTheme.navy, () => context.go(AppRoutes.drills)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.standardCard.copyWith(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: AppTheme.bebasDisplay.copyWith(fontSize: 12, color: color)),
          ],
        ),
      ),
    ),
  );

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabBar() {
    final tabs = ['LIVE', 'UPCOMING', 'HISTORY'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTab = i;
                _tabController.animateTo(i);
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabs[i],
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 18,
                      color: isSelected ? AppTheme.parchment : AppTheme.gold,
                      letterSpacing: 1,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.cardinal,
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
      return _emptyState(Icons.sports_soccer_rounded, 'NO LIVE MATCH', 'START A MATCH TO BEGIN TRACKING');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LiveMatchCard(
        homeTeam: currentMatch.homeTeamName,
        awayTeam: currentMatch.awayTeamName ?? 'Opponent',
        homeScore: liveState.homeScore,
        awayScore: liveState.awayScore,
        timeDisplay: timerState.displayTime,
        isLive: true,
        onTap: () => context.push(AppRoutes.liveMatch, extra: currentMatch),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final matchState = ref.watch(matchProvider);
    final upcoming = matchState.upcomingMatches.where((m) => m.status == 'upcoming').toList();

    if (upcoming.isEmpty) {
      return _emptyState(Icons.event_rounded, 'NO UPCOMING MATCHES', 'PLAN YOUR NEXT MATCH NOW');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: upcoming.length,
      itemBuilder: (context, i) => _buildMatchRow(upcoming[i]),
    );
  }

  Widget _buildHistorySection() {
    final matchState = ref.watch(matchProvider);
    final completed = matchState.recentMatches.where((m) => m.status == 'completed').toList();

    if (completed.isEmpty) {
      return _emptyState(Icons.history_rounded, 'NO MATCH HISTORY', 'FINISH MATCHES TO SEE STATS');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: completed.length,
      itemBuilder: (context, i) => _buildMatchRow(completed[i], isHistory: true),
    );
  }

  Widget _buildMatchRow(MatchModel match, {bool isHistory = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.standardCard,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push(isHistory ? AppRoutes.matchSummary : AppRoutes.matchDetail, extra: match),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.elevatedSurface, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text('${match.matchDate.day}', style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
        ),
        title: Text('${match.homeTeamName} vs ${match.awayTeamName}', style: AppTheme.bodyBold),
        subtitle: Text(_formatMatchDate(match.matchDate), style: AppTheme.labelSmall),
        trailing: isHistory 
            ? Text('${match.homeScore}-${match.awayScore}', style: AppTheme.bebasDisplay.copyWith(fontSize: 18, color: AppTheme.cardinal))
            : const Icon(Icons.chevron_right, color: AppTheme.gold),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    decoration: AppTheme.standardCard,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 48, color: AppTheme.gold.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(title, style: AppTheme.bebasDisplay.copyWith(fontSize: 20, color: AppTheme.parchment)),
        const SizedBox(height: 4),
        Text(sub, style: AppTheme.labelSmall),
      ],
    ),
  );

  String _formatMatchDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
  }
}
