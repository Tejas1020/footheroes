import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/live_match_provider.dart';
import '../../providers/match_timer_provider.dart';
import '../../providers/player_stats_provider.dart';
import '../../models/match_model.dart';
import '../../core/router/app_router.dart';
import '../../services/whistle_service.dart';
import '../../widgets/glass_neu_decorations.dart';

/// Player Home Widget - Redesigned with vibrant block-based layout
class PlayerHomeWidget extends ConsumerStatefulWidget {
  const PlayerHomeWidget({super.key});

  @override
  ConsumerState<PlayerHomeWidget> createState() => _PlayerHomeWidgetState();
}

class _PlayerHomeWidgetState extends ConsumerState<PlayerHomeWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedIndex = _tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
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
        ref.read(matchProvider.notifier).loadUpcomingMatches(currentTeam.teamId);
      }
    });

    ref.read(matchProvider.notifier).loadRecentMatches();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Ready to score today?';
    if (hour < 17) return 'Keep the momentum going!';
    return 'Night mode activated.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Quick Actions Strip
            SliverToBoxAdapter(child: _buildQuickActions()),

            // Season Snapshot + Last 5
            SliverToBoxAdapter(child: _buildSeasonSnapshot()),

            // Tab Bar
            SliverToBoxAdapter(child: _buildTabBar()),

            // Tab Content
            SliverToBoxAdapter(child: _buildTabContent()),

            // Bottom safe area
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ============================================================
  // HEADER - Avatar + greeting + badges
  // ============================================================

  Widget _buildHeader() {
    final authState = ref.watch(authProvider);
    final name = authState.email?.split('@').first ?? 'Player';
    final displayName = name.split(' ').first;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              GlassAvatarBadge(initials: initials, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDay()},',
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.headingFontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Role + Position badges
          Row(
            children: [
              _buildRoleBadge(),
              const SizedBox(width: 8),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (stats) {
                  final position =
                      stats?.primaryPosition.isNotEmpty == true ? stats!.primaryPosition : null;
                  if (position == null) return const SizedBox.shrink();
                  return _buildPositionBadge(position);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: MidnightPitchTheme.primaryGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PLAYER',
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPositionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.electricMint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        position.toUpperCase(),
        style: const TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: MidnightPitchTheme.electricMint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS STRIP
  // ============================================================

  Widget _buildQuickActions() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildActionChip(
            icon: Icons.add,
            label: 'New Match',
            color: MidnightPitchTheme.electricMint,
            onTap: () => context.go(AppRoutes.matchCreation),
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            icon: Icons.emoji_events_outlined,
            label: 'Tournaments',
            color: MidnightPitchTheme.championGold,
            onTap: () => context.go(AppRoutes.tournaments),
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            icon: Icons.fitness_center,
            label: 'Drills',
            color: MidnightPitchTheme.skyBlue,
            onTap: () => context.go(AppRoutes.drills),
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            icon: Icons.leaderboard_outlined,
            label: 'Leaderboard',
            color: MidnightPitchTheme.primaryText,
            onTap: () => context.go(AppRoutes.leaderboard),
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            icon: Icons.person_outline,
            label: 'Profile',
            color: MidnightPitchTheme.mutedText,
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEASON SNAPSHOT - 2x3 stat grid + last 5
  // ============================================================

  Widget _buildSeasonSnapshot() {
    final statsAsync = ref.watch(currentUserStatsProvider);
    final matchState = ref.watch(matchProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text(
            'SEASON SNAPSHOT',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Stats grid
          statsAsync.when(
            loading: () => _buildLoadingStatsGrid(),
            error: (e, s) => _buildLoadingStatsGrid(),
            data: (stats) {
              if (stats == null) return _buildLoadingStatsGrid();
              return _buildStatsGrid(stats);
            },
          ),
          const SizedBox(height: 16),
          // Last 5 matches
          const Text(
            'LAST 5',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildLastFiveMatches(matchState.recentMatches, ref.read(authProvider).userId),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingStatsGrid() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MidnightPitchTheme.neuRaised,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: MidnightPitchTheme.electricMint,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: MidnightPitchTheme.neuRaised,
      ),
      child: Column(
        children: [
          // Primary stats row - 3 large tiles
          Row(
            children: [
              Expanded(child: _buildStatTile('${stats.goals}', 'Goals', Icons.sports_soccer, MidnightPitchTheme.electricMint)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile('${stats.assists}', 'Assists', Icons.flag, MidnightPitchTheme.skyBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile(stats.avgRating.toStringAsFixed(1), 'Avg Rating', Icons.star, MidnightPitchTheme.championGold)),
            ],
          ),
          const SizedBox(height: 12),
          // Secondary stats row - 6 compact tiles
          Row(
            children: [
              Expanded(child: _buildCompactStat('${stats.appearances}', 'Games')),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactStat('${stats.wins}', 'Wins')),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactStat('${stats.cleanSheets}', 'Clean')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildCompactStat('${stats.yellowCards}', 'Yellow')),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactStat('${stats.redCards}', 'Red')),
              const SizedBox(width: 8),
              Expanded(child: _buildCompactStat('${stats.winRate.toStringAsFixed(0)}%', 'Win %')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.neuBase,
        borderRadius: BorderRadius.circular(14),
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
      child: Column(
        children: [
          GlassIconBadge(icon: icon, iconColor: color, size: 36),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MidnightPitchTheme.ghostBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastFiveMatches(List<dynamic> recentMatches, String? userId) {
    final results = <String>[];
    for (final match in recentMatches.take(10)) {
      final m = match as MatchModel;
      if (m.status != 'completed') continue;
      final homeGoals = m.homeScore;
      final awayGoals = m.awayScore;
      if (homeGoals == awayGoals) {
        results.add('D');
      } else {
        final isHome = m.homeTeamId == userId || (m.createdBy == userId && m.awayTeamId != userId);
        final isAway = m.awayTeamId == userId;
        final userWon = (isHome && homeGoals > awayGoals) || (isAway && awayGoals > homeGoals);
        results.add(userWon ? 'W' : 'L');
      }
      if (results.length >= 5) break;
    }

    if (results.isEmpty) {
      return Text(
        'No recent matches',
        style: MidnightPitchTheme.bodySM.copyWith(color: MidnightPitchTheme.mutedText),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: results.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) {
          final result = results[i];
          final color = switch (result) {
            'W' => MidnightPitchTheme.electricMint,
            'D' => MidnightPitchTheme.championGold,
            'L' => MidnightPitchTheme.liveRed,
            _ => MidnightPitchTheme.mutedText,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GlassBadge(label: result, color: color, showGlow: true, size: 40),
          );
        },
      ),
    );
  }

  // ============================================================
  // TAB BAR - Animated pill selection
  // ============================================================

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: MidnightPitchTheme.neuBase,
          borderRadius: BorderRadius.circular(14),
          boxShadow: MidnightPitchTheme.neuRaised,
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _buildTabItem('LIVE', 0, Icons.sensors)),
            Expanded(child: _buildTabItem('UPCOMING', 1, Icons.event)),
            Expanded(child: _buildTabItem('HISTORY', 2, Icons.history)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? MidnightPitchTheme.electricMint : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MidnightPitchTheme.electricMint.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : MidnightPitchTheme.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : MidnightPitchTheme.mutedText,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildTabContentKeyed(),
      ),
    );
  }

  Widget _buildTabContentKeyed() {
    switch (_selectedIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('live'),
          child: _buildOngoingMatch(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('upcoming'),
          child: _buildUpcomingMatch(),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('history'),
          child: _buildPreviousMatches(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // LIVE MATCH - Hero glassmorphic card
  // ============================================================

  Widget _buildOngoingMatch() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) {
      return _buildEmptyLiveMatch();
    }

    final homeName = currentMatch.homeTeamName.isNotEmpty ? currentMatch.homeTeamName : 'Home';
    final awayName = currentMatch.awayTeamName ?? 'Away';
    final goalCount = liveState.events.where((e) => e.type == 'goal').length;
    final matchMinute = timerState.currentMinute;
    final halfLabel = timerState.currentHalf == 1 ? '1ST' : '2ND';
    final isHalftime = timerState.status == TimerStatus.halftime;
    final isFinished = timerState.status == TimerStatus.finished;
    final displayLabel = isHalftime
        ? 'HALF TIME'
        : isFinished
            ? 'FULL TIME'
            : "$matchMinute'";

    if (isHalftime || isFinished) {
      WhistleService.playWhistle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live badge row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE MATCH',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.liveRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingDot(color: Colors.white, size: 6),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Hero card
        GestureDetector(
          onTap: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFFFFFFF).withValues(alpha: 0.40)),
                  boxShadow: [
                    BoxShadow(
                      color: MidnightPitchTheme.liveRed.withValues(alpha: 0.20),
                      blurRadius: 30,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Timer badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.liveRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 14, color: MidnightPitchTheme.liveRed),
                          const SizedBox(width: 6),
                          Text(
                            displayLabel,
                            style: TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: MidnightPitchTheme.liveRed,
                            ),
                          ),
                          if (!isHalftime && !isFinished) ...[
                            const SizedBox(width: 4),
                            Text(
                              halfLabel,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: MidnightPitchTheme.liveRed.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Score row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Home team
                        _buildTeamShield(homeName, Icons.shield_outlined),
                        const SizedBox(width: 20),
                        // Score
                        Column(
                          children: [
                            Text(
                              '${liveState.homeScore}',
                              style: const TextStyle(
                                fontFamily: MidnightPitchTheme.headingFontFamily,
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.primaryText,
                              ),
                            ),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: MidnightPitchTheme.mutedText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '${liveState.awayScore}',
                              style: const TextStyle(
                                fontFamily: MidnightPitchTheme.headingFontFamily,
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Away team
                        _buildTeamShield(awayName, Icons.shield_outlined),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Team names
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            homeName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'vs',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            awayName,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Goals + timer info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: MidnightPitchTheme.neuBase,
                            borderRadius: BorderRadius.circular(8),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_soccer, size: 14, color: MidnightPitchTheme.electricMint),
                              const SizedBox(width: 6),
                              Text(
                                '$goalCount goals scored',
                                style: const TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: MidnightPitchTheme.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MidnightPitchTheme.electricMint,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'RESUME MATCH',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTeamShield(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: MidnightPitchTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: MidnightPitchTheme.electricMint, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLiveMatch() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.neuBase,
          borderRadius: BorderRadius.circular(20),
          boxShadow: MidnightPitchTheme.neuRaised,
        ),
        child: Column(
          children: [
            Icon(Icons.sports_soccer, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No Live Match',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start or join a match to see it here',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPCOMING MATCH
  // ============================================================

  Widget _buildUpcomingMatch() {
    final matchState = ref.watch(matchProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    final upcomingMatches = matchState.upcomingMatches.where((m) {
      if (userId == null) return false;
      return m.status == 'upcoming' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (upcomingMatches.isEmpty) return _buildEmptyUpcomingMatch();

    final nextMatch = upcomingMatches.first;
    final homeTeamName = nextMatch.homeTeamName.isNotEmpty ? nextMatch.homeTeamName : 'Home';
    final awayTeamName = nextMatch.awayTeamName ?? 'Away';
    final matchDate = nextMatch.matchDate;
    final timeStr =
        '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
    final dateStr = _formatDate(matchDate);
    final venue = nextMatch.venue;
    final format = nextMatch.format.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcomingMatches.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'UPCOMING (${upcomingMatches.length})',
              style: const TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 1.5,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'UPCOMING',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 1.5,
              ),
            ),
          ),
        // Main upcoming card
        GestureDetector(
          onTap: () => context.go(AppRoutes.matchDetail, extra: nextMatch),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              borderRadius: BorderRadius.circular(20),
              boxShadow: MidnightPitchTheme.neuRaised,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTeamShield(homeTeamName, Icons.shield_outlined),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text(
                          'KICK OFF',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.electricMint,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.headingFontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _buildTeamShield(awayTeamName, Icons.shield_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                // Format + venue row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (format.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          format,
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.electricMint,
                          ),
                        ),
                      ),
                    if (venue != null && venue.isNotEmpty) ...[
                      if (format.isNotEmpty) const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined, size: 12, color: MidnightPitchTheme.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        venue,
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.matchDetail, extra: nextMatch),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MidnightPitchTheme.electricMint,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'VIEW MATCH',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Additional matches
        if (upcomingMatches.length > 1) ...[
          const SizedBox(height: 12),
          ...upcomingMatches.skip(1).take(3).map((match) {
            final hName = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home';
            final aName = match.awayTeamName ?? 'Away';
            final mDate = _formatDate(match.matchDate);
            return GestureDetector(
              onTap: () => context.go(AppRoutes.matchDetail, extra: match),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.neuBase,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: MidnightPitchTheme.neuLight,
                      offset: const Offset(-2, -2),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: MidnightPitchTheme.neuDark.withValues(alpha: 0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.championGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.event_outlined, size: 18, color: MidnightPitchTheme.championGold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$hName vs $aName',
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.primaryText,
                            ),
                          ),
                          Text(
                            match.format.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 10,
                              color: MidnightPitchTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      mDate,
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 18, color: MidnightPitchTheme.mutedText),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyUpcomingMatch() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.neuBase,
          borderRadius: BorderRadius.circular(20),
          boxShadow: MidnightPitchTheme.neuRaised,
        ),
        child: Column(
          children: [
            Icon(Icons.event_outlined, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No Upcoming Match',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a match to get started',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY - Previous matches with result badges
  // ============================================================

  Widget _buildPreviousMatches() {
    final matchState = ref.watch(matchProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    final completedMatches = matchState.recentMatches.where((m) {
      return m.status == 'completed' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (completedMatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: MidnightPitchTheme.neuBase,
            borderRadius: BorderRadius.circular(20),
            boxShadow: MidnightPitchTheme.neuRaised,
          ),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text(
                'No Match History',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completed matches will appear here',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'HISTORY',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...completedMatches.take(10).map((match) => _buildPreviousMatchCard(match)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviousMatchCard(MatchModel match) {
    final homeWon = match.homeScore > match.awayScore;
    final isHome = match.homeTeamId == ref.read(authProvider).userId;
    final resultLabel = homeWon
        ? (isHome ? 'WIN' : 'LOSS')
        : match.homeScore < match.awayScore
            ? (isHome ? 'LOSS' : 'WIN')
            : 'DRAW';
    final resultColor = switch (resultLabel) {
      'WIN' => MidnightPitchTheme.electricMint,
      'LOSS' => MidnightPitchTheme.liveRed,
      _ => MidnightPitchTheme.championGold,
    };

    final dateStr = '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}';

    return GestureDetector(
      onTap: () => context.go(AppRoutes.matchSummary, extra: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.neuBase,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: resultColor.withValues(alpha: 0.30)),
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
        child: Row(
          children: [
            // Result badge (larger, glowing)
            GlassBadge(label: resultLabel, color: resultColor, showGlow: true, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score
                  Row(
                    children: [
                      Text(
                        match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home',
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${match.homeScore} - ${match.awayScore}',
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: MidnightPitchTheme.electricMint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        match.awayTeamName ?? 'Away',
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Meta row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match.format.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ),
                      if (match.venue != null && match.venue!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_outlined, size: 10, color: MidnightPitchTheme.mutedText),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            match.venue!,
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 10,
                              color: MidnightPitchTheme.mutedText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        dateStr,
                        style: const TextStyle(
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
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: resultColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAB
  // ============================================================

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.go(AppRoutes.matchCreation),
      backgroundColor: MidnightPitchTheme.electricMint,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add, size: 22),
      label: const Text(
        'New Match',
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }
}