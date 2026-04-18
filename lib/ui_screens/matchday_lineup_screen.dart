import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/midnight_pitch_theme.dart';
import '../models/lineup_model.dart';
import '../models/formation_model.dart';
import '../models/team_model.dart';
import '../providers/lineup_provider.dart';
import '../providers/team_provider.dart';
import '../providers/squad_provider.dart';
import '../providers/formation_provider.dart';
import '../widgets/football_pitch_widget.dart';
import '../widgets/shareable_cards.dart';

/// Matchday Lineup screen — starting XI, substitutes, availability,
/// and pre-match actions. Coach mode view.
class MatchdayLineupScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String teamId;
  final String opponentName;
  final VoidCallback? onBack;

  const MatchdayLineupScreen({
    super.key,
    required this.matchId,
    required this.teamId,
    required this.opponentName,
    this.onBack,
  });

  @override
  ConsumerState<MatchdayLineupScreen> createState() => _MatchdayLineupScreenState();
}

class _MatchdayLineupScreenState extends ConsumerState<MatchdayLineupScreen> {
  String _selectedFormationType = '4-4-2';
  final TextEditingController _teamTalkController = TextEditingController();
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(lineupProvider.notifier).loadLineup(widget.matchId, widget.teamId);
    await ref.read(formationProvider.notifier).loadTeamFormations(widget.teamId);
    await ref.read(squadProvider.notifier).loadSquad(widget.teamId);

    // Set formation type from existing lineup
    final lineup = ref.read(lineupProvider).currentLineup;
    if (lineup != null) {
      setState(() {
        _selectedFormationType = lineup.formationType;
      });
    }
  }

  @override
  void dispose() {
    _teamTalkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineupState = ref.watch(lineupProvider);
    final squadState = ref.watch(squadProvider);
    final teamState = ref.watch(teamProvider);
    final formationState = ref.watch(formationProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildContextBar(teamState.currentTeam),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lineupState.error != null)
                      _buildErrorBanner(lineupState.error!),
                    _buildAvailabilitySummary(squadState),
                    const SizedBox(height: 24),
                    _buildFormationSelector(formationState.formations),
                    const SizedBox(height: 24),
                    _buildPitch(lineupState.currentLineup),
                    const SizedBox(height: 24),
                    _buildStartingXIList(lineupState.currentLineup),
                    const SizedBox(height: 32),
                    _buildSubstitutesList(lineupState.currentLineup),
                    const SizedBox(height: 32),
                    _buildUnconfirmedSection(squadState),
                    const SizedBox(height: 32),
                    _buildTeamTalkInput(lineupState.currentLineup),
                    const SizedBox(height: 32),
                    _buildActionButtons(lineupState.currentLineup, teamState.currentTeam),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.liveRed.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: MidnightPitchTheme.liveRed),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: MidnightPitchTheme.liveRed))),
          GestureDetector(
            onTap: () => ref.read(lineupProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: MidnightPitchTheme.liveRed, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(Icons.arrow_back_ios, color: MidnightPitchTheme.electricMint, size: 20),
                ),
              const SizedBox(width: 12),
              Text(
                'MATCHDAY LINEUP',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.primaryText,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'COACH MODE',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.championGold,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBar(TeamModel? team) {
    return Container(
      color: MidnightPitchTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.championGold,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              team?.name ?? 'MY TEAM',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: MidnightPitchTheme.surfaceDim,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'vs ${widget.opponentName}',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySummary(SquadState squadState) {
    final confirmed = squadState.rsvpStatus.values.where((v) => v == 'yes').length;
    final maybe = squadState.rsvpStatus.values.where((v) => v == 'maybe').length;
    final out = squadState.rsvpStatus.values.where((v) => v == 'no').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusChip(MidnightPitchTheme.electricMint, '$confirmed Confirmed'),
          const SizedBox(width: 12),
          _buildStatusChip(MidnightPitchTheme.championGold, '$maybe Maybe'),
          const SizedBox(width: 12),
          _buildStatusChip(MidnightPitchTheme.liveRed, '$out Out'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationSelector(List<FormationModel> formations) {
    final supportedFormations = ref.watch(supportedFormationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORMATION',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: supportedFormations.map((type) {
              final isSelected = type == _selectedFormationType;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _changeFormation(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MidnightPitchTheme.electricMint.withValues(alpha: 0.1)
                          : MidnightPitchTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? Border.all(color: MidnightPitchTheme.electricMint) : null,
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPitch(LineupModel? lineup) {
    final slots = lineup?.startingXI ?? FormationTemplates.getSlotsForFormation(_selectedFormationType);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: MidnightPitchTheme.ambientShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FootballPitchWidget(
          slots: slots,
          onSlotTap: _onPlayerSlotTap,
          showLabels: true,
          pitchColor: const Color(0xFF1B5E20),
          lineColor: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildStartingXIList(LineupModel? lineup) {
    final slots = lineup?.startingXI ?? FormationTemplates.getSlotsForFormation(_selectedFormationType);
    final assignedSlots = slots.where((s) => s.isAssigned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STARTING XI',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.08,
              ),
            ),
            Text(
              '${assignedSlots.length}/11',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: assignedSlots.length == 11
                    ? MidnightPitchTheme.electricMint
                    : MidnightPitchTheme.championGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...slots.map((slot) => _buildPlayerSlotRow(slot, lineup)),
      ],
    );
  }

  Widget _buildPlayerSlotRow(PlayerPositionSlot slot, LineupModel? lineup) {
    final isAssigned = slot.isAssigned;
    final isCaptain = lineup?.captainId == slot.assignedPlayerId;
    final isViceCaptain = lineup?.viceCaptainId == slot.assignedPlayerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAssigned ? MidnightPitchTheme.electricMint : MidnightPitchTheme.surfaceContainerHighest,
              border: Border.all(
                color: isCaptain
                    ? MidnightPitchTheme.championGold
                    : isViceCaptain
                        ? Colors.blue.shade300
                        : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              isAssigned ? slot.assignedPlayerName?.substring(0, 2).toUpperCase() ?? '??' : '+',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAssigned ? MidnightPitchTheme.surfaceDim : MidnightPitchTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAssigned ? slot.assignedPlayerName ?? 'Unknown' : 'Tap to assign',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isAssigned ? MidnightPitchTheme.primaryText : MidnightPitchTheme.mutedText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.positionLabel,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutesList(LineupModel? lineup) {
    final subIds = lineup?.substituteIds ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.2))),
            const SizedBox(width: 12),
            Text(
              'SUBSTITUTES · ${subIds.length}',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showSubstitutePicker,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Substitute'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MidnightPitchTheme.surfaceContainerHigh,
            foregroundColor: MidnightPitchTheme.electricMintLight,
          ),
        ),
      ],
    );
  }

  Widget _buildUnconfirmedSection(SquadState squadState) {
    final unconfirmed = squadState.roster.where((m) {
      final status = squadState.rsvpStatus[m.userId];
      return status != 'yes' && status != 'no';
    }).toList();

    if (unconfirmed.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: MidnightPitchTheme.championGold, size: 20),
              const SizedBox(width: 12),
              Text(
                '${unconfirmed.length} UNCONFIRMED',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                  letterSpacing: 0.08,
                ),
              ),
            ],
          ),
          const Icon(Icons.expand_more, color: MidnightPitchTheme.mutedText),
        ],
      ),
    );
  }

  Widget _buildTeamTalkInput(LineupModel? lineup) {
    _teamTalkController.text = lineup?.teamTalkNotes ?? '';

    return TextField(
      controller: _teamTalkController,
      maxLines: 3,
      style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily,
        color: MidnightPitchTheme.primaryText,
      ),
      decoration: InputDecoration(
        labelText: 'Team Talk Notes',
        labelStyle: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          color: MidnightPitchTheme.mutedText,
        ),
        filled: true,
        fillColor: MidnightPitchTheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidnightPitchTheme.electricMint),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LineupModel? lineup, TeamModel? team) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveLineup,
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.electricMint,
              foregroundColor: MidnightPitchTheme.surfaceDim,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(MidnightPitchTheme.surfaceDim),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SAVE LINEUP',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _shareLineup(lineup, team),
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.surfaceContainerHigh,
              foregroundColor: MidnightPitchTheme.electricMintLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text(
                  'SHARE LINEUP',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _changeFormation(String type) async {
    setState(() => _selectedFormationType = type);
    await ref.read(lineupProvider.notifier).changeFormation(type);
  }

  void _onPlayerSlotTap(PlayerPositionSlot slot) {
    _showPlayerAssignmentDialog(slot);
  }

  void _showPlayerAssignmentDialog(PlayerPositionSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${slot.positionLabel}'),
        content: const Text('Player selection would go here. This would show available players from the squad.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAvailablePlayersForSlot(slot);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showSubstitutePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Substitute'),
        content: const Text('Substitute selection would go here. This would show squad players not in starting XI.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLineup() async {
    setState(() => _isSaving = true);

    // Update team talk notes
    await ref.read(lineupProvider.notifier).updateTeamTalk(_teamTalkController.text);

    final success = await ref.read(lineupProvider.notifier).saveLineup();

    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar('Lineup saved!');
    } else {
      _showSnackBar('Failed to save lineup');
    }
  }

  Future<void> _shareLineup(LineupModel? lineup, TeamModel? team) async {
    if (lineup == null) {
      _showSnackBar('No lineup to share');
      return;
    }

    // Show shareable card dialog
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LineupShareCard(
          lineup: lineup,
          teamName: team?.name ?? 'My Team',
          opponentName: widget.opponentName,
          repaintKey: _shareCardKey,
        ),
      ),
    );

    // Capture and share
    final bytes = await ShareableCardCapture.captureWidget(_shareCardKey);
    if (bytes != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: 'lineup.png', mimeType: 'image/png')],
          text: 'Check out our starting XI vs ${widget.opponentName}!',
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAvailablePlayersForSlot(PlayerPositionSlot slot) {
    final squadState = ref.read(squadProvider);
    final lineupState = ref.read(lineupProvider);

    // Get already assigned player IDs
    final assignedIds = lineupState.currentLineup?.startingXI
        .where((s) => s.isAssigned && s.slotId != slot.slotId)
        .map((s) => s.assignedPlayerId)
        .toSet() ?? {};

    final availablePlayers = squadState.roster.where((player) {
      return !assignedIds.contains(player.userId);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Text('Select ${slot.positionLabel}', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: availablePlayers.isEmpty
              ? Center(
                  child: Text(
                    'No available players',
                    style: TextStyle(color: MidnightPitchTheme.mutedText),
                  ),
                )
              : ListView.builder(
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, index) {
                    final player = availablePlayers[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MidnightPitchTheme.surfaceContainerHigh,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(color: MidnightPitchTheme.electricMint),
                        ),
                      ),
                      title: Text(player.name, style: TextStyle(color: MidnightPitchTheme.primaryText)),
                      subtitle: Text(player.position, style: TextStyle(color: MidnightPitchTheme.mutedText)),
                      onTap: () {
                        Navigator.pop(context);
                        _assignPlayerToSlot(slot, player.userId, player.name);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _assignPlayerToSlot(PlayerPositionSlot slot, String playerId, String playerName) async {
    await ref.read(lineupProvider.notifier).assignPlayerToSlot(
      slot.slotId,
      playerId,
      playerName,
    );
    _showSnackBar('$playerName assigned to ${slot.positionLabel}');
  }
}