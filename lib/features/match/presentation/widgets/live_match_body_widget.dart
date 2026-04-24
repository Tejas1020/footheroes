import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../providers/match_timer_provider.dart';
import '../../../../../../../../../../../services/offline_sync_service.dart';
import '../../../../../../../../../../models/match_event_model.dart';
import '../../../../../../../../../../../features/match/data/models/live_match_models.dart';
import 'player_row_widget.dart';
import 'live_match_components.dart';
import 'match_timer_widget.dart';
import 'event_edit_sheet.dart';

/// Live match body content using Dark Colour System.
class LiveMatchBodyWidget extends ConsumerWidget {
  final List<LivePlayerInfo> roster;
  final VoidCallback onAddPlayer;
  final void Function(LivePlayerInfo player) onPlayerTap;
  final void Function(String playerId, String team)? onToggleCaptain;

  const LiveMatchBodyWidget({
    super.key,
    required this.roster,
    required this.onAddPlayer,
    required this.onPlayerTap,
    this.onToggleCaptain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(liveMatchProvider);
    final timerState = ref.watch(matchTimerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildScoreboard(matchState, timerState),
        const SizedBox(height: 24),
        _buildSyncStatus(matchState.syncStatus),
        const SizedBox(height: 16),
        _buildControlButtons(context, ref, timerState),
        const SizedBox(height: 24),
        _buildEventsList(context, matchState.events),
        const SizedBox(height: 24),
        _buildPlayerRoster(ref, matchState),
      ]),
    );
  }

  Widget _buildScoreboard(LiveMatchState matchState, MatchTimerState timerState) {
    final match = matchState.currentMatch;
    return Container(
      decoration: AppTheme.standardCard.copyWith(
        gradient: AppTheme.cardSurfaceGradient,
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TeamColumn(
              label: 'HOME',
              name: match?.homeTeamName ?? 'Home',
              score: matchState.homeScore,
              accentColor: AppTheme.cardinal,
            ),
          ),
          ScoreCenter(matchState: matchState, timerState: timerState),
          Expanded(
            child: TeamColumn(
              label: 'AWAY',
              name: match?.awayTeamName ?? 'Away',
              score: matchState.awayScore,
              accentColor: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(SyncStatus status) {
    if (status == SyncStatus.synced) return const SizedBox.shrink();
    final (message, color) = switch (status) {
      SyncStatus.syncing => ('Syncing events...', AppTheme.gold),
      SyncStatus.pending => ('Events pending sync', AppTheme.gold),
      SyncStatus.failed => ('Sync failed - will retry', AppTheme.cardinal),
      SyncStatus.synced => ('', AppTheme.navy),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 12,
          height: 12,
          child: status == SyncStatus.syncing
              ? CircularProgressIndicator(strokeWidth: 2, color: color)
              : Icon(Icons.info_outline, color: color, size: 12),
        ),
        const SizedBox(width: 8),
        Text(message,
            style: AppTheme.dmSans.copyWith(
              fontSize: 12,
              color: color,
            )),
      ]),
    );
  }

  Widget _buildControlButtons(BuildContext context, WidgetRef ref, MatchTimerState timerState) {
    final isRunning = timerState.status == TimerStatus.running;
    final isPaused = timerState.status == TimerStatus.paused;
    final isStopped = timerState.status == TimerStatus.stopped;
    final isHalftime = timerState.status == TimerStatus.halftime;
    final isFinished = timerState.status == TimerStatus.finished;
    final isFirstHalf = timerState.currentHalf == 1;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (isRunning)
          ControlBtn(
            icon: Icons.pause,
            label: 'PAUSE',
            color: AppTheme.cardinal,
            onTap: () => ref.read(matchTimerProvider.notifier).pauseTimer(),
          )
        else if (isPaused || isStopped)
          ControlBtn(
            icon: Icons.play_arrow,
            label: isStopped ? 'START' : 'RESUME',
            color: AppTheme.cardinal,
            onTap: () => isStopped
                ? ref.read(matchTimerProvider.notifier).startMatch()
                : ref.read(matchTimerProvider.notifier).startTimer(),
          ),
        if ((isRunning || isPaused) && !isHalftime && !isFinished)
          ControlBtn(
            icon: Icons.add,
            label: '+EXTRA MIN',
            color: AppTheme.gold,
            onTap: () => _showStoppageDialog(context, ref),
          ),
        if ((isRunning || isPaused || isStopped) && !isHalftime && !isFinished)
          ControlBtn(
            icon: Icons.remove,
            label: '-REDUCE MIN',
            color: AppTheme.rose,
            onTap: () => _showReduceDialog(context, ref),
          ),
        if (isFirstHalf && (isRunning || isPaused))
          ControlBtn(
            icon: Icons.stop,
            label: 'HALF TIME',
            color: AppTheme.navy,
            onTap: () => ref.read(matchTimerProvider.notifier).endFirstHalf(),
          )
        else if (!isFirstHalf && !isFinished && !isHalftime)
          ControlBtn(
            icon: Icons.stop,
            label: 'END MATCH',
            color: AppTheme.cardinal,
            onTap: () async {
              await ref.read(liveMatchProvider.notifier).endMatch();
            },
          ),
        if (isHalftime)
          ControlBtn(
            icon: Icons.play_arrow,
            label: 'START 2ND HALF',
            color: AppTheme.cardinal,
            onTap: () => ref.read(matchTimerProvider.notifier).startSecondHalf(),
          ),
      ],
    );
  }

  void _showStoppageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => StoppageTimeDialog(
        onConfirm: (minutes) {
          ref.read(matchTimerProvider.notifier).addStoppageTime(minutes * 60);
        },
      ),
    );
  }

  void _showReduceDialog(BuildContext context, WidgetRef ref) {
    final timerState = ref.read(matchTimerProvider);
    final totalMinutes = (timerState.halfDuration * 2) ~/ 60;
    showDialog(
      context: context,
      builder: (ctx) => ReduceTimeDialog(
        totalMatchMinutes: totalMinutes,
        onConfirm: (minutes) {
          ref.read(matchTimerProvider.notifier).reduceTime(minutes * 60);
        },
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<MatchEventModel> events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.standardCard,
        child: Center(
          child: Text('No events logged yet',
              style: AppTheme.dmSans.copyWith(
                color: AppTheme.gold,
              )),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              Text(
                'MATCH EVENTS',
                style: AppTheme.labelSmall,
              ),
            ],
          ),
          Text(
            'Tap to edit',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.gold.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        decoration: AppTheme.standardCard,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (context, index) =>
              const Divider(color: AppTheme.cardBorderColor, height: 1),
          itemBuilder: (context, index) => EventRow(
            event: events[index],
            onTap: () => _showEventEditSheet(context, events[index]),
          ),
        ),
      ),
    ]);
  }

  void _showEventEditSheet(BuildContext context, MatchEventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventEditSheet(event: event),
    );
  }

  Widget _buildPlayerRoster(WidgetRef ref, LiveMatchState matchState) {
    final redCardedIds = matchState.redCardedPlayerIds;
    if (roster.isEmpty) return _buildAddPlayerSection();

    final homePlayers = roster.where((p) => p.team != 'away').toList();
    final awayPlayers = roster.where((p) => p.team == 'away').toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppTheme.accentBar(),
                const SizedBox(width: 8),
                Text(
                  'ROSTER — tap to log event',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
            GestureDetector(
              onTap: onAddPlayer,
              child: Text(
                '+ ADD',
                style: AppTheme.bodyBold.copyWith(
                  fontSize: 12,
                  color: AppTheme.cardinal,
                ),
              ),
            ),
          ],
        ),
        if (homePlayers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.cardinal, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('HOME', style: AppTheme.labelSmall.copyWith(color: AppTheme.cardinal)),
          ]),
          const SizedBox(height: 8),
          ...homePlayers.map((player) => _buildPlayerRow(player, matchState, redCardedIds, ref)),
        ],
        if (awayPlayers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.navy, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('AWAY', style: AppTheme.labelSmall.copyWith(color: AppTheme.navy)),
          ]),
          const SizedBox(height: 8),
          ...awayPlayers.map((player) => _buildPlayerRow(player, matchState, redCardedIds, ref)),
        ],
      ],
    );
  }

  Widget _buildPlayerRow(LivePlayerInfo player, LiveMatchState matchState, List<String> redCardedIds, WidgetRef ref) {
    final playerEvents = matchState.events.where((e) => e.playerId == player.id).toList();
    final isRedCarded = redCardedIds.contains(player.id);
    final isCaptain = (player.team == 'home' && matchState.homeCaptainId == player.id) ||
        (player.team == 'away' && matchState.awayCaptainId == player.id);
    return PlayerRowWidget(
      playerId: player.id,
      playerName: player.name,
      playerPosition: player.position,
      playerEvents: playerEvents,
      playerRatings: matchState.playerRatings,
      isRedCarded: isRedCarded,
      isCaptain: isCaptain,
      onTap: () => onPlayerTap(player),
      onToggleCaptain: onToggleCaptain != null ? () => onToggleCaptain!(player.id, player.team) : null,
    );
  }

  Widget _buildAddPlayerSection() {
    return GestureDetector(
      onTap: onAddPlayer,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.standardCard.copyWith(
          color: AppTheme.elevatedSurface,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add, color: AppTheme.cardinal),
          const SizedBox(width: 8),
          Text(
            'Add Players to Roster',
            style: AppTheme.bodyBold.copyWith(
              color: AppTheme.cardinal,
            ),
          ),
        ]),
      ),
    );
  }
}