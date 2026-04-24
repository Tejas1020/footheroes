import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_roster_provider.dart';
import 'package:footheroes/models/match_model.dart';
import 'package:footheroes/models/match_roster_model.dart';
import 'package:footheroes/models/formation_model.dart';
import 'package:footheroes/core/router/app_router.dart';
import 'package:footheroes/widgets/add_player_sheet.dart';
import 'package:footheroes/widgets/motion_card.dart';
import 'package:footheroes/widgets/football_pitch_widget.dart';

/// Upcoming Match Detail — Full Visual Upgrade per Screen 3 spec.
class UpcomingMatchDetailScreen extends ConsumerStatefulWidget {
  final MatchModel match;
  const UpcomingMatchDetailScreen({super.key, required this.match});

  @override
  ConsumerState<UpcomingMatchDetailScreen> createState() => _UpcomingMatchDetailScreenState();
}

class _UpcomingMatchDetailScreenState extends ConsumerState<UpcomingMatchDetailScreen> {
  bool _pitchExpanded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchRosterProvider.notifier).loadRoster(widget.match.matchId);
    });
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
      backgroundColor: AppTheme.voidBg,
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
                  const SizedBox(height: 24),
                  _buildFormationPitch(homePlayers),
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
    backgroundColor: AppTheme.voidBg,
    expandedHeight: 0,
    pinned: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
      onPressed: () => context.pop(),
    ),
    title: Text('MATCH DETAILS', style: AppTheme.bebasDisplay.copyWith(fontSize: 18, letterSpacing: 1)),
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
                      child: const Icon(Icons.shield, color: AppTheme.gold, size: 36),
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
                      child: const Icon(Icons.shield, color: AppTheme.gold, size: 36),
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
      _buildInfoChip(Icons.location_on_rounded, widget.match.venue ?? 'TBD'),
    ],
  );

  Widget _buildFormationPitch(List<MatchRosterEntry> homePlayers) {
    final slots = FormationTemplates.getSlotsForFormation('4-4-2');
    // Map roster players into formation slots
    final assignedSlots = <PlayerPositionSlot>[];
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (i < homePlayers.length) {
        assignedSlots.add(PlayerPositionSlot(
          slotId: slot.slotId,
          positionLabel: slot.positionLabel,
          xPercent: slot.xPercent,
          yPercent: slot.yPercent,
          assignedPlayerId: homePlayers[i].playerId,
          assignedPlayerName: homePlayers[i].playerName,
        ));
      } else {
        assignedSlots.add(slot);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'FORMATION',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
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
                        color: AppTheme.cardinal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _pitchExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      size: 14,
                      color: AppTheme.cardinal,
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
            onSlotTap: (slot) => _showAddPlayerDialog('home'),
          ),
        ),
      ],
    );
  }

  // Date chip: #1F000D bg, #C1121F border 1px, calendar icon #C1121F, text #F5ECD8, radius 10px
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
          // Avatar circle: 36px, bg #2E0012, border 1.5px #C1121F30
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x30C1121F), width: 1.5),
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
          // Position badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isHome ? const Color(0x18C1121F) : const Color(0x18003049),
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
        ],
      ),
    );
  }

  Widget _buildKickOffButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: () => context.push(AppRoutes.liveMatch, extra: widget.match),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.gold,
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
              color: const Color(0x60C1121F),
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
