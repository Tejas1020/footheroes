import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/auth_provider.dart';
import '../models/leaderboard_model.dart';

/// Leaderboard screen — podium rankings, full standings,
/// filter tabs, and trend indicators.
class LeaderboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const LeaderboardScreen({super.key, this.onBack});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _selectedTab = 0; // 0=Area, 1=Position, 2=Team
  int _selectedFilter = 0; // 0=This month, 1=This season, 2=All time

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(leaderboardProvider.notifier).loadLeaderboard();
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    final tabs = ['area', 'position', 'team'];
    ref.read(leaderboardProvider.notifier).setTab(tabs[index]);
  }

  void _onFilterChanged(int index) {
    setState(() => _selectedFilter = index);
    final timeframes = ['monthly', 'seasonal', 'alltime'];
    ref.read(leaderboardProvider.notifier).setTimeframe(timeframes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final isLoading = leaderboardState.status == LeaderboardStatus.loading;
    final currentUserId = ref.watch(authProvider).userId;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: MidnightPitchTheme.electricMint),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabs(),
                          const SizedBox(height: 16),
                          _buildFilters(),
                          const SizedBox(height: 32),
                          _buildPodium(leaderboardState.rankings),
                          const SizedBox(height: 32),
                          _buildStandingsHeader(leaderboardState.activeArea),
                          const SizedBox(height: 12),
                          _buildRankingsList(leaderboardState.rankings, currentUserId),
                        ],
                      ),
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
            'LEADERBOARDS',
            style: MidnightPitchTheme.titleMD.copyWith(
              color: MidnightPitchTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // TABS & FILTERS
  // =============================================================================

  Widget _buildTabs() {
    const tabs = ['Area', 'Position', 'Team'];
    return Row(
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isActive = index == _selectedTab;
        return GestureDetector(
          onTap: () => _onTabChanged(index),
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 32,
                  color: isActive ? MidnightPitchTheme.electricMint : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    const filters = ['This month', 'This season', 'All time'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = index == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onFilterChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? MidnightPitchTheme.electricMint.withValues(alpha: 0.2)
                      : MidnightPitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? Border.all(color: MidnightPitchTheme.electricMint.withValues(alpha: 0.3))
                      : Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? MidnightPitchTheme.electricMintLight : MidnightPitchTheme.mutedText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =============================================================================
  // PODIUM — 2nd, 1st, 3rd
  // =============================================================================

  Widget _buildPodium(List<RankingEntry> rankings) {
    // Get top 3 for podium (or use placeholders if not enough data)
    final top3 = rankings.take(3).toList();

    // Fill with placeholders if needed
    while (top3.length < 3) {
      top3.add(RankingEntry(
        rank: top3.length + 1,
        userId: '',
        name: '---',
        location: '---',
        goals: 0,
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        Expanded(child: _buildPodiumSlot(
          rank: 2,
          name: top3.length > 1 ? top3[1].name : 'J. Davidson',
          stat: top3.length > 1 ? '${top3[1].goals} G' : '21 G',
          medalColor: MidnightPitchTheme.secondaryText,
          height: 112,
        )),
        const SizedBox(width: 8),
        // 1st place
        Expanded(child: _buildPodiumSlot(
          rank: 1,
          name: top3.isNotEmpty ? top3[0].name : 'Alex Hunter',
          stat: top3.isNotEmpty ? '${top3[0].goals} G' : '24 G',
          medalColor: MidnightPitchTheme.championGold,
          height: 144,
          isChampion: true,
        )),
        const SizedBox(width: 8),
        // 3rd place
        Expanded(child: _buildPodiumSlot(
          rank: 3,
          name: top3.length > 2 ? top3[2].name : 'L. Thompson',
          stat: top3.length > 2 ? '${top3[2].goals} G' : '19 G',
          medalColor: const Color(0xFFCD7F32),
          height: 96,
        )),
      ],
    );
  }

  Widget _buildPodiumSlot({
    required int rank,
    required String name,
    required String stat,
    required Color medalColor,
    required double height,
    bool isChampion = false,
  }) {
    return Column(
      children: [
        // Crown for 1st place
        if (isChampion) ...[
          const Icon(Icons.military_tech, color: MidnightPitchTheme.championGold, size: 32),
          const SizedBox(height: 4),
        ],
        // Avatar circle
        Container(
          width: isChampion ? 80 : 64,
          height: isChampion ? 80 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [medalColor, medalColor.withValues(alpha: 0.6)],
            ),
          ),
          padding: EdgeInsets.all(isChampion ? 6 : 4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MidnightPitchTheme.surfaceContainer,
            ),
            alignment: Alignment.center,
            child: Text(
              name.substring(0, 1),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: isChampion ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Card
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isChampion ? 16 : 12),
              topRight: Radius.circular(isChampion ? 16 : 12),
            ),
            border: Border(
              top: BorderSide(color: medalColor.withValues(alpha: isChampion ? 0.5 : 0.3), width: isChampion ? 2 : 1),
              left: BorderSide(color: medalColor.withValues(alpha: 0.3), width: 1),
              right: BorderSide(color: medalColor.withValues(alpha: 0.3), width: 1),
              bottom: BorderSide(color: MidnightPitchTheme.surfaceContainerHighest),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rank == 1 ? 'CHAMPION' : rank == 2 ? 'SILVER' : 'BRONZE',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: medalColor,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: isChampion ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: stat.split(' ').first,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: isChampion ? 24 : 18,
                        fontWeight: FontWeight.w800,
                        color: rank == 1 ? MidnightPitchTheme.electricMint : rank == 2 ? MidnightPitchTheme.skyBlue : MidnightPitchTheme.championGold,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: ' ${stat.split(' ').last}',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // STANDINGS & RANKINGS
  // =============================================================================

  Widget _buildStandingsHeader(String activeArea) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'FULL STANDINGS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: 0.02,
          ),
        ),
        Text(
          'REGION: ${activeArea.toUpperCase()}',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(List<RankingEntry> rankings, String? currentUserId) {
    // Get rankings after top 3 for the list
    final remainingRankings = rankings.skip(3).toList();

    // If no data, show placeholders
    if (remainingRankings.isEmpty && rankings.isEmpty) {
      const fallbackRankings = [
        _RankEntry(4, 'Sam Wells', 'Hackney', 17, trendUp: true, trendVal: 2),
        _RankEntry(5, 'Chris Evans', 'Islington', 15, trendUp: false, trendVal: 1),
        _RankEntry(12, 'Marcus Kane', 'Bromley', 11, trendUp: true, trendVal: 3, isMe: true),
        _RankEntry(13, 'Daniel Ricci', 'Croydon', 10, trendFlat: true),
      ];
      return Column(
        children: fallbackRankings.map((entry) => _buildRankRow(entry)).toList(),
      );
    }

    return Column(
      children: remainingRankings.map((entry) {
        final isMe = currentUserId != null && entry.userId == currentUserId;
        return _buildRankRowFromEntry(entry, isMe);
      }).toList(),
    );
  }

  Widget _buildRankRowFromEntry(RankingEntry entry, bool isMe) {
    final trendColor = entry.trendUp == true
        ? MidnightPitchTheme.electricMint
        : entry.trendUp == false
            ? MidnightPitchTheme.liveRed
            : MidnightPitchTheme.skyBlue;

    final trendIcon = entry.trendUp == true
        ? Icons.trending_up
        : entry.trendUp == false
            ? Icons.trending_down
            : Icons.remove;

    final trendVal = entry.trendValue ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe
            ? MidnightPitchTheme.electricMint.withValues(alpha: 0.1)
            : MidnightPitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border(left: BorderSide(color: MidnightPitchTheme.electricMint, width: 3))
            : Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 20,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                color: isMe ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MidnightPitchTheme.surfaceContainerHigh,
              border: isMe ? Border.all(color: MidnightPitchTheme.electricMint, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                    color: isMe ? MidnightPitchTheme.electricMintLight : MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  entry.location.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          // Goals + Trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.goals} goals',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '$trendVal',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(_RankEntry entry) {
    final trendColor = entry.trendUp == true
        ? MidnightPitchTheme.electricMint
        : entry.trendUp == false
            ? MidnightPitchTheme.liveRed
            : MidnightPitchTheme.skyBlue;

    final trendIcon = entry.trendUp == true
        ? Icons.trending_up
        : entry.trendUp == false
            ? Icons.trending_down
            : Icons.remove;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isMe
            ? MidnightPitchTheme.electricMint.withValues(alpha: 0.1)
            : MidnightPitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: entry.isMe
            ? Border(left: BorderSide(color: MidnightPitchTheme.electricMint, width: 3))
            : Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 20,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: entry.isMe ? FontWeight.w800 : FontWeight.w700,
                color: entry.isMe ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MidnightPitchTheme.surfaceContainerHigh,
              border: entry.isMe ? Border.all(color: MidnightPitchTheme.electricMint, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              entry.name.split(' ').map((n) => n[0]).join(),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: entry.isMe ? FontWeight.w700 : FontWeight.w600,
                    color: entry.isMe ? MidnightPitchTheme.electricMintLight : MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  entry.location.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          // Goals + Trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.goals} goals',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.trendVal}',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankEntry {
  final int rank;
  final String name;
  final String location;
  final int goals;
  final bool? trendUp;
  final int trendVal;
  final bool isMe;
  final bool trendFlat;

  const _RankEntry(this.rank, this.name, this.location, this.goals, {this.trendUp, this.trendVal = 0, this.isMe = false, this.trendFlat = false});
}