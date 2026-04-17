import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../models/match_model.dart';
import '../models/match_roster_model.dart';
import '../providers/match_roster_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_match_provider.dart';
import '../widgets/add_player_sheet.dart';

/// Detail screen for an upcoming scheduled match.
/// Shows venue, date/time, roster, and allows starting the match.
class UpcomingMatchDetailScreen extends ConsumerStatefulWidget {
  final MatchModel match;
  final VoidCallback? onBack;
  final VoidCallback? onStartMatch;

  const UpcomingMatchDetailScreen({
    super.key,
    required this.match,
    this.onBack,
    this.onStartMatch,
  });

  @override
  ConsumerState<UpcomingMatchDetailScreen> createState() => _UpcomingMatchDetailScreenState();
}

class _UpcomingMatchDetailScreenState extends ConsumerState<UpcomingMatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchRosterProvider.notifier).loadRoster(widget.match.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(matchRosterProvider);
    final match = widget.match;
    final dateStr = _formatDate(match.matchDate);
    final timeStr = _formatTime(match.matchDate);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MidnightPitchTheme.electricMint, size: 20),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: Text(
          'MATCH DETAILS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: -0.02,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(match.status),
              const SizedBox(height: 24),
              _buildTeams(match),
              const SizedBox(height: 32),
              _buildInfoSection(dateStr, timeStr, match),
              const SizedBox(height: 32),
              _buildRosterSection(rosterState),
              if (_isCreator()) ...[
                const SizedBox(height: 24),
                _buildDeleteButton(),
              ],
              const SizedBox(height: 48),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = switch (status) {
      'upcoming' => ('UPCOMING', MidnightPitchTheme.championGold),
      'challenge_accepted' => ('CONFIRMED', MidnightPitchTheme.electricMint),
      'challenge_sent' => ('PENDING', MidnightPitchTheme.championGold),
      _ => (status.toUpperCase(), MidnightPitchTheme.mutedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildTeams(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined, color: MidnightPitchTheme.electricMint, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.format.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.electricMint,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'VS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined, color: MidnightPitchTheme.mutedText, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  match.awayTeamName ?? 'Away',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String dateStr, String timeStr, MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'Date', dateStr),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, 'Kick-off', timeStr),
          if (match.venue != null && match.venue!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on_outlined, 'Venue', match.venue!),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(Icons.sports_soccer, 'Format', match.format.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MidnightPitchTheme.electricMint),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRosterSection(MatchRosterState rosterState) {
    final homePlayers = rosterState.entries.where((e) => e.team != 'away').toList();
    final awayPlayers = rosterState.entries.where((e) => e.team == 'away').toList();
    final isCreator = _isCreator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROSTER',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.15,
              ),
            ),
            if (isCreator)
              GestureDetector(
                onTap: () => _addPlayer(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 16, color: MidnightPitchTheme.electricMint),
                      const SizedBox(width: 4),
                      Text(
                        'ADD PLAYER',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.electricMint,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Home team
        _buildTeamRoster('HOME', homePlayers, MidnightPitchTheme.electricMint, isCreator),
        const SizedBox(height: 16),
        // Away team
        _buildTeamRoster('AWAY', awayPlayers, MidnightPitchTheme.skyBlue, isCreator),
      ],
    );
  }

  Widget _buildTeamRoster(String label, List<MatchRosterEntry> players, Color accentColor, bool canRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${players.length} player${players.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (players.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MidnightPitchTheme.ghostBorder, style: BorderStyle.solid),
            ),
            child: Text(
              'No ${label.toLowerCase()} players yet',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                color: MidnightPitchTheme.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...players.map((player) => _buildPlayerRow(player, canRemove)),
      ],
    );
  }

  void _addPlayer() async {
    final appwriteService = ref.read(appwriteServiceProvider);
    final player = await showAddPlayerSheet(context, appwriteService);
    if (player == null) return;

    final success = await ref.read(matchRosterProvider.notifier).addPlayer(
      widget.match.matchId,
      player,
      team: player.team,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${player.name} added to roster' : 'Failed to add player'),
        backgroundColor: success ? MidnightPitchTheme.electricMint : MidnightPitchTheme.liveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removePlayer(MatchRosterEntry player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Remove Player?', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: Text(
          'Remove ${player.playerName} from the roster?',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.liveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref.read(matchRosterProvider.notifier).removePlayer(player.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${player.playerName} removed' : 'Failed to remove player'),
        backgroundColor: success ? MidnightPitchTheme.electricMint : MidnightPitchTheme.liveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPlayerRow(MatchRosterEntry player, bool canRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: player.isRegistered
                  ? MidnightPitchTheme.electricMint.withValues(alpha: 0.15)
                  : MidnightPitchTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: player.isRegistered
                ? Icon(Icons.verified, size: 18, color: MidnightPitchTheme.electricMint)
                : Text(
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
                if (player.playerEmail != null && player.playerEmail!.isNotEmpty)
                  Text(
                    player.playerEmail!,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          if (player.position.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.position,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ),
          if (canRemove) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removePlayer(player),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.liveRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.close, size: 16, color: MidnightPitchTheme.liveRed),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: MidnightPitchTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricMint.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onStartMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: MidnightPitchTheme.surfaceDim,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 22),
            const SizedBox(width: 8),
            Text(
              'START MATCH',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCreator() {
    final userId = ref.read(authProvider).userId;
    return userId != null && userId == widget.match.createdBy;
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () => _confirmDelete(),
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
                    'Permanently remove this match',
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

  void _confirmDelete() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Delete Match?', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: Text(
          'This will permanently delete ${widget.match.homeTeamName} vs ${widget.match.awayTeamName ?? "Opponent"}. This cannot be undone.',
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
              final success = await ref.read(postMatchProvider.notifier).deleteMatch(widget.match.matchId);
              if (!mounted) return;
              if (success) {
                if (widget.onBack != null) {
                  widget.onBack!();
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}