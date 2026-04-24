import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/providers/live_match_provider.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_timer_provider.dart';
import 'package:footheroes/providers/match_roster_provider.dart';
import 'package:footheroes/models/match_model.dart';
import '../widgets/match_timer_widget.dart';
import '../widgets/event_logging_sheet.dart';
import '../widgets/live_match_body_widget.dart';
import '../../data/models/live_match_models.dart';
import '../../../../../widgets/add_player_sheet.dart';

/// Live Match Screen — real-time match scoring with timer, scoreboard,
/// player roster, and event logging. Offline-first with auto-sync.
class LiveMatchScreen extends ConsumerStatefulWidget {
  final MatchModel? match;
  final VoidCallback? onBack;
  final VoidCallback? onHalfTime;
  final VoidCallback? onFullTime;

  const LiveMatchScreen({super.key, this.match, this.onBack, this.onHalfTime, this.onFullTime});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeMatch());
  }

  Future<void> _initializeMatch() async {
    if (widget.match != null) {
      final liveState = ref.read(liveMatchProvider);
      final timerState = ref.read(matchTimerProvider);

      final currentMatchId = liveState.currentMatch?.matchId;
      final isAlreadyActive = currentMatchId == widget.match!.matchId &&
          timerState.status != TimerStatus.stopped;

      if (!isAlreadyActive) {
        await ref.read(liveMatchProvider.notifier).initMatch(widget.match!);
      }

      await ref.read(matchRosterProvider.notifier).loadRoster(widget.match!.matchId);
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  List<LivePlayerInfo> _buildRoster() {
    final rosterState = ref.watch(matchRosterProvider);
    final matchState = ref.watch(liveMatchProvider);
    final seen = <String>{};
    final roster = <LivePlayerInfo>[];

    for (final entry in rosterState.entries) {
      if (!seen.contains(entry.playerId)) {
        seen.add(entry.playerId);
        roster.add(LivePlayerInfo(
          id: entry.playerId,
          name: entry.playerName,
          position: entry.position,
          email: entry.playerEmail,
          isRegistered: entry.isRegistered,
          team: entry.team ?? 'home',
          isCaptain: entry.isCaptain,
        ));
      }
    }

    for (final event in matchState.events) {
      if (!seen.contains(event.playerId)) {
        seen.add(event.playerId);
        roster.add(LivePlayerInfo(
          id: event.playerId,
          name: event.playerName,
          position: event.details ?? '',
          team: event.team,
        ));
      }
    }

    return roster;
  }

  void _showEventSheet(LivePlayerInfo player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventLoggingSheet(
        player: EventLoggingPlayer(
          id: player.id,
          name: player.name,
          position: player.position,
          team: player.team,
        ),
        onClose: () {},
        onRedCard: () =>
            ref.read(liveMatchProvider.notifier).removePlayerFromActive(player.id),
      ),
    );
  }

  void _showAddPlayerDialog() async {
    final player = await showAddPlayerSheet(
      context,
      ref.read(appwriteServiceProvider),
    );
    if (player != null && mounted) {
      final matchId = widget.match?.matchId ??
          ref.read(liveMatchProvider).currentMatch?.matchId;
      if (matchId != null) {
        ref.read(matchRosterProvider.notifier).addPlayer(
          matchId,
          player,
          team: player.team,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(liveMatchProvider);

    if (!_isInitialized || matchState.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.voidBg,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.cardinal),
        ),
      );
    }

    final roster = _buildRoster();

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      appBar: AppBar(
        backgroundColor: AppTheme.abyss,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
          onPressed: widget.onBack ?? () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'LIVE MATCH',
          style: AppTheme.bebasDisplay.copyWith(fontSize: 18, letterSpacing: 1),
        ),
        actions: [
          const Center(child: MatchTimerWidget()),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SyncIndicatorWidget(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LiveMatchBodyWidget(
          roster: roster,
          onAddPlayer: _showAddPlayerDialog,
          onPlayerTap: _showEventSheet,
          onToggleCaptain: (playerId, team) {
            ref.read(liveMatchProvider.notifier).toggleCaptain(playerId, team);
          },
        ),
      ),
    );
  }
}
