import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/models/career_stats.dart';
import 'package:footheroes/providers/season_stats_provider.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_provider.dart';
import 'package:footheroes/core/utils/season_util.dart';
import 'package:footheroes/widgets/cards.dart';
import 'package:footheroes/widgets/premium_app_bar.dart';
import 'package:footheroes/widgets/wavy_divider.dart';

class SeasonStatsScreen extends ConsumerStatefulWidget {
  const SeasonStatsScreen({super.key});

  @override
  ConsumerState<SeasonStatsScreen> createState() => _SeasonStatsScreenState();
}

class _SeasonStatsScreenState extends ConsumerState<SeasonStatsScreen> {
  late String _selectedSeason;

  /// Generate all seasons from firstYear to the upcoming season.
  List<String> _allSeasons() {
    final now = DateTime.now();
    // Current season label for "now"
    final currentLabel = SeasonUtil.seasonLabel(now);
    final currentStartYear = int.parse(currentLabel.split('/').first);
    // Show from 2020/21 up to one season ahead
    final firstYear = 2020;
    final lastYear = currentStartYear + 1;
    final seasons = <String>[];
    for (int y = firstYear; y <= lastYear; y++) {
      final suffix = ((y + 1) % 100).toString().padLeft(2, '0');
      seasons.add('$y/$suffix');
    }
    return seasons.reversed.toList(); // newest first
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedSeason = SeasonUtil.seasonLabel(now);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userId = auth.userId;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.voidBg,
        body: Center(
          child: Text('Sign in to view stats',
              style: AppTheme.bodyReg.copyWith(color: AppTheme.parchment)),
        ),
      );
    }

    final allSeasons = _allSeasons();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: AppTheme.radialGlowOverlay),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              PremiumAppBar(
                title: 'SEASON STATS',
                showBackButton: true,
                onBack: () => context.pop(),
              ),
              const WavyDivider(height: 8),
              // Dropdown season selector
              _buildSeasonDropdown(allSeasons),
              const SizedBox(height: 20),
              Expanded(
                child: _buildSeasonStats(userId, _selectedSeason),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonDropdown(List<String> seasons) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: AppTheme.cardBorderLight,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedSeason,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.cardinal, size: 24),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14),
            items: seasons.map((season) {
              return DropdownMenuItem(
                value: season,
                child: Text(season,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 16,
                      fontWeight: season == _selectedSeason
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: Colors.black87,
                    )),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedSeason = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonStats(String userId, String season) {
    final statsAsync =
        ref.watch(seasonStatsProvider((userId: userId, season: season)));

    return statsAsync.when(
      loading: () => _buildStatsLoading(),
      error: (err, _) => _buildStatsError(err.toString()),
      data: (stats) {
        if (stats.appearances == 0) {
          return _buildNoMatchesInSeason(season);
        }
        return _buildStatsList(stats, userId, season);
      },
    );
  }

  Widget _buildStatsList(CareerStats stats, String userId, String season) {
    final matchState = ref.watch(matchProvider);

    final formResults = <FormResult>[];
    final seasonMatches = matchState.recentMatches.where((m) {
      return m.status == 'completed' &&
          SeasonUtil.isInSeason(m.matchDate, season);
    }).take(5).toList();

    for (final match in seasonMatches) {
      final isHome = match.homeTeamId == userId ||
          (match.createdBy == userId && match.awayTeamId != userId);
      final isAway = match.awayTeamId == userId;
      final FormResultType type;
      if (match.homeScore == match.awayScore) {
        type = FormResultType.draw;
      } else {
        final userWon = (isHome && match.homeScore > match.awayScore) ||
            (isAway && match.awayScore > match.homeScore);
        type = userWon ? FormResultType.win : FormResultType.loss;
      }
      formResults.add(FormResult(type: type, dayLabel: ''));
    }

    final wins = formResults.where((f) => f.type == FormResultType.win).length;
    final streakLabel = wins >= 3 ? '🔥 $wins WIN STREAK' : null;

    final auth = ref.watch(authProvider);
    final name = auth.name ?? 'Player';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey(season),
          children: [
            HeroCard(
              sectionLabel: '$season SEASON',
              playerName: name,
              position: stats.primaryPosition.isNotEmpty
                  ? stats.primaryPosition
                  : 'Forward',
              league: stats.teamName ?? 'Sunday League',
              matchesPlayed: stats.appearances,
              avgRating: stats.avgRating,
              stats: [
                HeroStatData(label: 'GOALS', value: '${stats.goals}'),
                HeroStatData(label: 'ASSISTS', value: '${stats.assists}'),
                HeroStatData(label: 'WINS', value: '${stats.wins}'),
                HeroStatData(
                    label: 'WIN RATE',
                    value: '${stats.winRate.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    label: 'Goals',
                    value: '${stats.goals}',
                    trend: '${stats.goalsPerGame.toStringAsFixed(1)} per game',
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
            BreakdownCard(
              label: 'Season breakdown',
              stats: [
                BreakdownStat(label: 'DRAWS', value: '${stats.draws}'),
                BreakdownStat(label: 'LOSSES', value: '${stats.losses}'),
                BreakdownStat(label: 'CLEAN SH.', value: '${stats.cleanSheets}'),
                BreakdownStat(
                  label: 'YELLOW',
                  value: '${stats.yellowCards}',
                  valueColor: AppTheme.brandOrange,
                  valueGradient: AppTheme.brandGradient,
                ),
                BreakdownStat(
                  label: 'RED',
                  value: '${stats.redCards}',
                  valueColor: AppTheme.deepRed,
                  valueGradient: AppTheme.redGradient,
                ),
              ],
            ),
            if (formResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              DarkCard(
                label: 'Recent Form',
                form: formResults,
                streak: streakLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: AppTheme.cardinal),
      ),
    );
  }

  Widget _buildStatsError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48,
              color: AppTheme.cardinal.withAlpha(100)),
          const SizedBox(height: 12),
          Text('Failed to load stats',
              style: AppTheme.bodyReg.copyWith(color: AppTheme.parchment)),
        ],
      ),
    );
  }

  Widget _buildNoMatchesInSeason(String season) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer_rounded, size: 48,
              color: AppTheme.gold.withAlpha(60)),
          const SizedBox(height: 16),
          Text('No Matches in $season',
              style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text('Stats will appear here once you play matches in this season',
              textAlign: TextAlign.center,
              style: AppTheme.bodyReg.copyWith(
                  fontSize: 12, color: AppTheme.gold)),
        ],
      ),
    );
  }
}
