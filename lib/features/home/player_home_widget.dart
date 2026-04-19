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
import '../../widgets/motion_card.dart';

/// REDESIGNED Player Home Widget
/// Electric Midnight aesthetic: motion-driven animations, parallax scroll effects, bold visual hierarchy
class PlayerHomeWidget extends ConsumerStatefulWidget {
  const PlayerHomeWidget({super.key});

  @override
  ConsumerState<PlayerHomeWidget> createState() => _PlayerHomeWidgetState();
}

class _PlayerHomeWidgetState extends ConsumerState<PlayerHomeWidget>
    with TickerProviderStateMixin {
  double _scrollOffset = 0;
  final ScrollController _scrollController = ScrollController();

  // Tab state
  int _selectedTab = 0; // 0 = Live, 1 = Upcoming, 2 = History

  // Entry animations
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

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _entryController.forward();
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
        ref.read(matchProvider.notifier).loadUpcomingMatches(currentTeam.teamId);
      }
    });
    ref.read(matchProvider.notifier).loadRecentMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) {
        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          slivers: [
            // ── QUICK ACTIONS STRIP ──
            SliverToBoxAdapter(
              child: Opacity(
                opacity: _staggerAnimations[1].value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _staggerAnimations[1].value)),
                  child: _buildQuickActions(),
                ),
              ),
            ),

            // ── SEASON STATS — ONE CARD ──
            SliverToBoxAdapter(
              child: Opacity(
                opacity: _staggerAnimations[2].value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _staggerAnimations[2].value)),
                  child: _buildSeasonStats(),
                ),
              ),
            ),

            // ── HORIZONTAL TAB BAR ──
            SliverToBoxAdapter(
              child: Opacity(
                opacity: _staggerAnimations[3].value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _staggerAnimations[3].value)),
                  child: _buildTabBar(),
                ),
              ),
            ),

            // ── TAB CONTENT ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildTabContent(),
                ),
              ),
            ),

            // Bottom safe area
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // QUICK ACTIONS — Horizontal scroll with animated chips
  // ─────────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(Icons.add_circle_rounded, 'New Match', MidnightPitchTheme.electricBlue, () => context.go(AppRoutes.matchCreation)),
      _QuickActionData(Icons.emoji_events_rounded, 'Tournaments', MidnightPitchTheme.championGold, () => context.go(AppRoutes.tournaments)),
      _QuickActionData(Icons.fitness_center_rounded, 'Drills', MidnightPitchTheme.electricBlue, () => context.go(AppRoutes.drills)),
      _QuickActionData(Icons.leaderboard_rounded, 'Leaderboard', MidnightPitchTheme.primaryText, () => context.go(AppRoutes.leaderboard)),
      _QuickActionData(Icons.person_rounded, 'Profile', MidnightPitchTheme.mutedText, () => context.go(AppRoutes.profile)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 0, 10),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: actions.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _AnimatedActionChip(
                  data: actions[i],
                  delay: i * 60,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SEASON STATS — ALL IN ONE CARD
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSeasonStats() {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: statsAsync.when(
        loading: () => _buildLoadingStats(),
        error: (_, __) => _buildEmptyStats(),
        data: (stats) {
          if (stats == null) return _buildEmptyStats();
          return _buildStatsCard(stats);
        },
      ),
    );
  }

  Widget _buildLoadingStats() {
    return MotionCard(
      staggerIndex: 0,
      isLoading: true,
      child: const SizedBox(height: 180),
    );
  }

  Widget _buildEmptyStats() {
    return MotionCard(
      staggerIndex: 0,
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: MidnightPitchTheme.surfaceContainerHighest),
          const SizedBox(height: 12),
          Text('No Stats Yet', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
          const SizedBox(height: 4),
          Text('Play matches to see your stats here', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, color: MidnightPitchTheme.mutedText)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(dynamic stats) {
    return MotionCard(
      staggerIndex: 0,
      glowColor: MidnightPitchTheme.electricBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEASON SNAPSHOT',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.appearances} matches played',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: MidnightPitchTheme.championGold),
                    const SizedBox(width: 4),
                    Text(
                      stats.avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.headingFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.championGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hero stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroStat('${stats.goals}', 'Goals', Icons.sports_soccer, MidnightPitchTheme.electricBlue),
              Container(width: 1, height: 50, color: MidnightPitchTheme.ghostBorder),
              _buildHeroStat('${stats.assists}', 'Assists', Icons.assistant, MidnightPitchTheme.electricBlue),
              Container(width: 1, height: 50, color: MidnightPitchTheme.ghostBorder),
              _buildHeroStat('${stats.wins}', 'Wins', Icons.emoji_events, MidnightPitchTheme.championGold),
              Container(width: 1, height: 50, color: MidnightPitchTheme.ghostBorder),
              _buildHeroStat('${stats.winRate.toStringAsFixed(0)}%', 'Win Rate', Icons.percent, MidnightPitchTheme.championGold),
            ],
          ),
          const SizedBox(height: 20),

          // Secondary stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat('${stats.draws}', 'Draws', MidnightPitchTheme.mutedText),
                _buildCompactStat('${stats.losses}', 'Losses', MidnightPitchTheme.liveRed),
                _buildCompactStat('${stats.cleanSheets}', 'Clean Sheets', MidnightPitchTheme.electricBlue),
                _buildCompactStat('${stats.yellowCards}', 'Yellow', MidnightPitchTheme.championGold),
                _buildCompactStat('${stats.redCards}', 'Red', MidnightPitchTheme.liveRed),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent form row
          _buildRecentForm(stats),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon, Color color) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: MidnightPitchTheme.mutedText,
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
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentForm(dynamic stats) {
    final matchState = ref.watch(matchProvider);
    final userId = ref.read(authProvider).userId;

    final results = <String>[];
    for (final match in matchState.recentMatches.take(10)) {
      if (match.status != 'completed') continue;
      final m = match;
      final isHome = m.homeTeamId == userId || (m.createdBy == userId && m.awayTeamId != userId);
      final isAway = m.awayTeamId == userId;
      if (m.homeScore == m.awayScore) {
        results.add('D');
      } else {
        final userWon = (isHome && m.homeScore > m.awayScore) || (isAway && m.awayScore > m.homeScore);
        results.add(userWon ? 'W' : 'L');
      }
      if (results.length >= 5) break;
    }

    if (results.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'RECENT FORM',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: results.map((r) {
            final color = switch (r) {
              'W' => MidnightPitchTheme.successGreen,
              'D' => const Color(0xFFFF8C00), // Orange for draws
              'L' => MidnightPitchTheme.liveRed,
              _ => MidnightPitchTheme.mutedText,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: Text(
                  r,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.headingFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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
  // HORIZONTAL TAB BAR
  // ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = [
      _TabData('LIVE', Icons.sensors_rounded, Icons.circle),
      _TabData('UPCOMING', Icons.event_rounded, Icons.circle),
      _TabData('HISTORY', Icons.history_rounded, Icons.circle),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = _selectedTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : MidnightPitchTheme.ghostBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: 16,
                          color: isSelected ? Colors.white : MidnightPitchTheme.mutedText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : MidnightPitchTheme.mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (i == 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : MidnightPitchTheme.liveRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
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

  // ─────────────────────────────────────────────────────────────────
  // LIVE SECTION
  // ─────────────────────────────────────────────────────────────────

  Widget _buildLiveSection() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) {
      return _buildEmptyLiveMatch();
    }

    final homeName = currentMatch.homeTeamName.isNotEmpty ? currentMatch.homeTeamName : 'Home';
    final awayName = currentMatch.awayTeamName ?? 'Away';
    final goals = liveState.events.where((e) => e.type == 'goal').length;
    final minute = timerState.currentMinute;
    final half = timerState.currentHalf == 1 ? '1ST' : '2ND';
    final displayTime = "$minute' $half";

    return MotionCard(
      staggerIndex: 0,
      glowColor: MidnightPitchTheme.liveRed,
      onTap: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
      child: Column(
        children: [
          // Live badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIVE MATCH', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: MidnightPitchTheme.mutedText, letterSpacing: 2)),
              _LivePulsingBadge(time: displayTime),
            ],
          ),
          const SizedBox(height: 20),

          // Teams + Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TeamBadge(name: homeName, isHome: true),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text('${liveState.homeScore}', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 48, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: MidnightPitchTheme.mutedText, shape: BoxShape.circle)),
                  Text('${liveState.awayScore}', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 48, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
                ],
              ),
              const SizedBox(width: 20),
              _TeamBadge(name: awayName, isHome: false),
            ],
          ),
          const SizedBox(height: 8),

          // Team names
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Text(homeName, textAlign: TextAlign.right, style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: MidnightPitchTheme.secondaryText))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('vs', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: MidnightPitchTheme.mutedText))),
              Expanded(child: Text(awayName, textAlign: TextAlign.left, style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: MidnightPitchTheme.secondaryText))),
            ],
          ),
          const SizedBox(height: 16),

          // Goals count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: MidnightPitchTheme.neuLight, offset: const Offset(-2, -2), blurRadius: 4),
                BoxShadow(color: MidnightPitchTheme.neuDark.withValues(alpha: 0.4), offset: const Offset(2, 2), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, size: 14, color: MidnightPitchTheme.electricBlue),
                const SizedBox(width: 6),
                Text('$goals goals scored', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: MidnightPitchTheme.primaryText)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.liveMatch, extra: currentMatch),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text('RESUME MATCH', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MidnightPitchTheme.electricBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLiveMatch() {
    return MotionCard(
      staggerIndex: 0,
      child: Column(
        children: [
          Icon(Icons.sports_soccer_rounded, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No Live Match', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
          const SizedBox(height: 4),
          Text('Start or join a match to see it here', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, color: MidnightPitchTheme.mutedText)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // UPCOMING SECTION
  // ─────────────────────────────────────────────────────────────────

  Widget _buildUpcomingSection() {
    final matchState = ref.watch(matchProvider);
    final userId = ref.read(authProvider).userId;

    final upcoming = matchState.upcomingMatches.where((m) {
      return m.status == 'upcoming' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (upcoming.isEmpty) {
      return MotionCard(
        staggerIndex: 0,
        child: Column(
          children: [
            Icon(Icons.event_outlined, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No Upcoming Matches', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
            const SizedBox(height: 4),
            Text('Create a match to get started', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, color: MidnightPitchTheme.mutedText)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${upcoming.length} UPCOMING', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: MidnightPitchTheme.mutedText, letterSpacing: 2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: MidnightPitchTheme.championGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('${upcoming.length}', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: MidnightPitchTheme.championGold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...upcoming.take(5).map((m) => _buildUpcomingCard(m)),
      ],
    );
  }

  Widget _buildUpcomingCard(MatchModel match) {
    final homeName = match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home';
    final awayName = match.awayTeamName ?? 'Away';
    final timeStr = '${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MotionCard(
        staggerIndex: 0,
        glowColor: MidnightPitchTheme.championGold,
        onTap: () => context.go(AppRoutes.matchDetail, extra: match),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date block
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: MidnightPitchTheme.championGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text('${match.matchDate.day}', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: MidnightPitchTheme.championGold)),
                  Text(_getMonthAbbr(match.matchDate.month), style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 9, fontWeight: FontWeight.w600, color: MidnightPitchTheme.championGold)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$homeName vs $awayName', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: MidnightPitchTheme.mutedText),
                      const SizedBox(width: 4),
                      Text(timeStr, style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 11, color: MidnightPitchTheme.mutedText)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(match.format.toUpperCase(), style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 9, fontWeight: FontWeight.w700, color: MidnightPitchTheme.electricBlue)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: MidnightPitchTheme.mutedText, size: 22),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HISTORY SECTION
  // ─────────────────────────────────────────────────────────────────

  Widget _buildHistorySection() {
    final matchState = ref.watch(matchProvider);
    final userId = ref.read(authProvider).userId;

    final completed = matchState.recentMatches.where((m) {
      return m.status == 'completed' &&
          (m.homeTeamId == userId || m.awayTeamId == userId || m.createdBy == userId);
    }).toList();

    if (completed.isEmpty) {
      return MotionCard(
        staggerIndex: 0,
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No Match History', style: TextStyle(fontFamily: MidnightPitchTheme.headingFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText)),
            const SizedBox(height: 4),
            Text('Completed matches will appear here', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, color: MidnightPitchTheme.mutedText)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MATCH HISTORY', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: MidnightPitchTheme.mutedText, letterSpacing: 2)),
        const SizedBox(height: 10),
        ...completed.take(5).map((m) => _buildHistoryCard(m, userId)),
      ],
    );
  }

  Widget _buildHistoryCard(MatchModel match, String? userId) {
    final homeWon = match.homeScore > match.awayScore;
    final isHome = match.homeTeamId == userId || match.createdBy == userId;
    final resultLabel = homeWon
        ? (isHome ? 'WIN' : 'LOSS')
        : match.homeScore < match.awayScore
            ? (isHome ? 'LOSS' : 'WIN')
            : 'DRAW';
    final resultColor = switch (resultLabel) {
      'WIN' => MidnightPitchTheme.electricBlue,
      'LOSS' => MidnightPitchTheme.liveRed,
      _ => MidnightPitchTheme.championGold,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MotionCard(
        staggerIndex: 0,
        border: Border.all(color: resultColor.withValues(alpha: 0.25), width: 1.5),
        glowColor: resultColor,
        onTap: () => context.go(AppRoutes.matchSummary, extra: match),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Result badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: resultColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                resultLabel[0],
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: MidnightPitchTheme.primaryText)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('${match.homeScore} - ${match.awayScore}', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w800, color: MidnightPitchTheme.electricBlue)),
                      ),
                      Text(match.awayTeamName ?? 'Away', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: MidnightPitchTheme.primaryText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                        child: Text(match.format.toUpperCase(), style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 9, fontWeight: FontWeight.w600, color: MidnightPitchTheme.mutedText)),
                      ),
                      const Spacer(),
                      Text('${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10, color: MidnightPitchTheme.mutedText)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: resultColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

// ─────────────────────────────────────────────────────────────────
// HELPER DATA CLASSES
// ─────────────────────────────────────────────────────────────────

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickActionData(this.icon, this.label, this.color, this.onTap);
}

class _TabData {
  final String label;
  final IconData icon;
  final IconData badgeIcon;

  _TabData(this.label, this.icon, this.badgeIcon);
}

// ─────────────────────────────────────────────────────────────────
// ANIMATED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _AnimatedActionChip extends StatefulWidget {
  final _QuickActionData data;
  final int delay;

  const _AnimatedActionChip({required this.data, required this.delay});

  @override
  State<_AnimatedActionChip> createState() => _AnimatedActionChipState();
}

class _AnimatedActionChipState extends State<_AnimatedActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _entryAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 400 + widget.delay),
      vsync: this,
    );
    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _entryAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.data.onTap(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.data.color.withValues(alpha: 0.2)
                : widget.data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.data.color.withValues(alpha: _isPressed ? 0.5 : 0.25),
              width: 1.5,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.data.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.data.icon, size: 18, color: widget.data.color),
              const SizedBox(width: 8),
              Text(
                widget.data.label,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.data.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePulsingBadge extends StatefulWidget {
  final String time;
  const _LivePulsingBadge({required this.time});

  @override
  State<_LivePulsingBadge> createState() => _LivePulsingBadgeState();
}

class _LivePulsingBadgeState extends State<_LivePulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.liveRed,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.liveRed.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4 + (0.6 * _ctrl.value)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.time,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String name;
  final bool isHome;

  const _TeamBadge({required this.name, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: MidnightPitchTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.neuBase,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.shield_outlined, color: MidnightPitchTheme.electricBlue, size: 24),
          ),
        ),
      ],
    );
  }
}