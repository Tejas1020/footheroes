import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_roster_provider.dart';
import 'package:footheroes/models/match_model.dart';
import 'package:footheroes/models/match_roster_model.dart';
import 'package:footheroes/models/formation_model.dart';
import 'package:footheroes/providers/match_provider.dart';
import 'package:footheroes/core/router/app_router.dart';
import 'package:footheroes/widgets/add_player_sheet.dart';
import 'package:footheroes/widgets/motion_card.dart';
import 'package:footheroes/widgets/simple_venue_map_sheet.dart';
import 'package:footheroes/widgets/position_picker_bottom_sheet.dart';
import 'package:footheroes/widgets/football_pitch_widget.dart';
import 'package:footheroes/features/match/data/models/live_match_models.dart';
import 'package:footheroes/features/find_nearby/providers/repositories_provider.dart';
import 'package:footheroes/features/find_nearby/domain/entities/join_request.dart';

/// Upcoming Match Detail — Full Visual Upgrade per Screen 3 spec.
class UpcomingMatchDetailScreen extends ConsumerStatefulWidget {
  final MatchModel match;
  const UpcomingMatchDetailScreen({super.key, required this.match});

  @override
  ConsumerState<UpcomingMatchDetailScreen> createState() => _UpcomingMatchDetailScreenState();
}

class _UpcomingMatchDetailScreenState extends ConsumerState<UpcomingMatchDetailScreen> {
  bool _pitchExpanded = false;
  late String _homeFormation;
  late String _awayFormation;
  List<JoinRequest> _pendingRequests = [];
  bool _loadingRequests = false;

  @override
  void initState() {
    super.initState();
    _homeFormation = widget.match.homeFormation;
    _awayFormation = widget.match.awayFormation ?? '4-4-2';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchRosterProvider.notifier).loadRoster(widget.match.matchId);
      _loadJoinRequests();
    });
  }

  Future<void> _loadJoinRequests() async {
    final auth = ref.read(authProvider);
    if (auth.userId != widget.match.createdBy) return;
    setState(() => _loadingRequests = true);
    try {
      final repo = ref.read(joinRequestRepositoryProvider);
      final requests = await repo.getPendingForMatch(widget.match.matchId);
      if (mounted) setState(() => _pendingRequests = requests);
    } catch (e) {
      debugPrint('Failed to load join requests: $e');
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _updateFormation({String? home, String? away}) async {
    if (home == null && away == null) return;
    final repo = ref.read(matchRepositoryProvider);
    try {
      await repo.updateFormation(widget.match.matchId, homeFormation: home, awayFormation: away);
      if (home != null) setState(() => _homeFormation = home);
      if (away != null) setState(() => _awayFormation = away);
    } catch (e) {
      debugPrint('Formation update failed: $e');
    }
  }

  void _showAddPlayerDialog(String team) async {
    final player = await showAddPlayerSheet(
      context,
      ref.read(appwriteServiceProvider),
      team: team,
    );
    if (player != null && mounted) {
      ref.read(matchRosterProvider.notifier).addPlayer(
        widget.match.matchId,
        player,
        team: team,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(matchRosterProvider);
    final homePlayers = rosterState.entries.where((e) => e.team == 'home').toList();
    final awayPlayers = rosterState.entries.where((e) => e.team == 'away').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMatchHero(),
                  const SizedBox(height: 32),
                  _buildInfoGrid(),
                  const SizedBox(height: 16),
                  _buildInviteCode(),
                  const SizedBox(height: 24),
                  _buildTeamFormationPitch(homePlayers, 'home', _homeFormation, AppTheme.cardinal),
                  const SizedBox(height: 24),
                  _buildTeamFormationPitch(awayPlayers, 'away', _awayFormation, AppTheme.navy),
                  const SizedBox(height: 32),
                  _buildJoinRequestsSection(),
                  const SizedBox(height: 32),
                  _buildSquadRoster(homePlayers, awayPlayers),
                  const SizedBox(height: 40),
                  _buildKickOffButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: Colors.transparent,
    expandedHeight: 0,
    pinned: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: AppTheme.voidBg.withValues(alpha: 0.5)),
      ),
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
      onPressed: () => context.pop(),
    ),
    title: Text('MATCH DETAILS', style: AppTheme.t7CardTitle.copyWith(fontSize: 18, letterSpacing: 1)),
  );

  // Team vs Team hero card
  Widget _buildMatchHero() {
    return MotionCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home team shield
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroCtaGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shieldShadowLarge,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.shield, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.match.homeTeamName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.cardinal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // VS text
              Text(
                'VS',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 28),
              ),
              // Away team shield
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.awayDataGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.awayShieldShadow,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.shield, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (widget.match.awayTeamName ?? 'OPPONENT').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.gold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() => Row(
    children: [
      _buildInfoChip(Icons.calendar_today_rounded, _formatDate(widget.match.matchDate)),
      const SizedBox(width: 12),
      _buildVenueChip(),
    ],
  );

  Widget _buildVenueChip() {
    final hasCoords = widget.match.venueLatitude != null && widget.match.venueLongitude != null;
    return Expanded(
      child: GestureDetector(
        onTap: hasCoords
            ? () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => SimpleVenueMapSheet(
                    name: widget.match.venue ?? 'Match Venue',
                    latitude: widget.match.venueLatitude!,
                    longitude: widget.match.venueLongitude!,
                  ),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardinal, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppTheme.cardinal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.match.venue ?? 'TBD',
                  style: AppTheme.bodyBold.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasCoords) ...[
                const SizedBox(width: 4),
                Icon(Icons.map, color: AppTheme.gold, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCode() {
    final code = widget.match.matchId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.navy.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.navy.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code, color: AppTheme.navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVITE CODE',
                  style: AppTheme.labelSmall.copyWith(fontSize: 8, color: AppTheme.navy),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 16, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.navy,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.navy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: AppTheme.navy, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'COPY',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFormationPitch(List<MatchRosterEntry> players, String team, String formation, Color color) {
    final slots = FormationTemplates.getSlotsForFormation(formation);
    final assignedSlots = FormationTemplates.assignPlayersToSlots<MatchRosterEntry>(
      slots: slots,
      players: players,
      getId: (p) => p.playerId,
      getName: (p) => p.playerName,
      getPosition: (p) => p.position,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${team.toUpperCase()} FORMATION',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            _buildFormationChip(formation, color, (f) => _updateFormation(
              home: team == 'home' ? f : null,
              away: team == 'away' ? f : null,
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _pitchExpanded = !_pitchExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pitchExpanded ? 'COLLAPSE' : 'EXPAND',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _pitchExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      size: 14,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: AppTheme.cardBorder,
          ),
          clipBehavior: Clip.antiAlias,
          child: FootballPitchWidget(
            slots: assignedSlots,
            height: _pitchExpanded ? 520 : 250,
            onSlotTap: (slot) => _showAddPlayerDialog(team),
          ),
        ),
      ],
    );
  }

  Widget _buildFormationChip(String current, Color color, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () => _showFormationPicker(current, color, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current,
              style: AppTheme.bebasDisplay.copyWith(fontSize: 12, color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 10, color: color),
          ],
        ),
      ),
    );
  }

  void _showFormationPicker(String current, Color color, ValueChanged<String> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.voidBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SELECT FORMATION', style: AppTheme.labelSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: FormationTemplates.supportedFormations.map((f) {
                  final isSelected = current == f;
                  return GestureDetector(
                    onTap: () {
                      onChanged(f);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppTheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : AppTheme.cardBorder,
                      ),
                      child: Text(
                        f,
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 16,
                          color: isSelected ? AppTheme.parchment : AppTheme.gold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Date chip: #1F000D bg, #00458E border 1px, calendar icon #00458E, text #F5ECD8, radius 10px
  Widget _buildInfoChip(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardinal, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.cardinal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyBold.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildJoinRequestsSection() {
    final auth = ref.watch(authProvider);
    final isCreator = auth.userId == widget.match.createdBy;
    if (!isCreator) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'JOIN REQUESTS',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_pendingRequests.length}',
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 12,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.navy, strokeWidth: 2),
            ),
          )
        else if (_pendingRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.cardBorderLight,
            ),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, color: AppTheme.gold, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No pending requests',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 13,
                    color: AppTheme.mutedParchment,
                  ),
                ),
              ],
            ),
          )
        else
          ..._pendingRequests.map((r) => _buildJoinRequestCard(r)),
      ],
    );
  }

  Widget _buildJoinRequestCard(JoinRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: AppTheme.cardBorderLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x3000458E), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  request.requesterUid.substring(0, 1).toUpperCase(),
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 16,
                    color: AppTheme.cardinal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player ${request.requesterUid.substring(0, 8)}...',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.parchment,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wants position: ${request.requesterPosition}',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 11,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.requesterMessage != null && request.requesterMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${request.requesterMessage!}"',
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.mutedParchment,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _showApproveDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: AppTheme.parchment,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('APPROVE'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.cardinal,
                      side: BorderSide(color: AppTheme.cardinal.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('DECLINE'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveDialog(JoinRequest request) async {
    String selectedSide = 'home';
    String selectedPosition = request.requesterPosition;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.abyss,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  AppTheme.accentBar(),
                  const SizedBox(width: 8),
                  Text('APPROVE PLAYER', style: AppTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 20),
              Text('ASSIGN SIDE', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _sideChip('Home', 'home', selectedSide, (v) => setModalState(() => selectedSide = v)),
                  const SizedBox(width: 10),
                  _sideChip('Away', 'away', selectedSide, (v) => setModalState(() => selectedSide = v)),
                ],
              ),
              const SizedBox(height: 20),
              Text('POSITION', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['GK', 'LB', 'CB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'].map((pos) {
                  final isSelected = selectedPosition == pos;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedPosition = pos),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.cardinal : AppTheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : AppTheme.cardBorder,
                      ),
                      child: Text(
                        pos,
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 14,
                          color: isSelected ? AppTheme.parchment : AppTheme.gold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _approveRequest(request, selectedSide, selectedPosition),
                  style: AppTheme.primaryButton,
                  child: const Text('CONFIRM & ADD TO ROSTER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideChip(String label, String value, String selected, ValueChanged<String> onTap) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (value == 'home' ? AppTheme.cardinal : AppTheme.navy)
                : AppTheme.elevatedSurface,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? null : AppTheme.cardBorder,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 14,
              color: isSelected ? AppTheme.parchment : AppTheme.gold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveRequest(JoinRequest request, String side, String position) async {
    Navigator.pop(context);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      // Approve the join request
      final repo = ref.read(joinRequestRepositoryProvider);
      await repo.approve(request.id, side);

      // Add player to roster
      final player = LivePlayerInfo(
        id: request.requesterUid,
        name: 'Player ${request.requesterUid.substring(0, 8)}',
        position: position,
        team: side,
      );
      await ref.read(matchRosterProvider.notifier).addPlayer(
        widget.match.matchId,
        player,
        team: side,
      );

      await _loadJoinRequests();
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Player approved and added to roster'),
          backgroundColor: AppTheme.navy,
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: AppTheme.cardinal,
        ),
      );
    }
  }

  Future<void> _declineRequest(JoinRequest request) async {
    try {
      final repo = ref.read(joinRequestRepositoryProvider);
      await repo.decline(request.id);
      await _loadJoinRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
            backgroundColor: AppTheme.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppTheme.cardinal,
          ),
        );
      }
    }
  }

  Widget _buildSquadRoster(List<MatchRosterEntry> homePlayers, List<MatchRosterEntry> awayPlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'SQUAD ROSTER',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRosterSection('HOME', homePlayers, AppTheme.cardinal, true),
        const SizedBox(height: 10),
        _buildRosterSection('AWAY', awayPlayers, AppTheme.gold, false),
      ],
    );
  }

  Widget _buildRosterSection(String title, List<MatchRosterEntry> players, Color color, bool isHome) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: AppTheme.cardBorderLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showAddPlayerDialog(title.toLowerCase()),
                child: Text(
                  '+ ADD',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cardinal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded, color: isHome ? AppTheme.cardinal : AppTheme.gold, size: 22),
            ],
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHome ? AppTheme.cardinal : AppTheme.navy,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTheme.dmSans.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHome ? AppTheme.cardinal : AppTheme.gold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${players.length}',
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 12,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No players added', style: AppTheme.labelSmall),
              )
            else
              ...players.map((p) => _playerRow(p, isHome)),
          ],
        ),
      ),
    );
  }

  // Each player row per spec
  Widget _playerRow(MatchRosterEntry p, bool isHome) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle: 36px, bg #2E0012, border 1.5px #00458E30
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x3000458E), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              p.playerName[0].toUpperCase(),
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 16,
                color: AppTheme.cardinal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player name: DM Sans 14sp #F5ECD8 600 weight
          Expanded(
            child: Text(
              p.playerName,
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.parchment,
              ),
            ),
          ),
          // Position badge — tappable for creators to edit
          GestureDetector(
            onTap: () => _changePlayerPosition(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isHome ? const Color(0x1800458E) : const Color(0x180058B8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.position,
                style: AppTheme.dmSans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isHome ? AppTheme.cardinal : AppTheme.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePlayerPosition(MatchRosterEntry entry) async {
    final auth = ref.read(authProvider);
    final isCreator = auth.userId == widget.match.createdBy;
    if (!isCreator) return;

    await showPositionPicker(
      context,
      currentPosition: entry.position,
      onSelected: (position) async {
        final success = await ref.read(matchRosterProvider.notifier).updatePlayerPosition(entry.id, position);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Position updated'),
              backgroundColor: AppTheme.navy,
            ),
          );
        }
      },
    );
  }

  Widget _buildKickOffButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: () => context.push(AppRoutes.liveMatch, extra: widget.match),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTheme.heroCtaGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x6000458E),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: const Text(
            'KICK OFF MATCH',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    ),
  );

  String _formatDate(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${d.day} ${months[d.month-1]} ${d.year}';
  }
}
