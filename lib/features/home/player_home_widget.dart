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
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';

/// Player Home Widget - displays player-focused dashboard content
class PlayerHomeWidget extends ConsumerStatefulWidget {
  const PlayerHomeWidget({super.key});

  @override
  ConsumerState<PlayerHomeWidget> createState() => _PlayerHomeWidgetState();
}

class _PlayerHomeWidgetState extends ConsumerState<PlayerHomeWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();

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

    // Load active matches where this player is a participant
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      backgroundColor: MidnightPitchTheme.surfaceDim,
      drawer: _buildQuickActionsDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSeasonSnapshot(),
            const SizedBox(height: 24),
            _buildHorizontalTabBar(),
            const SizedBox(height: 16),
            _buildTabContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.matchCreation),
        backgroundColor: MidnightPitchTheme.electricMint,
        foregroundColor: MidnightPitchTheme.surfaceDim,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'New Match',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final authState = ref.watch(authProvider);
    final displayName = authState.email?.split('@').first ?? 'Player';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back, $displayName',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 13,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _drawerKey.currentState?.openDrawer(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.menu, color: MidnightPitchTheme.primaryText, size: 22),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEASON SNAPSHOT - Stat Rows
  // ============================================================

  Widget _buildSeasonSnapshot() {
    final statsAsync = ref.watch(currentUserStatsProvider);
    final matchState = ref.watch(matchProvider);

    return statsAsync.when(
      loading: () => _buildLoadingCard(),
      error: (_, _) => _buildLoadingCard(),
      data: (stats) {
        if (stats == null) return _buildLoadingCard();

        final position = stats.primaryPosition.isNotEmpty ? stats.primaryPosition : 'ST';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MidnightPitchTheme.sectionLabel('Season Snapshot'),
                _buildPositionBadge(position),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Primary stats row (goals, assists, avg rating)
                  _buildStatsRow(
                    icon: Icons.sports_soccer,
                    label: 'Goals',
                    value: '${stats.goals}',
                    iconColor: MidnightPitchTheme.electricMint,
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(
                    icon: Icons.flag,
                    label: 'Assists',
                    value: '${stats.assists}',
                    iconColor: MidnightPitchTheme.skyBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(
                    icon: Icons.star,
                    label: 'Avg Rating',
                    value: stats.avgRating.toStringAsFixed(1),
                    iconColor: MidnightPitchTheme.championGold,
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    color: MidnightPitchTheme.surfaceContainerHigh,
                  ),
                  // Secondary stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatsRowSecondary('Games', '${stats.appearances}'),
                      _buildStatsRowSecondary('Wins', '${stats.wins}'),
                      _buildStatsRowSecondary('Clean Sheets', '${stats.cleanSheets}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatsRowSecondary('Yellow', '${stats.yellowCards}'),
                      _buildStatsRowSecondary('Red', '${stats.redCards}'),
                      _buildStatsRowSecondary('Win Rate', '${stats.winRate.toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Last 5 matches section
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: MidnightPitchTheme.sectionLabel('Last 5 matches'),
            ),
            const SizedBox(height: 12),
            _buildLastFiveMatches(matchState.recentMatches, ref.read(authProvider).userId),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.secondaryText,
            ),
          ),
        ),
        _buildStatValue(value),
      ],
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: MidnightPitchTheme.primaryText,
      ),
    );
  }

  Widget _buildStatsRowSecondary(String label, String value) {
    return Column(
      children: [
        _buildStatValueSmall(value),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatValueSmall(String value) {
    return Text(
      value,
      style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MidnightPitchTheme.primaryText,
      ),
    );
  }

  Widget _buildPositionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.electricMint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        position.toUpperCase(),
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MidnightPitchTheme.electricMint,
          letterSpacing: 0.05,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const SkeletonCard(height: 180, childCount: 4);
  }

  Widget _buildLastFiveMatches(List<dynamic> recentMatches, String? userId) {
    final results = <String>[];
    for (final match in recentMatches.take(5)) {
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
    }

    if (results.isEmpty) {
      return Text('No recent matches', style: MidnightPitchTheme.bodySM);
    }

    return Row(
      children: results.map((result) {
        final color = switch (result) {
          'W' => MidnightPitchTheme.electricMint,
          'D' => MidnightPitchTheme.championGold,
          'L' => MidnightPitchTheme.liveRed,
          _ => MidnightPitchTheme.mutedText,
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              result,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.surfaceDim,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // QUICK ACTIONS DRAWER
  // ============================================================

  Widget _buildQuickActionsDrawer() {
    return Drawer(
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
            ),
            const Divider(color: MidnightPitchTheme.ghostBorder, height: 1),
            const SizedBox(height: 8),
            _buildDrawerAction(
              icon: Icons.sports_soccer,
              label: 'Score Match',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.liveMatch);
              },
            ),
            _buildDrawerAction(
              icon: Icons.emoji_events_outlined,
              label: 'Tournaments',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.tournaments);
              },
            ),
            _buildDrawerAction(
              icon: Icons.play_circle_outline,
              label: 'Drills',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.drills);
              },
            ),
            _buildDrawerAction(
              icon: Icons.compare_arrows,
              label: 'Compare',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.proCard);
              },
            ),
            _buildDrawerAction(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.profile);
              },
            ),
            _buildDrawerAction(
              icon: Icons.emoji_events,
              label: 'Leaderboard',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.leaderboard);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text(
                'FootHeroes v1.0',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: MidnightPitchTheme.electricMint, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MidnightPitchTheme.primaryText,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  // ============================================================
  // TAB BAR
  // ============================================================

  Widget _buildHorizontalTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('LIVE', 0)),
          Expanded(child: _buildTabItem('UPCOMING', 1)),
          Expanded(child: _buildTabItem('PREVIOUS', 2)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? MidnightPitchTheme.electricMint : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? MidnightPitchTheme.surfaceDim : MidnightPitchTheme.mutedText,
            letterSpacing: 0.05,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOngoingMatch();
      case 1:
        return _buildUpcomingMatch();
      case 2:
        return _buildPreviousMatches();
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // ONGOING MATCH - Simpler live match card
  // ============================================================

  Widget _buildOngoingMatch() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) return const SizedBox.shrink();

    final homeName = currentMatch.homeTeamName.isNotEmpty
        ? currentMatch.homeTeamName
        : 'Home';
    final awayName = currentMatch.awayTeamName ?? 'Away';
    final goalCount = liveState.events.where((e) => e.type == 'goal').length;
    final matchMinute = timerState.currentMinute;
    final halfLabel = timerState.currentHalf == 1 ? '1ST HALF' : '2ND HALF';
    final isHalftime = timerState.status == TimerStatus.halftime;
    final isFinished = timerState.status == TimerStatus.finished;
    final displayLabel = isHalftime
        ? 'HALF TIME'
        : isFinished
            ? 'FULL TIME'
            : "$matchMinute' $halfLabel";

    // Play whistle at half-time and full-time transitions
    if (isHalftime || isFinished) {
      WhistleService.playWhistle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MidnightPitchTheme.sectionLabel('Live Match'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.liveRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 0.1,
                )),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
          child: Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(
                color: MidnightPitchTheme.liveRed.withValues(alpha: 0.1),
                blurRadius: 24, offset: const Offset(0, 4),
              )],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.liveRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer, size: 14, color: MidnightPitchTheme.liveRed),
                  const SizedBox(width: 4),
                  Text(displayLabel, style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.liveRed, letterSpacing: 0.05,
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Text(homeName, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText),
                    overflow: TextOverflow.ellipsis)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${liveState.homeScore}  -  ${liveState.awayScore}',
                      style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: MidnightPitchTheme.primaryText, letterSpacing: -1)),
                  ),
                  Expanded(child: Text(awayName, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText),
                    overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              // Match clock under scoreline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isHalftime ? MidnightPitchTheme.championGold : MidnightPitchTheme.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(timerState.displayTime, style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  )),
                  if (timerState.displayExtraTime != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(timerState.displayExtraTime!, style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.championGold,
                      )),
                    ),
                  const SizedBox(width: 6),
                  Text(displayLabel, style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.mutedText,
                  )),
                ]),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.sports_soccer, size: 14, color: MidnightPitchTheme.electricMint),
                const SizedBox(width: 4),
                Text('$goalCount goals', style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: MidnightPitchTheme.mutedText)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 40,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MidnightPitchTheme.electricMint,
                    foregroundColor: MidnightPitchTheme.surfaceDim,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_arrow, size: 18),
                    const SizedBox(width: 8),
                    Text('RESUME MATCH', style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.05)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UPCOMING MATCH
  // ============================================================

  Widget _buildUpcomingMatch() {
    final matchState = ref.watch(matchProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    // Find upcoming matches where user is a participant
    final upcomingMatches = matchState.upcomingMatches.where((m) {
      if (userId == null) return false;
      return m.status == 'upcoming' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (upcomingMatches.isEmpty) return _buildEmptyUpcomingMatch();

    // Show the next upcoming match
    final nextMatch = upcomingMatches.first;
    final homeTeamName = nextMatch.homeTeamName.isNotEmpty ? nextMatch.homeTeamName : 'Home';
    final awayTeamName = nextMatch.awayTeamName ?? 'Away';
    final matchDate = nextMatch.matchDate;
    final timeStr = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
    final dateStr = _formatDate(matchDate);
    final venue = nextMatch.venue;
    final format = nextMatch.format.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcomingMatches.length > 1)
          MidnightPitchTheme.sectionLabel('Upcoming matches (${upcomingMatches.length})')
        else
          MidnightPitchTheme.sectionLabel('Upcoming match'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go(AppRoutes.matchDetail, extra: nextMatch),
          child: Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MidnightPitchTheme.championGold.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMatchHeader(homeTeamName, awayTeamName, timeStr, dateStr),
                if (venue != null && venue.isNotEmpty || format.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (format.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            format,
                            style: TextStyle(
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
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: MidnightPitchTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.matchDetail, extra: nextMatch),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: MidnightPitchTheme.surfaceDim,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, size: 18),
                        const SizedBox(width: 8),
                        Text('VIEW MATCH',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 12, fontWeight: FontWeight.w800,
                            letterSpacing: 0.05,
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
        if (upcomingMatches.length > 1) ...[
          const SizedBox(height: 12),
          ...upcomingMatches.skip(1).take(2).map((match) {
            final hName = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home';
            final aName = match.awayTeamName ?? 'Away';
            final mDate = _formatDate(match.matchDate);
            return GestureDetector(
              onTap: () => context.go(AppRoutes.matchDetail, extra: match),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: MidnightPitchTheme.championGold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$hName vs $aName',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                    ),
                    Text(mDate, style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11, color: MidnightPitchTheme.mutedText,
                    )),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyUpcomingMatch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Upcoming match'),
        const SizedBox(height: 16),
        const EmptyStateWidget(
          icon: Icons.event_outlined,
          title: 'No Upcoming Match',
          subtitle: 'Create a match to get started',
        ),
      ],
    );
  }

  // ============================================================
  // PREVIOUS MATCHES - Without _Pressable, without 4px left accent border
  // ============================================================

  Widget _buildPreviousMatches() {
    final matchState = ref.watch(matchProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    final completedMatches = matchState.recentMatches.where((m) {
      return m.status == 'completed' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (completedMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Previous Matches'),
        const SizedBox(height: 16),
        ...completedMatches.map((match) => _buildPreviousMatchCard(match)),
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

    final dateStr = '${match.matchDate.day}/${match.matchDate.month}';

    return GestureDetector(
      onTap: () => context.go(AppRoutes.matchSummary, extra: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: resultColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                resultLabel,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: resultColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.homeTeamName.isNotEmpty ? match.homeTeamName : "Home"} ${match.homeScore} - ${match.awayScore} ${match.awayTeamName ?? "Away"}',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        match.format.toUpperCase(),
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                      if (match.venue != null && match.venue!.isNotEmpty) ...[
                        Text(
                          ' · ${match.venue}',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.receipt_long, color: resultColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MATCH HEADER HELPERS
  // ============================================================

  Widget _buildMatchHeader(String homeTeam, String awayTeam, String time, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTeamColumn(homeTeam, Icons.shield_outlined),
        _buildMatchTime(time, date),
        _buildTeamColumn(awayTeam, Icons.shield_outlined),
      ],
    );
  }

  Widget _buildTeamColumn(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MidnightPitchTheme.mutedText, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchTime(String time, String date) {
    return Column(
      children: [
        Text(
          'VS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.electricMint,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, color: MidnightPitchTheme.mutedText),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }
}