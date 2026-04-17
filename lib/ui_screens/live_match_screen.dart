import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../providers/live_match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_timer_provider.dart';
import '../../providers/match_roster_provider.dart';
import '../../models/match_model.dart';
import '../../features/match/presentation/widgets/match_timer_widget.dart';
import '../../features/match/presentation/widgets/event_logging_sheet.dart';
import '../../features/match/presentation/widgets/live_match_body_widget.dart';
import '../../features/match/data/models/live_match_models.dart';
import '../../widgets/add_player_sheet.dart';

/// Live Match Screen — real-time match scoring with timer, scoreboard,
/// player roster, and event logging. Offline-first with auto-sync.
/// Roster is persisted to Appwrite so players survive screen navigations.
class LiveMatchScreen extends ConsumerStatefulWidget {
  final MatchModel? match;
  final VoidCallback? onHalfTime;
  final VoidCallback? onFullTime;

  const LiveMatchScreen({super.key, this.match, this.onHalfTime, this.onFullTime});

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

      // Only re-init if no match is loaded or it's a different match
      final currentMatchId = liveState.currentMatch?.matchId;
      final isAlreadyActive = currentMatchId == widget.match!.matchId &&
          timerState.status != TimerStatus.stopped;

      if (!isAlreadyActive) {
        await ref.read(liveMatchProvider.notifier).initMatch(widget.match!);
      }

      // Load roster from Appwrite database
      await ref.read(matchRosterProvider.notifier).loadRoster(widget.match!.matchId);
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  /// Build the roster from DB entries + any match events, deduplicating by playerId.
  List<LivePlayerInfo> _buildRoster() {
    final rosterState = ref.watch(matchRosterProvider);
    final matchState = ref.watch(liveMatchProvider);
    final seen = <String>{};
    final roster = <LivePlayerInfo>[];

    // DB roster entries first (authoritative)
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
        ));
      }
    }

    // Then fill in from events (for matches created before roster feature)
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
      return Scaffold(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        body: Center(
          child: CircularProgressIndicator(
              color: MidnightPitchTheme.electricMint),
        ),
      );
    }

    final roster = _buildRoster();

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MidnightPitchTheme.primaryText, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'LIVE MATCH',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: 0.05,
          ),
        ),
        actions: [
          const MatchTimerWidget(),
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
        ),
      ),
    );
  }
}