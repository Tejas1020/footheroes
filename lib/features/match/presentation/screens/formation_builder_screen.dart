import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../models/formation_model.dart';
import '../../../../../../../models/team_model.dart';
import '../../../../../../../providers/formation_provider.dart';
import '../../../../../../../providers/team_provider.dart';
import '../../../../../../../providers/squad_provider.dart';
import '../../../../../../../../widgets/football_pitch_widget.dart';
import '../../../../../../../../widgets/shareable_cards.dart';
import '../../../../../../../../widgets/empty_state_widget.dart';

/// Formation Builder screen (Coach Mode) — pick a formation,
/// view the pitch layout, assign players to positions, and save/share.
class FormationBuilderScreen extends ConsumerStatefulWidget {
  final String teamId;
  final VoidCallback? onBack;

  const FormationBuilderScreen({
    super.key,
    required this.teamId,
    this.onBack,
  });

  @override
  ConsumerState<FormationBuilderScreen> createState() => _FormationBuilderScreenState();
}

class _FormationBuilderScreenState extends ConsumerState<FormationBuilderScreen> {
  String _selectedFormationType = '4-4-2';
  String? _editingFormationId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey _shareCardKey = GlobalKey();
  List<PlayerPositionSlot> _currentSlots = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(formationProvider.notifier).loadTeamFormations(widget.teamId);
    _initSlots();
  }

  void _initSlots() {
    _currentSlots = FormationTemplates.getSlotsForFormation(_selectedFormationType);
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formationState = ref.watch(formationProvider);
    final teamState = ref.watch(teamProvider);
    final squadState = ref.watch(squadProvider);

    // Check if squad is empty - show empty state
    if (squadState.roster.isEmpty && squadState.status == SquadStatus.loaded) {
      return Scaffold(
        backgroundColor: AppTheme.voidBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              const Expanded(
                child: EmptyStateWidget(
                  icon: Icons.groups_outlined,
                  title: 'No Players in Squad',
                  subtitle: 'Add players to your squad to build a lineup',
                  actionLabel: 'Go to Squad',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formationState.error != null)
                      _buildErrorBanner(formationState.error!),
                    _buildSavedFormations(formationState.formations),
                    const SizedBox(height: 16),
                    _buildFormationSelector(),
                    const SizedBox(height: 24),
                    _buildPitch(),
                    const SizedBox(height: 24),
                    _buildNameInput(),
                    const SizedBox(height: 16),
                    _buildNotesInput(),
                    const SizedBox(height: 32),
                    _buildActionButtons(teamState.currentTeam),
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
        color: AppTheme.cardinal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.cardinal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppTheme.cardinal),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(formationProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppTheme.cardinal, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.voidBg.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                GestureDetector(
                  onTap: () {
                    final router = GoRouter.of(context);
                    if (router.canPop()) {
                      router.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Icon(Icons.arrow_back, color: AppTheme.parchment, size: 24),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COACH MODE',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.rose,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Formation builder',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _shareFormation,
                child: const Icon(Icons.share, color: AppTheme.parchment, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedFormations(List<FormationModel> formations) {
    if (formations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAVED FORMATIONS',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.gold,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: formations.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final formation = formations[index];
              final isSelected = formation.id == _editingFormationId;
              return GestureDetector(
                onTap: () => _loadFormation(formation),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.navy.withValues(alpha: 0.1)
                        : AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.navy)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formation.formationType,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.navy
                                  : AppTheme.parchment,
                            ),
                          ),
                          if (formation.isDefault) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              size: 12,
                              color: AppTheme.rose,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formation.name,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          color: AppTheme.gold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormationSelector() {
    final supportedFormations = ref.watch(supportedFormationsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: supportedFormations.map((label) {
          final isActive = label == _selectedFormationType;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _changeFormationType(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.navy.withValues(alpha: 0.1)
                      : AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? Border.all(color: AppTheme.navy)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppTheme.navy
                        : AppTheme.gold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPitch() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.redDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FootballPitchWidget(
          slots: _currentSlots,
          onSlotTap: _onSlotTap,
          showLabels: true,
          pitchColor: AppTheme.redDeep,
          lineColor: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.parchment,
      ),
      decoration: InputDecoration(
        labelText: 'Formation Name',
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppTheme.gold,
        ),
        filled: true,
        fillColor: AppTheme.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.navy),
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.parchment,
      ),
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppTheme.gold,
        ),
        filled: true,
        fillColor: AppTheme.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.navy),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TeamModel? team) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFormation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: AppTheme.voidBg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppTheme.voidBg),
                        ),
                      )
                    : Text(
                        _editingFormationId != null ? 'UPDATE FORMATION' : 'SAVE FORMATION',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            if (_editingFormationId != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: _setAsDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.rose,
                    side: const BorderSide(color: AppTheme.rose),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('SET DEFAULT'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _newFormation,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.gold,
            side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('NEW FORMATION'),
        ),
      ],
    );
  }

  void _changeFormationType(String type) {
    setState(() {
      _selectedFormationType = type;
      _currentSlots = FormationTemplates.getSlotsForFormation(type);
    });
  }

  void _loadFormation(FormationModel formation) {
    setState(() {
      _editingFormationId = formation.id;
      _selectedFormationType = formation.formationType;
      _currentSlots = formation.slots;
      _nameController.text = formation.name;
      _notesController.text = formation.notes ?? '';
    });
  }

  void _newFormation() {
    setState(() {
      _editingFormationId = null;
      _nameController.clear();
      _notesController.clear();
      _selectedFormationType = '4-4-2';
      _currentSlots = FormationTemplates.getSlotsForFormation('4-4-2');
    });
  }

  void _onSlotTap(PlayerPositionSlot slot) {
    _showPlayerSelectionDialog(slot);
  }

  void _showPlayerSelectionDialog(PlayerPositionSlot slot) {
    final squadState = ref.read(squadProvider);
    final availablePlayers = squadState.roster.where((player) {
      // Filter out players already assigned to other slots
      final assignedIds = _currentSlots
          .where((s) => s.isAssigned && s.slotId != slot.slotId)
          .map((s) => s.assignedPlayerId)
          .toSet();
      return !assignedIds.contains(player.userId);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text('Assign ${slot.positionLabel}', style: TextStyle(color: AppTheme.parchment)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: availablePlayers.isEmpty
              ? Center(
                  child: Text(
                    'No available players',
                    style: TextStyle(color: AppTheme.gold),
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
                          color: AppTheme.elevatedSurface,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(color: AppTheme.gold),
                        ),
                      ),
                      title: Text(player.name, style: TextStyle(color: AppTheme.parchment)),
                      subtitle: Text(player.position, style: TextStyle(color: AppTheme.gold)),
                      onTap: () {
                        Navigator.pop(context);
                        _assignPlayerToSlot(slot, player.userId, player.name);
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (slot.isAssigned)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearSlotAssignment(slot);
              },
              child: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _assignPlayerToSlot(PlayerPositionSlot slot, String playerId, String playerName) {
    setState(() {
      final index = _currentSlots.indexWhere((s) => s.slotId == slot.slotId);
      if (index != -1) {
        _currentSlots[index] = _currentSlots[index].copyWith(
          assignedPlayerId: playerId,
          assignedPlayerName: playerName,
        );
      }
    });
  }

  void _clearSlotAssignment(PlayerPositionSlot slot) {
    setState(() {
      final index = _currentSlots.indexWhere((s) => s.slotId == slot.slotId);
      if (index != -1) {
        _currentSlots[index] = _currentSlots[index].copyWith(
          assignedPlayerId: null,
          assignedPlayerName: null,
        );
      }
    });
  }

  Future<void> _saveFormation() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter a formation name');
      return;
    }

    setState(() => _isSaving = true);

    final formation = FormationModel(
      id: _editingFormationId ?? 'form_${widget.teamId}_${DateTime.now().millisecondsSinceEpoch}',
      formationId: _editingFormationId ?? 'form_${widget.teamId}_${DateTime.now().millisecondsSinceEpoch}',
      teamId: widget.teamId,
      name: _nameController.text,
      formationType: _selectedFormationType,
      slots: _currentSlots,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
      isDefault: false,
    );

    bool success;
    if (_editingFormationId != null) {
      success = await ref.read(formationProvider.notifier).updateFormation(formation);
    } else {
      success = await ref.read(formationProvider.notifier).saveFormation(formation);
    }

    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar('Formation saved!');
    } else {
      _showSnackBar('Failed to save formation');
    }
  }

  Future<void> _setAsDefault() async {
    if (_editingFormationId == null) return;

    final success = await ref
        .read(formationProvider.notifier)
        .setDefault(widget.teamId, _editingFormationId!);

    if (success) {
      _showSnackBar('Set as default formation!');
    } else {
      _showSnackBar('Failed to set as default');
    }
  }

  Future<void> _shareFormation() async {
    final team = ref.read(teamProvider).currentTeam;
    final formation = FormationModel(
      id: 'share_temp',
      formationId: 'share_temp',
      teamId: widget.teamId,
      name: _nameController.text.isNotEmpty ? _nameController.text : _selectedFormationType,
      formationType: _selectedFormationType,
      slots: _currentSlots,
      createdAt: DateTime.now(),
    );

    // Create shareable card
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FormationShareCard(
          formation: formation,
          team: team,
          repaintKey: _shareCardKey,
        ),
      ),
    );

    // Capture and share
    final bytes = await ShareableCardCapture.captureWidget(_shareCardKey);
    if (bytes != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: 'formation.png', mimeType: 'image/png')],
          text: 'Check out my ${formation.name} formation on FootHeroes!',
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
}