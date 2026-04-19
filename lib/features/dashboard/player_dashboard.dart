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

/// Player Dashboard - Redesigned with bold block-based layout
/// Following Vibrant & Block-based style with proper touch targets
class PlayerDashboard extends ConsumerStatefulWidget {
  const PlayerDashboard({super.key});

  @override
  ConsumerState<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends ConsumerState<PlayerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
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
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(child: _buildHeader()),

            // Quick Stats Hero
            SliverToBoxAdapter(child: _buildQuickStats()),

            // Quick Actions
            SliverToBoxAdapter(child: _buildQuickActions()),

            // Tab Bar
            SliverToBoxAdapter(child: _buildTabBar()),

            // Tab Content
            SliverToBoxAdapter(child: _buildTabContent()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER - Bold greeting with avatar
  // ============================================================

  Widget _buildHeader() {
    final auth = ref.watch(authProvider);
    final name = auth.email?.split('@').first ?? 'Player';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: MidnightPitchTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                color: MidnightPitchTheme.surfaceDim,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name.split(' ').first}!',
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.headingFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          _buildIconButton(Icons.notifications_outlined, () {
            // TODO: Notifications
          }),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Ready for morning training?';
    if (hour < 17) return 'Ready for afternoon match?';
    return 'Time for evening practice!';
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MidnightPitchTheme.ghostBorder),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: MidnightPitchTheme.primaryText, size: 24),
      ),
    );
  }

  // ============================================================
  // QUICK STATS - Large hero stat cards
  // ============================================================

  Widget _buildQuickStats() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: statsAsync.when(
        loading: () => _buildLoadingStats(),
        error: (_, __) => _buildLoadingStats(),
        data: (stats) {
          if (stats == null) return _buildLoadingStats();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MidnightPitchTheme.sectionLabel('Season Stats'),
              const SizedBox(height: 12),
              _buildAnimatedStatsCard(stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedStatsCard(dynamic stats) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.94 + (0.06 * animValue),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Season Stats',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.headingFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.appearances} matches',
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.electricBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Main stats - 3 columns
            Row(
              children: [
                Expanded(
                  child: _buildMainStat(
                    value: '${stats.goals}',
                    label: 'Goals',
                    color: MidnightPitchTheme.electricBlue,
                    icon: Icons.sports_soccer,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _buildMainStat(
                    value: '${stats.assists}',
                    label: 'Assists',
                    color: MidnightPitchTheme.electricBlue,
                    icon: Icons.assistant,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _buildMainStat(
                    value: stats.avgRating.toStringAsFixed(1),
                    label: 'Rating',
                    color: MidnightPitchTheme.championGold,
                    icon: Icons.star,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Secondary stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSubStat('${stats.wins}', 'Wins', MidnightPitchTheme.electricBlue),
                  _buildSubStat('${stats.draws}', 'Draws', MidnightPitchTheme.championGold),
                  _buildSubStat('${stats.losses}', 'Losses', MidnightPitchTheme.liveRed),
                  _buildSubStat('${stats.cleanSheets}', 'Clean Sheets', MidnightPitchTheme.electricBlue),
                  _buildSubStat('${stats.winRate.toStringAsFixed(0)}%', 'Win Rate', MidnightPitchTheme.championGold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStat({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animVal, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animVal)),
          child: Opacity(opacity: animVal, child: child),
        );
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Season Stats',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: MidnightPitchTheme.electricBlue,
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS - Icon chips
  // ============================================================

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Quick Actions'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.add_circle,
                  label: 'New Match',
                  color: MidnightPitchTheme.electricBlue,
                  onTap: () => context.go(AppRoutes.matchCreation),
                ),
                const SizedBox(width: 10),
                _buildActionChip(
                  icon: Icons.emoji_events,
                  label: 'Tournaments',
                  color: MidnightPitchTheme.championGold,
                  onTap: () => context.go(AppRoutes.tournaments),
                ),
                const SizedBox(width: 10),
                _buildActionChip(
                  icon: Icons.play_circle,
                  label: 'Drills',
                  color: MidnightPitchTheme.electricBlue,
                  onTap: () => context.go(AppRoutes.drills),
                ),
                const SizedBox(width: 10),
                _buildActionChip(
                  icon: Icons.person,
                  label: 'Profile',
                  color: MidnightPitchTheme.primaryText,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
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
  // TAB BAR - LIVE / UPCOMING / HISTORY
  // ============================================================

  Widget _buildTabBar() {
    final tabs = ['LIVE', 'UPCOMING', 'HISTORY'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MidnightPitchTheme.ghostBorder),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = index);
                  _tabController.animateTo(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? MidnightPitchTheme.electricBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : MidnightPitchTheme.mutedText,
                      letterSpacing: 0.5,
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

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildTabBody(),
      ),
    );
  }

  Widget _buildTabBody() {
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

  // ============================================================
  // LIVE MATCH SECTION
  // ============================================================

  Widget _buildLiveSection() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) {
      return _buildEmptyState(
        icon: Icons.sports_soccer,
        title: 'No Live Match',
        subtitle: 'Start a new match to get going!',
        action: _buildActionChip(
          icon: Icons.add,
          label: 'New Match',
          color: MidnightPitchTheme.electricBlue,
          onTap: () => context.go(AppRoutes.matchCreation),
        ),
      );
    }

    // Play whistle at transitions
    if (timerState.status == TimerStatus.halftime ||
        timerState.status == TimerStatus.finished) {
      WhistleService.playWhistle();
    }

    final homeName = currentMatch.homeTeamName.isNotEmpty
        ? currentMatch.homeTeamName
        : 'Home';
    final awayName = currentMatch.awayTeamName ?? 'Away';
    final goals = liveState.events.where((e) => e.type == 'goal').length;

    return Column(
      key: const ValueKey('live'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: MidnightPitchTheme.liveRed,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Match card
        GestureDetector(
          onTap: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.3)),
              boxShadow: MidnightPitchTheme.ambientShadow,
            ),
            child: Column(
              children: [
                // Timer badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.liveRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: MidnightPitchTheme.liveRed),
                      const SizedBox(width: 6),
                      Text(
                        _getTimerDisplay(timerState),
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.liveRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Teams row
                Row(
                  children: [
                    Expanded(
                      child: _buildTeamDisplay(homeName, Icons.shield_outlined),
                    ),
                    Column(
                      children: [
                        Text(
                          '${liveState.homeScore} - ${liveState.awayScore}',
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.headingFontFamily,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$goals goals',
                          style: const TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 12,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _buildTeamDisplay(awayName, Icons.shield_outlined, isRight: true),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Resume button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: const Text(
                      'RESUME MATCH',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MidnightPitchTheme.electricBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimerDisplay(timerState) {
    if (timerState.status == TimerStatus.halftime) return 'HALF TIME';
    if (timerState.status == TimerStatus.finished) return 'FULL TIME';
    final half = timerState.currentHalf == 1 ? '1st' : '2nd';
    return "${timerState.currentMinute}' $half";
  }

  Widget _buildTeamDisplay(String name, IconData icon, {bool isRight = false}) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MidnightPitchTheme.electricBlue, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MidnightPitchTheme.primaryText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ============================================================
  // UPCOMING MATCHES SECTION
  // ============================================================

  Widget _buildUpcomingSection() {
    final matchState = ref.watch(matchProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.userId;

    final upcoming = matchState.upcomingMatches.where((m) {
      if (userId == null) return false;
      return m.status == 'upcoming' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (upcoming.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event,
        title: 'No Upcoming Matches',
        subtitle: 'Create a match to see it here!',
        action: _buildActionChip(
          icon: Icons.add,
          label: 'New Match',
          color: MidnightPitchTheme.electricBlue,
          onTap: () => context.go(AppRoutes.matchCreation),
        ),
      );
    }

    return Column(
      key: const ValueKey('upcoming'),
      children: [
        // Count badge
        Row(
          children: [
            MidnightPitchTheme.sectionLabel('${upcoming.length} Upcoming'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${upcoming.length}',
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Upcoming cards
        ...upcoming.map((match) => _buildUpcomingCard(match)),
      ],
    );
  }

  Widget _buildUpcomingCard(MatchModel match) {
    final homeName = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home';
    final awayName = match.awayTeamName ?? 'Away';

    return GestureDetector(
      onTap: () => context.go(AppRoutes.matchDetail, extra: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MidnightPitchTheme.ghostBorder),
          boxShadow: MidnightPitchTheme.ambientShadow,
        ),
        child: Row(
          children: [
            // Date block
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.championGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    match.matchDate.day.toString(),
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.headingFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.championGold,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(match.matchDate.month),
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.championGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Match info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$homeName vs $awayName',
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: MidnightPitchTheme.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        '${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 12,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (match.format.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            match.format.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.electricBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: MidnightPitchTheme.mutedText, size: 24),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  // ============================================================
  // HISTORY SECTION
  // ============================================================

  Widget _buildHistorySection() {
    final matchState = ref.watch(matchProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.userId;

    final completed = matchState.recentMatches.where((m) {
      return m.status == 'completed' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (completed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Match History',
        subtitle: 'Your completed matches will appear here',
      );
    }

    // Last 5 results
    final last5 = completed.take(5).toList();
    final results = _buildResultIndicators(last5, userId);

    return Column(
      key: const ValueKey('history'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Recent Results'),
        const SizedBox(height: 12),
        // Last 5 badges
        if (results.isNotEmpty) ...[
          Row(
            children: results.map((r) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildResultBadge(r),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
        // Match list
        ...completed.take(5).map((m) => _buildHistoryCard(m, userId)),
      ],
    );
  }

  List<String> _buildResultIndicators(List<MatchModel> matches, String? userId) {
    final results = <String>[];
    for (final m in matches) {
      final isHome = m.homeTeamId == userId || m.createdBy == userId;
      final won = (isHome && m.homeScore > m.awayScore) ||
                  (!isHome && m.awayScore > m.homeScore);
      results.add(m.homeScore == m.awayScore ? 'D' : won ? 'W' : 'L');
    }
    return results;
  }

  Widget _buildResultBadge(String result) {
    final (color, bgColor) = switch (result) {
      'W' => (MidnightPitchTheme.electricBlue, MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)),
      'D' => (MidnightPitchTheme.championGold, MidnightPitchTheme.championGold.withValues(alpha: 0.15)),
      'L' => (MidnightPitchTheme.liveRed, MidnightPitchTheme.liveRed.withValues(alpha: 0.15)),
      _ => (MidnightPitchTheme.mutedText, MidnightPitchTheme.ghostBorder),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        result,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.headingFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(MatchModel match, String? userId) {
    final homeName = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home';
    final awayName = match.awayTeamName ?? 'Away';
    final isHome = match.homeTeamId == userId || match.createdBy == userId;
    final won = (isHome && match.homeScore > match.awayScore) ||
               (!isHome && match.awayScore > match.homeScore);
    final isDraw = match.homeScore == match.awayScore;
    final resultLabel = isDraw ? 'DRAW' : won ? 'WIN' : 'LOSS';
    final resultColor = isDraw ? MidnightPitchTheme.championGold
                  : won ? MidnightPitchTheme.electricBlue
                  : MidnightPitchTheme.liveRed;

    return GestureDetector(
      onTap: () => context.go(AppRoutes.matchSummary, extra: match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: resultColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                resultLabel,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$homeName ${match.homeScore} - ${match.awayScore} $awayName',
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatMatchDate(match.matchDate),
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: MidnightPitchTheme.mutedText, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: MidnightPitchTheme.electricBlue, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action,
          ],
        ],
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}';
  }
}