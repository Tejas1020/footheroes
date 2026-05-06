import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/models/match_event_model.dart';
import 'package:footheroes/models/match_model.dart';
import 'package:footheroes/providers/post_match_provider.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/features/match/data/models/live_match_models.dart';
import 'package:footheroes/models/formation_model.dart';
import 'package:footheroes/providers/match_roster_provider.dart';
import 'package:footheroes/widgets/simple_venue_map_sheet.dart';
import '../widgets/unified_pitch_widget.dart';

// =============================================================================
// MATCH SUMMARY SCREEN — Full Visual Upgrade per Screen 4 spec
// =============================================================================
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
      final matchId = widget.matchId;
      if (matchId != null) {
        ref.read(matchRosterProvider.notifier).loadRoster(matchId);
      }
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
    await SharePlus.instance.share(ShareParams(text: 'Check out the match scorecard on Kixxon!'));
  }

  Future<void> _sharePlayerCard() async {
    await SharePlus.instance.share(ShareParams(text: 'Check out my player rating on Kixxon!'));
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
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.cardinal),
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildScoreboard(match, events, playerStats),
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
  // TOP BAR
  // =============================================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppTheme.voidBg,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onBack?.call(),
            child: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'MATCH REPORT',
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 18,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _shareScorecard,
            child: const Icon(Icons.share, color: AppTheme.gold, size: 22),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // SCOREBOARD — GradientB + GradientF overlay
  // =============================================================================

  Widget _buildScoreboard(MatchModel? match, List<MatchEventModel> events, Map<String, PlayerStats> playerStats) {
    final homeScore = match?.homeScore ?? 0;
    final awayScore = match?.awayScore ?? 0;
    final homeName = match?.homeTeamName ?? 'Home';
    final awayName = match?.awayTeamName ?? 'Away';

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardSurfaceGradient,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              // FULL TIME badge: GradientA bg, Bebas Neue 11sp, radius 20px
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroCtaGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0x5000458E), blurRadius: 8),
                  ],
                ),
                child: Text(
                  'FULL TIME',
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Teams + Score row
              Row(
                children: [
                  // Home team shield
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroCtaGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.shieldShadow,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.shield, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          homeName,
                          style: AppTheme.bebasDisplay.copyWith(
                            fontSize: 16,
                            color: AppTheme.cardinal,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$homeScore',
                        style: AppTheme.bebasDisplay.copyWith(fontSize: 56),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '-',
                          style: AppTheme.bebasDisplay.copyWith(fontSize: 36, color: AppTheme.redMid),
                        ),
                      ),
                      Text(
                        '$awayScore',
                        style: AppTheme.bebasDisplay.copyWith(fontSize: 56),
                      ),
                    ],
                  ),
                  // Away team shield
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.awayDataGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.awayShieldShadow,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.shield, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          awayName,
                          style: AppTheme.bebasDisplay.copyWith(
                            fontSize: 16,
                            color: AppTheme.gold,
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
              if (match?.venue != null && match!.venue!.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: (match.venueLatitude != null && match.venueLongitude != null)
                      ? () => showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => SimpleVenueMapSheet(
                              name: match.venue!,
                              latitude: match.venueLatitude!,
                              longitude: match.venueLongitude!,
                            ),
                          )
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.cardinal),
                      const SizedBox(width: 4),
                      Text(
                        match.venue!,
                        style: AppTheme.labelSmall,
                      ),
                      if (match.venueLatitude != null && match.venueLongitude != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.map, size: 12, color: AppTheme.gold),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(match.matchDate),
                        style: AppTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Teams button — opens pitch popup
              GestureDetector(
                onTap: () => _showTeamsBottomSheet(match, events, playerStats),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_soccer, size: 12, color: AppTheme.cardinal),
                      const SizedBox(width: 6),
                      Text(
                        'TEAMS',
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.parchment,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: Positioned.fill(
            child: Container(
              decoration: AppTheme.radialGlowOverlay,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // TAB BAR
  // =============================================================================

  Widget _buildTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.voidBg.withValues(alpha: 0.5),
            border: const Border(
              bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            ),
          ),
          child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.cardinal,
        unselectedLabelColor: AppTheme.mutedParchment,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.cardinal, width: 3),
        ),
        labelStyle: AppTheme.bebasDisplay.copyWith(
          fontSize: 15,
        ),
        unselectedLabelStyle: AppTheme.dmSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // TAB 1: SUMMARY
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalsCard(events),
          const SizedBox(height: 14),
          _buildMotmVoting(topRated, manOfTheMatchId, hasVoted, playerStats),
          if (authState.userId != null) ...[
            const SizedBox(height: 14),
            _buildPerformanceCard(authState.userId!, playerStats, manOfTheMatchId),
          ],
          const SizedBox(height: 14),
          if (playerStats.isNotEmpty) ...[
            _buildPlayerRatingsList(playerStats, manOfTheMatchId),
            const SizedBox(height: 14),
          ],
          _buildShareActions(),
          if (match != null && authState.userId != null && authState.userId == match.createdBy) ...[
            const SizedBox(height: 14),
            _buildDeleteMatchButton(match),
          ],
        ],
      ),
    );
  }

  // =============================================================================
  // GOALS CARD
  // =============================================================================

  Widget _buildGoalsCard(List<MatchEventModel> events) {
    final goals = events.where((e) => e.isGoal).toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    final homeGoals = goals.where((e) => e.team == 'home').toList()
      ..sort((a, b) => a.minute.compareTo(b.minute));
    final awayGoals = goals.where((e) => e.team == 'away').toList()
      ..sort((a, b) => a.minute.compareTo(b.minute));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: AppTheme.cardBorderLight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              const Icon(Icons.sports_soccer, size: 16, color: AppTheme.cardinal),
              const SizedBox(width: 8),
              Text('GOALS', style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...homeGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;
            return Column(
              children: [
                if (idx > 0) const Divider(color: AppTheme.dividerColor, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "${g.minute}'",
                        style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.cardinal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.playerName,
                          style: AppTheme.bodyBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          if (homeGoals.isNotEmpty && awayGoals.isNotEmpty)
            const Divider(color: AppTheme.dividerColor, height: 1),
          ...awayGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;
            return Column(
              children: [
                if (idx > 0) const Divider(color: AppTheme.dividerColor, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "${g.minute}'",
                        style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.playerName,
                          style: AppTheme.bodyBold.copyWith(color: AppTheme.mutedParchment),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // =============================================================================
  // MAN OF THE MATCH CARD
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: AppTheme.cardBorderLight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              const Icon(Icons.emoji_events, size: 16, color: AppTheme.cardinal),
              const SizedBox(width: 8),
              Text('MAN OF THE MATCH', style: AppTheme.labelSmall),
              if (countdownLabel != null) ...[
                const Spacer(),
                Text(countdownLabel, style: AppTheme.labelSmall.copyWith(fontSize: 10)),
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
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x2500458E)),
      ),
      child: Row(
        children: [
          // Avatar: GradientA bg, Bebas Neue initial
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroCtaGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              player.playerName.isNotEmpty ? player.playerName[0].toUpperCase() : '?',
              style: AppTheme.bebasDisplay.copyWith(fontSize: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: AppTheme.bodyBold.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating: ${player.rating.toStringAsFixed(1)}',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
          // Rating badge: GradientA bg, Bebas Neue 18sp
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.heroCtaGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppTheme.motmBadgeShadow,
            ),
            alignment: Alignment.center,
            child: Text(
              player.rating.toStringAsFixed(1),
              style: AppTheme.bebasDisplay.copyWith(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_events, color: AppTheme.cardinal, size: 28),
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
                color: AppTheme.abyss,
                borderRadius: BorderRadius.circular(12),
                border: AppTheme.cardBorder,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.cardSurface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      player.playerName.isNotEmpty ? player.playerName[0].toUpperCase() : '?',
                      style: AppTheme.bebasDisplay.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.playerName,
                          style: AppTheme.bodyBold,
                        ),
                        Text(
                          _buildStatsSummary(player),
                          style: AppTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroCtaGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      player.rating.toStringAsFixed(1),
                      style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: Colors.white),
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
  // YOUR PERFORMANCE CARD
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
      decoration: AppTheme.premiumCard,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardinal, width: 3),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.rating.toStringAsFixed(1),
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 24),
                ),
                Text(
                  'RATING',
                  style: AppTheme.labelSmall.copyWith(fontSize: 8),
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
                      style: AppTheme.labelSmall,
                    ),
                    if (isMotm) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events, size: 14, color: AppTheme.cardinal),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.playerName,
                  style: AppTheme.bodyBold.copyWith(fontSize: 16),
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
        color: highlight ? AppTheme.cardinal : AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? null : AppTheme.cardBorder,
      ),
      child: Text(
        label,
        style: AppTheme.dmSans.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlight ? AppTheme.parchment : AppTheme.gold,
        ),
      ),
    );
  }

  // =============================================================================
  // PLAYER RATINGS LIST
  // =============================================================================

  Widget _buildPlayerRatingsList(Map<String, PlayerStats> playerStats, String? manOfTheMatchId) {
    final sorted = playerStats.entries.toList()
      ..sort((a, b) => b.value.rating.compareTo(a.value.rating));

    return Container(
      decoration: AppTheme.standardCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              Text(
                'PLAYER RATINGS',
                style: AppTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final playerEntry = entry.value;
            final player = playerEntry.value;
            final isMotm = playerEntry.key == manOfTheMatchId;
            return Column(
              children: [
                if (idx > 0) const Divider(color: AppTheme.dividerColor, height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroCtaGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player.rating.toStringAsFixed(1),
                          style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: Colors.white),
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
                                  style: AppTheme.bodyBold,
                                ),
                                if (isMotm) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.emoji_events, size: 14, color: AppTheme.cardinal),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (player.goals > 0)
                                  Text(
                                    '${player.goals}G',
                                    style: AppTheme.labelSmall,
                                  ),
                                if (player.assists > 0)
                                  Text(
                                    ' · ${player.assists}A',
                                    style: AppTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
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
          title: 'Share Player Card',
          subtitle: 'Visual recap of your rating',
          onTap: _sharePlayerCard,
        ),
        const SizedBox(height: 14),
        _buildShareButton(
          icon: Icons.scoreboard,
          title: 'Share Match Scorecard',
          subtitle: 'Full team results and stats',
          onTap: _shareScorecard,
        ),
        const SizedBox(height: 14),
        _buildShareButton(
          icon: Icons.trending_up,
          title: 'View Pro Comparison',
          subtitle: 'Compare stats with top players',
          isHero: true,
          onTap: widget.onViewComparison,
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHero = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isHero
            ? AppTheme.premiumCard
            : AppTheme.standardCard,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isHero ? AppTheme.cardinal : AppTheme.elevatedSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppTheme.parchment, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyBold,
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.cardinal),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // DELETE MATCH
  // =============================================================================

  Widget _buildDeleteMatchButton(MatchModel match) {
    return GestureDetector(
      onTap: () => _confirmDeleteMatch(match),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.standardCard,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.redDeep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline, color: AppTheme.cardinal, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Match',
                    style: AppTheme.bodyBold.copyWith(color: AppTheme.cardinal),
                  ),
                  Text(
                    'Permanently remove this match and all its data',
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.cardinal),
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
        backgroundColor: AppTheme.abyss,
        title: Text('Delete Match?', style: AppTheme.bebasDisplay.copyWith(fontSize: 24)),
        content: Text(
          'This will permanently delete ${match.homeTeamName} vs ${match.awayTeamName ?? "Opponent"} and all associated events. This cannot be undone.',
          style: AppTheme.bodyReg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.bodyBold.copyWith(color: AppTheme.gold)),
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
            style: AppTheme.primaryButton,
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // TAB 2: STATS
  // =============================================================================

  Widget _buildStatsTab(
    List<MatchEventModel> events,
    Map<String, PlayerStats> playerStats,
    MatchModel? match,
  ) {
    final homeGoals = events.where((e) => e.isGoal && e.team == 'home').length;
    final awayGoals = events.where((e) => e.isGoal && e.team == 'away').length;
    final homeYellows = events.where((e) => e.isYellowCard && e.team == 'home').length;
    final awayYellows = events.where((e) => e.isYellowCard && e.team == 'away').length;
    final homeReds = events.where((e) => e.isRedCard && e.team == 'home').length;
    final awayReds = events.where((e) => e.isRedCard && e.team == 'away').length;

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

    final homePlayers = playerStats.values.where((p) {
      final eventsForPlayer = events.where((e) => e.playerId == p.playerId);
      final isHomeTeam = eventsForPlayer.any((e) => e.team == 'home') || eventsForPlayer.isEmpty && p.playerId == match?.homeTeamId;
      return isHomeTeam;
    }).length;
    final awayPlayers = playerStats.values.length - homePlayers;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StatAnimatedRow(label: 'GOALS', homeVal: homeGoals, awayVal: awayGoals),
          _StatAnimatedRow(label: 'ASSISTS', homeVal: homeAssists, awayVal: awayAssists),
          _StatAnimatedRow(label: 'YELLOW CARDS', homeVal: homeYellows, awayVal: awayYellows),
          _StatAnimatedRow(label: 'RED CARDS', homeVal: homeReds, awayVal: awayReds),
          _StatAnimatedRowDouble(label: 'AVG RATING', homeVal: homeAvgRating, awayVal: awayAvgRating),
          _StatAnimatedRow(label: 'PLAYERS', homeVal: homePlayers, awayVal: awayPlayers),
        ],
      ),
    );
  }

  // =============================================================================
  // TAB 3: TIMELINE
  // =============================================================================

  Widget _buildTimelineTab(List<MatchEventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 48, color: AppTheme.gold),
            const SizedBox(height: 16),
            Text(
              'No events recorded',
              style: AppTheme.bodyReg.copyWith(color: AppTheme.gold),
            ),
          ],
        ),
      );
    }

    final sortedEvents = List<MatchEventModel>.from(events)
      ..sort((a, b) => a.minute.compareTo(b.minute));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: AppTheme.cardinal.withValues(alpha: 0.15),
            ),
          ),
          Column(
            children: [
              _buildTimelineMarker('KICK OFF', 0),
              const SizedBox(height: 24),
              ...sortedEvents.map((e) => _buildGraphicalTimelineEvent(e)),
              const SizedBox(height: 24),
              _buildTimelineMarker('FULL TIME', 90),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(String label, int minute) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTheme.dmSans.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGraphicalTimelineEvent(MatchEventModel event) {
    final isHome = event.team == 'home';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: isHome ? _buildEventDetails(event, Alignment.centerRight) : const SizedBox.shrink(),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              "${event.minute}'",
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 14,
                color: AppTheme.cardinal,
              ),
            ),
          ),
          Expanded(
            child: !isHome ? _buildEventDetails(event, Alignment.centerLeft) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(MatchEventModel event, Alignment alignment) {
    final (icon, color) = _getEventIconAndColor(event.type);
    final isHome = event.team == 'home';

    return Column(
      crossAxisAlignment: isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHome) ...[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                event.playerName,
                style: AppTheme.bodyBold.copyWith(fontSize: 13),
                textAlign: isHome ? TextAlign.right : TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isHome) ...[
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 16),
            ],
          ],
        ),
        Text(
          event.displayFull,
          style: AppTheme.labelSmall.copyWith(fontSize: 10),
          textAlign: isHome ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  (IconData, Color) _getEventIconAndColor(String type) {
    return switch (type) {
      'goal' => (Icons.sports_soccer, AppTheme.cardinal),
      'assist' => (Icons.handshake, AppTheme.navy),
      'yellowCard' => (Icons.rectangle, AppTheme.parchment),
      'redCard' => (Icons.rectangle, AppTheme.cardinal),
      'subOn' => (Icons.keyboard_double_arrow_up, AppTheme.gold),
      'subOff' => (Icons.keyboard_double_arrow_down, AppTheme.cardinal),
      _ => (Icons.circle, AppTheme.gold),
    };
  }

  // =============================================================================
  // TEAMS BOTTOM SHEET
  // =============================================================================

  void _showTeamsBottomSheet(
    MatchModel? match,
    List<MatchEventModel> events,
    Map<String, PlayerStats> playerStats,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TeamPitchBottomSheet(
        match: match,
        events: events,
        playerStats: playerStats,
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

// =============================================================================
// TEAM PITCH BOTTOM SHEET
// =============================================================================
class _TeamPitchBottomSheet extends ConsumerWidget {
  final MatchModel? match;
  final List<MatchEventModel> events;
  final Map<String, PlayerStats> playerStats;

  const _TeamPitchBottomSheet({
    required this.match,
    required this.events,
    required this.playerStats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load roster for team assignments and positions
    final rosterState = ref.watch(matchRosterProvider);
    final homeRosterMap = {for (final e in rosterState.entries.where((e) => e.team == 'home')) e.playerId: e};
    final awayRosterMap = {for (final e in rosterState.entries.where((e) => e.team == 'away')) e.playerId: e};

    // Determine team for each player — roster is primary source of truth
    final playerTeams = <String, String>{};
    for (final entry in homeRosterMap.entries) {
      playerTeams[entry.key] = 'home';
    }
    for (final entry in awayRosterMap.entries) {
      playerTeams[entry.key] = 'away';
    }
    // Fallback to events for any player not in roster
    for (final event in events) {
      if (!playerTeams.containsKey(event.playerId)) {
        playerTeams[event.playerId] = event.team;
      }
    }
    // Only default to home if no other info exists
    for (final entry in playerStats.entries) {
      if (!playerTeams.containsKey(entry.key)) {
        playerTeams[entry.key] = 'home';
      }
    }

    // Assign formation positions to players
    final homeFormation = match?.homeFormation ?? '4-4-2';
    final awayFormation = match?.awayFormation ?? '4-4-2';
    final homeSlots = FormationTemplates.getSlotsForFormation(homeFormation);
    final awaySlots = FormationTemplates.getSlotsForFormation(awayFormation);

    final homePlayerIds = playerTeams.entries.where((e) => e.value == 'home').map((e) => e.key).toList();
    final awayPlayerIds = playerTeams.entries.where((e) => e.value == 'away').map((e) => e.key).toList();

    final homePlayers = <LivePlayerInfo>[];
    for (int i = 0; i < homePlayerIds.length; i++) {
      final pid = homePlayerIds[i];
      final rosterEntry = homeRosterMap[pid];
      final pos = rosterEntry?.position.isNotEmpty == true
          ? rosterEntry!.position
          : (i < homeSlots.length ? homeSlots[i].positionLabel : 'CM');
      homePlayers.add(LivePlayerInfo(
        id: pid,
        name: playerStats[pid]?.playerName ?? rosterEntry?.playerName ?? 'Player',
        position: pos,
        team: 'home',
      ));
    }

    final awayPlayers = <LivePlayerInfo>[];
    for (int i = 0; i < awayPlayerIds.length; i++) {
      final pid = awayPlayerIds[i];
      final rosterEntry = awayRosterMap[pid];
      final pos = rosterEntry?.position.isNotEmpty == true
          ? rosterEntry!.position
          : (i < awaySlots.length ? awaySlots[i].positionLabel : 'CM');
      awayPlayers.add(LivePlayerInfo(
        id: pid,
        name: playerStats[pid]?.playerName ?? rosterEntry?.playerName ?? 'Player',
        position: pos,
        team: 'away',
      ));
    }

    final homeEvents = events.where((e) => e.team == 'home').toList();
    final awayEvents = events.where((e) => e.team == 'away').toList();

    final homeTeamName = match?.homeTeamName ?? 'Home';
    final awayTeamName = match?.awayTeamName ?? 'Away';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.voidBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                AppTheme.accentBar(),
                const SizedBox(width: 8),
                Text(
                  'TEAM FORMATIONS',
                  style: AppTheme.labelSmall,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppTheme.gold, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: UnifiedPitchWidget(
              homePlayers: homePlayers,
              awayPlayers: awayPlayers,
              homeEvents: homeEvents,
              awayEvents: awayEvents,
              homeTeamName: homeTeamName,
              awayTeamName: awayTeamName,
              homeFormation: homeFormation,
              awayFormation: awayFormation,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =============================================================================
// ANIMATED STAT ROW
// =============================================================================
class _StatAnimatedRow extends StatefulWidget {
  final String label;
  final int homeVal;
  final int awayVal;

  const _StatAnimatedRow({
    required this.label,
    required this.homeVal,
    required this.awayVal,
  });

  @override
  State<_StatAnimatedRow> createState() => _StatAnimatedRowState();
}

class _StatAnimatedRowState extends State<_StatAnimatedRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _homeAnim;
  late Animation<double> _awayAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    final total = widget.homeVal + widget.awayVal;
    final homePercent = total > 0 ? widget.homeVal / total : (widget.homeVal > widget.awayVal ? 0.7 : widget.homeVal == widget.awayVal ? 0.5 : 0.3);
    _homeAnim = Tween<double>(begin: 0, end: homePercent).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _awayAnim = Tween<double>(begin: 0, end: 1 - homePercent).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${widget.homeVal}',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.cardinal),
              ),
              const Expanded(child: SizedBox()),
              Text(
                widget.label,
                style: AppTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const Expanded(child: SizedBox()),
              Text(
                '${widget.awayVal}',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Expanded(
                      flex: (_homeAnim.value * 100).clamp(1, 99).round(),
                      child: Container(height: 6, color: AppTheme.cardinal),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: (_awayAnim.value * 100).clamp(1, 99).round(),
                      child: Container(height: 6, color: AppTheme.navy),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatAnimatedRowDouble extends StatefulWidget {
  final String label;
  final double homeVal;
  final double awayVal;

  const _StatAnimatedRowDouble({
    required this.label,
    required this.homeVal,
    required this.awayVal,
  });

  @override
  State<_StatAnimatedRowDouble> createState() => _StatAnimatedRowDoubleState();
}

class _StatAnimatedRowDoubleState extends State<_StatAnimatedRowDouble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _homeAnim;
  late Animation<double> _awayAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    final total = widget.homeVal + widget.awayVal;
    final homePercent = total > 0 ? widget.homeVal / total : (widget.homeVal > widget.awayVal ? 0.5 : widget.homeVal == widget.awayVal ? 0.5 : 0.5);
    _homeAnim = Tween<double>(begin: 0, end: homePercent).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _awayAnim = Tween<double>(begin: 0, end: 1 - homePercent).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.homeVal.toStringAsFixed(1),
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.cardinal),
              ),
              const Expanded(child: SizedBox()),
              Text(
                widget.label,
                style: AppTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const Expanded(child: SizedBox()),
              Text(
                widget.awayVal.toStringAsFixed(1),
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Expanded(
                      flex: (_homeAnim.value * 100).clamp(1, 99).round(),
                      child: Container(height: 6, color: AppTheme.cardinal),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: (_awayAnim.value * 100).clamp(1, 99).round(),
                      child: Container(height: 6, color: AppTheme.navy),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
