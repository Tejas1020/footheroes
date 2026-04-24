import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/team_provider.dart';
import '../../../../providers/squad_provider.dart';
import '../../../../providers/live_match_provider.dart';
import '../../../../providers/match_timer_provider.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../widgets/empty_state_widget.dart';
import '../../../../../widgets/skeleton_loader.dart';
import '../../../../../widgets/motion_card.dart';

/// Coach Home Widget - redesigned for Dark Colour System.
class CoachHomeWidget extends ConsumerStatefulWidget {
  const CoachHomeWidget({super.key});

  @override
  ConsumerState<CoachHomeWidget> createState() => _CoachHomeWidgetState();
}

class _CoachHomeWidgetState extends ConsumerState<CoachHomeWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) return;

    ref.read(teamProvider.notifier).loadUserTeams(userId).then((_) {
      final teamState = ref.read(teamProvider);
      final currentTeam = teamState.currentTeam;
      if (currentTeam != null) {
        ref.read(squadProvider.notifier).loadSquad(currentTeam.teamId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSquadOverview(),
          const SizedBox(height: 32),
          _buildLiveMatchCard(),
          const SizedBox(height: 32),
          _buildNextMatchCountdown(),
          const SizedBox(height: 32),
          _buildTopPerformer(),
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSquadOverview() {
    final teamState = ref.watch(teamProvider);
    final squadState = ref.watch(squadProvider);
    final currentTeam = teamState.currentTeam;
    final isLoading = teamState.status == TeamStatus.loading ||
        squadState.status == SquadStatus.loading;

    if (isLoading) return const CardSkeleton();

    if (currentTeam == null) {
      return EmptyStateWidget(
        icon: Icons.groups_outlined,
        title: 'NO TEAM SELECTED',
        subtitle: 'Join or create a team to access coach features',
        actionLabel: 'GO TO SQUAD',
        onAction: () => context.go('/home/squad'),
      );
    }

    final roster = squadState.roster;
    final availablePlayers = roster.length;
    final confirmedCount = squadState.rsvpStatus.values.where((v) => v == 'yes').length;

    return MotionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('SQUAD OVERVIEW'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardinal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentTeam.format.toUpperCase(),
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 10, color: AppTheme.cardinal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _overviewStat('PLAYERS', '$availablePlayers', AppTheme.cardinal),
              _overviewStat('RSVP', '$confirmedCount', AppTheme.navy),
              _overviewStat('HEALTH', '92%', AppTheme.rose),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.cardBorderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(currentTeam.name, style: AppTheme.bodyBold),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/home/squad'),
                child: Text('MANAGE SQUAD', style: AppTheme.labelSmall.copyWith(color: AppTheme.cardinal)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
    AppTheme.accentBar(),
    const SizedBox(width: 8),
    Text(text, style: AppTheme.labelSmall),
  ]);

  Widget _overviewStat(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: AppTheme.bebasDisplay.copyWith(fontSize: 24, color: color)),
      Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 8)),
    ]),
  );

  Widget _buildLiveMatchCard() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('LIVE MATCH'),
        const SizedBox(height: 16),
        LiveMatchCard(
          homeTeam: currentMatch.homeTeamName,
          awayTeam: currentMatch.awayTeamName ?? 'Opponent',
          homeScore: liveState.homeScore,
          awayScore: liveState.awayScore,
          timeDisplay: timerState.displayTime,
          isLive: true,
          onTap: () => context.push(AppRoutes.liveMatch, extra: currentMatch),
        ),
      ],
    );
  }

  Widget _buildNextMatchCountdown() {
    final squadState = ref.watch(squadProvider);
    final nextMatch = squadState.nextMatch;

    if (nextMatch == null) return const SizedBox.shrink();

    final diff = nextMatch.matchDate.difference(DateTime.now());
    final days = diff.inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('UPCOMING FIXTURE'),
        const SizedBox(height: 16),
        MotionCard(
          child: Column(children: [
            Row(children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.cardinal, size: 16),
              const SizedBox(width: 8),
              Text('IN $days DAYS', style: AppTheme.bebasDisplay.copyWith(fontSize: 18, color: AppTheme.parchment)),
              const Spacer(),
              _formatDate(nextMatch.matchDate),
            ]),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.cardBorderColor),
            const SizedBox(height: 16),
            Row(children: [
              _miniTeam(nextMatch.homeTeamName, isHome: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: AppTheme.bebasDisplay),
              ),
              _miniTeam(nextMatch.awayTeamName ?? 'Opponent', isHome: false),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _miniTeam(String name, {required bool isHome}) => Expanded(
    child: Text(name.toUpperCase(), 
      textAlign: isHome ? TextAlign.right : TextAlign.left,
      style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: isHome ? AppTheme.cardinal : AppTheme.navy),
      maxLines: 1, overflow: TextOverflow.ellipsis),
  );

  Widget _buildTopPerformer() {
    final squadState = ref.watch(squadProvider);
    if (squadState.roster.isEmpty) return const SizedBox.shrink();

    final topPlayer = squadState.roster.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PLAYER OF THE MONTH'),
        const SizedBox(height: 16),
        MotionCard(
          glowColor: AppTheme.cardinal,
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(gradient: AppTheme.heroCtaGradient, shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: AppTheme.parchment, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topPlayer.name.toUpperCase(), style: AppTheme.bebasDisplay.copyWith(fontSize: 18)),
                  Text(topPlayer.position, style: AppTheme.labelSmall),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.cardinal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('MANAGER ACTIONS'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _action('Lineup', Icons.dashboard_customize_rounded, AppTheme.cardinal),
            _action('Session', Icons.calendar_today_rounded, AppTheme.navy),
            _action('Analytics', Icons.analytics_rounded, AppTheme.rose),
            _action('Settings', Icons.settings_rounded, AppTheme.gold),
          ],
        ),
      ],
    );
  }

  Widget _action(String l, IconData i, Color c) => Column(children: [
    Container(
      width: 64, height: 64,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Icon(i, color: c, size: 24),
    ),
    const SizedBox(height: 8),
    Text(l.toUpperCase(), style: AppTheme.labelSmall.copyWith(fontSize: 8)),
  ]);

  Widget _formatDate(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return Text('${d.day} ${months[d.month - 1]}', style: AppTheme.labelSmall);
  }
}
