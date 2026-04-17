import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/midnight_pitch_theme.dart';
import '../models/match_event_model.dart';
import '../models/match_model.dart';
import '../providers/post_match_provider.dart';
import '../providers/auth_provider.dart';

/// Match Summary screen — pro-style tabbed layout:
/// Summary (scoreboard + MOTM + performance) | Stats (team comparison) | Timeline
class MatchSummaryScreen extends ConsumerStatefulWidget {
  final String? matchId;
  final VoidCallback? onBack;
  final VoidCallback? onGoHome;
  final VoidCallback? onViewComparison;

  const MatchSummaryScreen({
    super.key,
    this.matchId,
    this.onBack,
    this.onGoHome,
    this.onViewComparison,
  });

  @override
  ConsumerState<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends ConsumerState<MatchSummaryScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  static const _tabs = ['Summary', 'Stats', 'Timeline'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatchSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchSummary() async {
    final matchId = widget.matchId;
    final userId = ref.read(authProvider).userId;
    if (matchId != null) {
      await ref.read(postMatchProvider.notifier).loadMatchSummary(matchId, currentUserId: userId);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _shareScorecard() async {
    await SharePlus.instance.share(ShareParams(text: 'Check out the match scorecard on FootHeroes!'));
  }

  Future<void> _sharePlayerCard() async {
    await SharePlus.instance.share(ShareParams(text: 'Check out my player rating on FootHeroes!'));
  }

  void _voteForMotm(String playerId) async {
    final matchId = widget.matchId;
    final userId = ref.read(authProvider).userId;
    if (matchId != null && userId != null) {
      await ref.read(postMatchProvider.notifier).voteManOfTheMatch(matchId, playerId, userId);
    }
  }

  // =============================================================================
  // BUILD
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    final postMatchState = ref.watch(postMatchProvider);
    final authState = ref.watch(authProvider);

    if (_isLoading || postMatchState.isLoading) {
      return Scaffold(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        body: Center(
          child: CircularProgressIndicator(color: MidnightPitchTheme.electricMint),
        ),
      );
    }

    final match = postMatchState.match;
    final events = postMatchState.events;
    final playerStats = postMatchState.playerStats;
    final topRated = postMatchState.getTopRatedPlayers();
    final manOfTheMatchId = postMatchState.manOfTheMatchId;
    final hasVoted = postMatchState.hasVoted;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildScoreboard(match),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(match, events, playerStats, topRated, manOfTheMatchId, hasVoted, authState),
                  _buildStatsTab(events, playerStats, match),
                  _buildTimelineTab(events),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // SCOREBOARD — persistent header above tabs
  // =============================================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: MidnightPitchTheme.surfaceDim,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios, color: MidnightPitchTheme.primaryText, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'MATCH REPORT',
            style: MidnightPitchTheme.titleMD.copyWith(
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _shareScorecard,
            child: Icon(Icons.share, color: MidnightPitchTheme.mutedText, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(MatchModel? match) {
    final homeScore = match?.homeScore ?? 0;
    final awayScore = match?.awayScore ?? 0;
    final homeName = match?.homeTeamName ?? 'Home';
    final awayName = match?.awayTeamName ?? 'Away';

    final resultColor = homeScore > awayScore
        ? MidnightPitchTheme.electricMint
        : homeScore < awayScore
            ? MidnightPitchTheme.liveRed
            : MidnightPitchTheme.championGold;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: MidnightPitchTheme.surfaceDim,
      child: Column(
        children: [
          // FULL TIME label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FULL TIME',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: resultColor,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Teams + Score row
          Row(
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.shield_outlined, color: MidnightPitchTheme.electricMint, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      homeName,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$homeScore',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: MidnightPitchTheme.primaryText,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '-',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: MidnightPitchTheme.mutedText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$awayScore',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: MidnightPitchTheme.primaryText,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ],
              ),
              // Away team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.shield_outlined, color: MidnightPitchTheme.mutedText, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      awayName,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Venue line
          if (match?.venue != null && match!.venue!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: MidnightPitchTheme.mutedText),
                const SizedBox(width: 4),
                Text(
                  match.venue!,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(match.matchDate),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================================
  // TAB BAR
  // =============================================================================

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MidnightPitchTheme.surfaceContainerHighest, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: MidnightPitchTheme.electricMint,
        unselectedLabelColor: MidnightPitchTheme.mutedText,
        indicatorColor: MidnightPitchTheme.electricMint,
        indicatorWeight: 2,
        labelStyle: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // =============================================================================
  // TAB 1: SUMMARY — MOTM, your performance, share, delete
  // =============================================================================

  Widget _buildSummaryTab(
    MatchModel? match,
    List<MatchEventModel> events,
    Map<String, PlayerStats> playerStats,
    List<String> topRated,
    String? manOfTheMatchId,
    bool hasVoted,
    AuthState authState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal scorers quick list
          _buildGoalScorers(events),
          const SizedBox(height: 24),
          // MOTM
          _buildMotmVoting(topRated, manOfTheMatchId, hasVoted, playerStats),
          // Your performance
          if (authState.userId != null) ...[
            const SizedBox(height: 24),
            _buildPerformanceCard(authState.userId!, playerStats, manOfTheMatchId),
          ],
          const SizedBox(height: 24),
          // Player ratings table
          if (playerStats.isNotEmpty) ...[
            _buildPlayerRatingsTable(playerStats, manOfTheMatchId),
            const SizedBox(height: 24),
          ],
          // Share
          _buildShareActions(),
          // Delete
          if (match != null && authState.userId != null && authState.userId == match.createdBy) ...[
            const SizedBox(height: 24),
            _buildDeleteMatchButton(match),
          ],
        ],
      ),
    );
  }

  /// Pro-style goal scorers strip — home left, away right.
  Widget _buildGoalScorers(List<MatchEventModel> events) {
    final goals = events.where((e) => e.isGoal).toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    final homeGoals = goals.where((e) => e.team == 'home').toList()
      ..sort((a, b) => a.minute.compareTo(b.minute));
    final awayGoals = goals.where((e) => e.team == 'away').toList()
      ..sort((a, b) => a.minute.compareTo(b.minute));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer, size: 16, color: MidnightPitchTheme.electricMint),
              const SizedBox(width: 6),
              Text(
                'GOALS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home goal scorers — left aligned
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homeGoals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "${g.playerName} ${g.minute}'",
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MidnightPitchTheme.electricMint,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              // Away goal scorers — right aligned
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: awayGoals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "${g.playerName} ${g.minute}'",
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MidnightPitchTheme.primaryText,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // TAB 2: STATS — team comparison bars (pro pattern)
  // =============================================================================

  Widget _buildStatsTab(
    List<MatchEventModel> events,
    Map<String, PlayerStats> playerStats,
    MatchModel? match,
  ) {
    // Compute team-level aggregates from events
    final homeGoals = events.where((e) => e.isGoal && e.team == 'home').length;
    final awayGoals = events.where((e) => e.isGoal && e.team == 'away').length;
    final homeYellows = events.where((e) => e.isYellowCard && e.team == 'home').length;
    final awayYellows = events.where((e) => e.isYellowCard && e.team == 'away').length;
    final homeReds = events.where((e) => e.isRedCard && e.team == 'home').length;
    final awayReds = events.where((e) => e.isRedCard && e.team == 'away').length;

    // Compute from player stats
    int homeAssists = 0, awayAssists = 0;
    for (final e in events) {
      if (e.isAssist) {
        if (e.team == 'home') {
          homeAssists++;
        } else {
          awayAssists++;
        }
      }
    }

    // Player counts
    final homePlayers = playerStats.values.where((p) {
      final eventsForPlayer = events.where((e) => e.playerId == p.playerId);
      return eventsForPlayer.any((e) => e.team == 'home') || eventsForPlayer.isEmpty && p.playerId == match?.homeTeamId;
    }).length;
    final awayPlayers = playerStats.values.length - homePlayers;

    // Avg rating
    double homeAvgRating = 0, awayAvgRating = 0;
    int homeRatedCount = 0, awayRatedCount = 0;
    for (final p in playerStats.values) {
      final playerTeam = events.firstWhere(
        (e) => e.playerId == p.playerId,
        orElse: () => MatchEventModel(id: '', eventId: '', matchId: '', type: '', playerId: '', playerName: '', minute: 0, team: 'home'),
      ).team;
      if (playerTeam == 'home') {
        homeAvgRating += p.rating;
        homeRatedCount++;
      } else {
        awayAvgRating += p.rating;
        awayRatedCount++;
      }
    }
    if (homeRatedCount > 0) homeAvgRating /= homeRatedCount;
    if (awayRatedCount > 0) awayAvgRating /= awayRatedCount;

    final homeLabel = match?.homeTeamName ?? 'Home';
    final awayLabel = match?.awayTeamName ?? 'Away';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildStatComparisonRow('Goals', homeGoals, awayGoals, homeLabel, awayLabel),
          _buildStatComparisonRow('Assists', homeAssists, awayAssists, homeLabel, awayLabel),
          _buildStatComparisonRow('Yellow Cards', homeYellows, awayYellows, homeLabel, awayLabel),
          _buildStatComparisonRow('Red Cards', homeReds, awayReds, homeLabel, awayLabel),
          _buildStatComparisonRowDouble('Avg Rating', homeAvgRating, awayAvgRating, homeLabel, awayLabel),
          _buildStatComparisonRow('Players', homePlayers, awayPlayers, homeLabel, awayLabel),
        ],
      ),
    );
  }

  /// Pro-style stat comparison row with visual bars.
  Widget _buildStatComparisonRow(String label, int homeVal, int awayVal, String homeLabel, String awayLabel) {
    final total = homeVal + awayVal;
    final homePercent = total > 0 ? homeVal / total : (homeVal > awayVal ? 0.5 : homeVal == awayVal ? 0.5 : 0.0);
    final awayPercent = 1.0 - homePercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$homeVal',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: homeVal >= awayVal ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                ),
              ),
              const Expanded(child: SizedBox()),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.1,
                ),
              ),
              const Expanded(child: SizedBox()),
              Text(
                '$awayVal',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: awayVal >= homeVal ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (homePercent * 100).round().clamp(1, 99),
                  child: Container(height: 6, color: MidnightPitchTheme.electricMint),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: (awayPercent * 100).round().clamp(1, 99),
                  child: Container(height: 6, color: MidnightPitchTheme.surfaceContainerHigh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatComparisonRowDouble(String label, double homeVal, double awayVal, String homeLabel, String awayLabel) {
    return _buildStatComparisonRow(
      label,
      (homeVal * 10).round(),
      (awayVal * 10).round(),
      homeLabel,
      awayLabel,
    );
  }

  // =============================================================================
  // TAB 3: TIMELINE — event-by-event
  // =============================================================================

  Widget _buildTimelineTab(List<MatchEventModel> events) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: _buildTimelineContent(events),
    );
  }

  Widget _buildTimelineContent(List<MatchEventModel> events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
        ),
        child: Center(
          child: Text(
            'No events recorded',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      );
    }

    // Split by half
    final firstHalf = events.where((e) => e.minute <= 45).toList();
    final secondHalf = events.where((e) => e.minute > 45).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstHalf.isNotEmpty) ...[
          _buildHalfHeader('1ST HALF'),
          const SizedBox(height: 12),
          ...firstHalf.map((e) => _buildTimelineEvent(e)),
        ],
        if (secondHalf.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildHalfHeader('2ND HALF'),
          const SizedBox(height: 12),
          ...secondHalf.map((e) => _buildTimelineEvent(e)),
        ],
      ],
    );
  }

  Widget _buildHalfHeader(String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: MidnightPitchTheme.surfaceContainerHighest)),
      ],
    );
  }

  Widget _buildTimelineEvent(MatchEventModel event) {
    final (icon, color) = switch (event.type) {
      'goal' => (Icons.sports_soccer, MidnightPitchTheme.electricMint),
      'assist' => (Icons.handshake, MidnightPitchTheme.skyBlue),
      'yellowCard' => (Icons.square, MidnightPitchTheme.championGold),
      'redCard' => (Icons.square, MidnightPitchTheme.liveRed),
      'subOn' => (Icons.keyboard_double_arrow_up, MidnightPitchTheme.electricMint),
      'subOff' => (Icons.keyboard_double_arrow_down, MidnightPitchTheme.liveRed),
      _ => (Icons.circle, MidnightPitchTheme.mutedText),
    };

    final isHighlighted = event.type == 'goal' || event.type == 'assist';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "${event.minute}'",
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              shape: BoxShape.circle,
              border: isHighlighted
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.playerName,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  event.displayFull,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          // Team tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: event.team == 'home'
                  ? MidnightPitchTheme.electricMint.withValues(alpha: 0.1)
                  : MidnightPitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.team == 'home' ? 'H' : 'A',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: event.team == 'home' ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // PLAYER RATINGS TABLE
  // =============================================================================

  Widget _buildPlayerRatingsTable(Map<String, PlayerStats> playerStats, String? manOfTheMatchId) {
    final sorted = playerStats.entries.toList()
      ..sort((a, b) => b.value.rating.compareTo(a.value.rating));

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PLAYER RATINGS',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.1,
              ),
            ),
          ),
          ...sorted.map((entry) {
            final player = entry.value;
            final isMotm = entry.key == manOfTheMatchId;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: MidnightPitchTheme.surfaceContainerHighest)),
              ),
              child: Row(
                children: [
                  // Rating
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _ratingColor(player.rating).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      player.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ratingColor(player.rating),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              player.playerName,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: MidnightPitchTheme.primaryText,
                              ),
                            ),
                            if (isMotm) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.workspace_premium, size: 14, color: MidnightPitchTheme.championGold),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (player.goals > 0) _buildMiniStat('${player.goals}G', highlight: true),
                            if (player.assists > 0) _buildMiniStat('${player.assists}A', highlight: true),
                            if (player.yellowCards > 0) _buildMiniStat('${player.yellowCards}YC'),
                            if (player.redCards > 0) _buildMiniStat('RC', highlight: false, isRed: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 8.0) return MidnightPitchTheme.electricMint;
    if (rating >= 6.5) return MidnightPitchTheme.championGold;
    return MidnightPitchTheme.liveRed;
  }

  Widget _buildMiniStat(String label, {bool highlight = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isRed
              ? MidnightPitchTheme.liveRed
              : highlight
                  ? MidnightPitchTheme.electricMint
                  : MidnightPitchTheme.mutedText,
        ),
      ),
    );
  }

  // =============================================================================
  // MOTM VOTING
  // =============================================================================

  Widget _buildMotmVoting(
    List<String> topRated,
    String? manOfTheMatchId,
    bool hasVoted,
    Map<String, PlayerStats> playerStats,
  ) {
    if (topRated.isEmpty || playerStats.isEmpty) return const SizedBox.shrink();
    final postMatchState = ref.watch(postMatchProvider);
    final isVotingClosed = postMatchState.match?.motmVotingClosed ?? false;
    final matchEndTime = postMatchState.match?.matchEndTime;

    String? countdownLabel;
    if (!isVotingClosed && matchEndTime != null) {
      final deadline = matchEndTime.add(const Duration(hours: 24));
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) {
        countdownLabel = 'Voting closed';
      } else {
        final h = remaining.inHours;
        final m = remaining.inMinutes % 60;
        countdownLabel = 'Voting closes in ${h}h ${m}m';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote, color: MidnightPitchTheme.championGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'MAN OF THE MATCH',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.championGold,
                  letterSpacing: 0.1,
                ),
              ),
              if (countdownLabel != null) ...[
                const Spacer(),
                Text(
                  countdownLabel,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isVotingClosed && manOfTheMatchId != null)
            _buildMotmResult(playerStats[manOfTheMatchId])
          else if (hasVoted && manOfTheMatchId != null)
            _buildMotmResult(playerStats[manOfTheMatchId])
          else
            _buildMotmVoteOptions(topRated, playerStats),
        ],
      ),
    );
  }

  Widget _buildMotmResult(PlayerStats? player) {
    if (player == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.championGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              player.playerName.isNotEmpty ? player.playerName[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating: ${player.rating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    color: MidnightPitchTheme.championGold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.workspace_premium, color: MidnightPitchTheme.championGold, size: 28),
          if (ref.watch(postMatchProvider).match?.motmVotingClosed == true)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('WINNER', style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10, fontWeight: FontWeight.w800,
                color: MidnightPitchTheme.championGold, letterSpacing: 0.12,
              )),
            ),
        ],
      ),
    );
  }

  Widget _buildMotmVoteOptions(List<String> topRated, Map<String, PlayerStats> playerStats) {
    return Column(
      children: topRated.map((playerId) {
        final player = playerStats[playerId];
        if (player == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _voteForMotm(playerId),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      player.playerName.isNotEmpty ? player.playerName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.playerName,
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MidnightPitchTheme.primaryText,
                          ),
                        ),
                        Text(
                          _buildStatsSummary(player),
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 11,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.championGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      player.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.championGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _buildStatsSummary(PlayerStats player) {
    final parts = <String>[];
    if (player.goals > 0) parts.add('${player.goals}G');
    if (player.assists > 0) parts.add('${player.assists}A');
    if (player.yellowCards > 0) parts.add('${player.yellowCards}YC');
    if (player.redCards > 0) parts.add('RC');
    return parts.isEmpty ? 'No events' : parts.join(' · ');
  }

  // =============================================================================
  // PERFORMANCE CARD
  // =============================================================================

  Widget _buildPerformanceCard(
    String userId,
    Map<String, PlayerStats> playerStats,
    String? manOfTheMatchId,
  ) {
    final player = playerStats[userId];
    if (player == null) return const SizedBox.shrink();

    final isMotm = userId == manOfTheMatchId;

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Rating circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _ratingColor(player.rating).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ratingColor(player.rating),
                    height: 1,
                  ),
                ),
                Text(
                  'RATING',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: _ratingColor(player.rating),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
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
                      'YOUR PERFORMANCE',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.championGold,
                        letterSpacing: 0.08,
                      ),
                    ),
                    if (isMotm) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.workspace_premium, size: 14, color: MidnightPitchTheme.championGold),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.playerName,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (player.goals > 0) _buildStatTag('${player.goals}G', highlight: true),
                    if (player.assists > 0) _buildStatTag('${player.assists}A', highlight: true),
                    if (player.yellowCards > 0) _buildStatTag('${player.yellowCards}YC'),
                    if (player.redCards > 0) _buildStatTag('RC'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTag(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlight ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
        ),
      ),
    );
  }

  // =============================================================================
  // SHARE ACTIONS
  // =============================================================================

  Widget _buildShareActions() {
    return Column(
      children: [
        _buildShareButton(
          icon: Icons.person,
          iconBgColor: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
          iconColor: MidnightPitchTheme.electricMint,
          title: 'Share Player Card',
          subtitle: 'Visual recap of your rating',
          borderColor: MidnightPitchTheme.electricMint.withValues(alpha: 0.25),
          onTap: _sharePlayerCard,
        ),
        const SizedBox(height: 12),
        _buildShareButton(
          icon: Icons.scoreboard,
          iconBgColor: MidnightPitchTheme.surfaceContainer,
          iconColor: MidnightPitchTheme.primaryText,
          title: 'Share Match Scorecard',
          subtitle: 'Full team results and stats',
          borderColor: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
          onTap: _shareScorecard,
        ),
        const SizedBox(height: 12),
        _buildShareButton(
          icon: Icons.trending_up,
          iconBgColor: MidnightPitchTheme.championGold.withValues(alpha: 0.2),
          iconColor: MidnightPitchTheme.championGold,
          title: 'View Pro Comparison',
          subtitle: 'Compare stats with top players',
          subtitleColor: MidnightPitchTheme.championGold,
          borderColor: MidnightPitchTheme.championGold.withValues(alpha: 0.3),
          cardBgColor: MidnightPitchTheme.surfaceContainerHigh,
          onTap: widget.onViewComparison,
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    required Color borderColor,
    Color? cardBgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor ?? MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: subtitleColor ?? MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // DELETE MATCH (creator only)
  // =============================================================================

  Widget _buildDeleteMatchButton(MatchModel match) {
    return GestureDetector(
      onTap: () => _confirmDeleteMatch(match),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.liveRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.liveRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline, color: MidnightPitchTheme.liveRed, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Match',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.liveRed,
                    ),
                  ),
                  Text(
                    'Permanently remove this match and all its data',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MidnightPitchTheme.liveRed),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMatch(MatchModel match) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Delete Match?', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: Text(
          'This will permanently delete ${match.homeTeamName} vs ${match.awayTeamName ?? "Opponent"} and all associated events. This cannot be undone.',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(postMatchProvider.notifier).deleteMatch(match.matchId);
              if (!mounted) return;
              if (success) {
                if (widget.onGoHome != null) {
                  widget.onGoHome!();
                } else {
                  Navigator.maybePop(context);
                }
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to delete match')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.liveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // HELPERS
  // =============================================================================

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}