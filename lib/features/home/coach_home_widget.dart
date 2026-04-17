import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/squad_provider.dart';
import '../../providers/live_match_provider.dart';
import '../../providers/match_timer_provider.dart';
import '../../core/router/app_router.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';

/// Coach Home Widget - displays coach-focused dashboard content
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
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

    if (isLoading) {
      return _buildLoadingCard();
    }

    if (currentTeam == null) {
      return _buildNoTeamCard();
    }

    final roster = squadState.roster;
    final availablePlayers = roster.length;
    final confirmedCount = squadState.rsvpStatus.values.where((v) => v == 'yes').length;
    final maybeCount = squadState.rsvpStatus.values.where((v) => v == 'maybe').length;

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MidnightPitchTheme.ambientShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MidnightPitchTheme.sectionLabel('Squad Overview'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.electricMint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentTeam.format.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.surfaceDim,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSquadStat(
                  Icons.check_circle_outline,
                  '$availablePlayers',
                  'Available',
                  MidnightPitchTheme.electricMint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSquadStat(
                  Icons.check_circle_outline,
                  '$confirmedCount',
                  'Confirmed',
                  MidnightPitchTheme.electricMint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSquadStat(
                  Icons.help_outline,
                  '$maybeCount',
                  'Maybe',
                  MidnightPitchTheme.championGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: MidnightPitchTheme.surfaceContainerHigh,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTeam.name,
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/home/squad'),
                child: const Text(
                  'Manage Squad',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.electricMint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const SkeletonCard(height: 180, childCount: 4);
  }

  Widget _buildNoTeamCard() {
    return EmptyStateWidget(
      icon: Icons.groups_outlined,
      title: 'No Team Selected',
      subtitle: 'Join or create a team to access coach features',
      actionLabel: 'Go to Squad',
      onAction: () => context.go('/home/squad'),
    );
  }

  Widget _buildSquadStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            color: MidnightPitchTheme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchCard() {
    final liveState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);
    final currentMatch = liveState.currentMatch;

    if (currentMatch == null || !currentMatch.isLive) return const SizedBox.shrink();

    final homeName = currentMatch.homeTeamName.isNotEmpty ? currentMatch.homeTeamName : 'Home';
    final awayName = currentMatch.awayTeamName ?? 'Away';
    final matchMinute = timerState.currentMinute;
    final halfLabel = timerState.currentHalf == 1 ? '1ST HALF' : '2ND HALF';
    final isHalftime = timerState.status == TimerStatus.halftime;
    final isFinished = timerState.status == TimerStatus.finished;
    final displayLabel = isHalftime
        ? 'HALF TIME'
        : isFinished
            ? 'FULL TIME'
            : "$matchMinute' $halfLabel";
    final goalCount = liveState.events.where((e) => e.type == 'goal').length;

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
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
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

  Widget _buildNextMatchCountdown() {
    final teamState = ref.watch(teamProvider);
    final squadState = ref.watch(squadProvider);
    final nextMatch = squadState.nextMatch;
    final isLoading = teamState.status == TeamStatus.loading ||
        squadState.status == SquadStatus.loading;

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Next Match'),
          const SizedBox(height: 16),
          _buildLoadingCard(),
        ],
      );
    }

    if (nextMatch == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Next Match'),
          const SizedBox(height: 16),
          const EmptyStateWidget(
            icon: Icons.event_outlined,
            title: 'No Match Scheduled',
            subtitle: 'Schedule a match to get started',
          ),
        ],
      );
    }

    final currentDate = DateTime.now();
    final matchDate = nextMatch.matchDate;
    final daysUntil = matchDate.difference(currentDate).inDays;
    final hoursUntil = matchDate.difference(currentDate).inHours % 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Next Match'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MidnightPitchTheme.electricMint.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    color: MidnightPitchTheme.electricMint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    daysUntil > 0 ? '$daysUntil days $hoursUntil hours' : '$hoursUntil hours',
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: MidnightPitchTheme.surfaceContainerHigh,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Team',
                        style: MidnightPitchTheme.labelSM,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VS',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: MidnightPitchTheme.electricMint,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Away Team',
                        style: MidnightPitchTheme.labelSM,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(matchDate),
                        style: MidnightPitchTheme.bodySM,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MidnightPitchTheme.electricMint,
                    foregroundColor: MidnightPitchTheme.surfaceDim,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'FIND MATCH',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformer() {
    final squadState = ref.watch(squadProvider);
    final roster = squadState.roster;

    if (roster.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Top Performer'),
          const SizedBox(height: 16),
          const EmptyStateWidget(
            icon: Icons.emoji_events_outlined,
            title: 'No Top Performer Yet',
            subtitle: 'Play matches to see top performers',
          ),
        ],
      );
    }

    // Find player with highest rating (placeholder logic)
    final topPlayer = roster.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Top Performer'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MidnightPitchTheme.surfaceContainer,
                MidnightPitchTheme.surfaceContainerHigh,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MidnightPitchTheme.championGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.championGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.emoji_events,
                  color: MidnightPitchTheme.championGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topPlayer.name,
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MidnightPitchTheme.electricMint.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            topPlayer.position,
                            style: TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.electricMint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Top performer',
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 12,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: MidnightPitchTheme.mutedText,
                size: 16,
              ),
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
        MidnightPitchTheme.sectionLabel('Quick actions'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAction(
              Icons.sports_outlined,
              'Build\nLineup',
              onTap: () {
                final teamState = ref.read(teamProvider);
                final currentTeam = teamState.currentTeam;
                if (currentTeam != null) {
                  context.go('/coach/${currentTeam.teamId}');
                }
              },
            ),
            _buildQuickAction(
              Icons.groups,
              'Manage\nSquad',
              onTap: () => context.go('/home/squad'),
            ),
            _buildQuickAction(
              Icons.calendar_today,
              'Session\nPlanner',
              onTap: () {
                final teamState = ref.read(teamProvider);
                final currentTeam = teamState.currentTeam;
                if (currentTeam != null) {
                  context.go('/coach/${currentTeam.teamId}/session');
                }
              },
            ),
            _buildQuickAction(
              Icons.analytics_outlined,
              'Team\nStats',
              onTap: () => context.go('/home/squad'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: MidnightPitchTheme.electricMint, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            height: 1.3,
          ),
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
