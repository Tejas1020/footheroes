import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/models/match_event_model.dart';
import 'package:footheroes/features/match/data/models/live_match_models.dart';
import 'package:footheroes/models/formation_model.dart';
import 'package:footheroes/widgets/football_pitch_widget.dart';

/// Single unified football pitch showing both teams in exact formation positions.
/// Uses FormationTemplates for precise x/y coordinates.
/// Top half = Away team (flipped vertically). Bottom half = Home team.
class UnifiedPitchWidget extends StatefulWidget {
  final List<LivePlayerInfo> homePlayers;
  final List<LivePlayerInfo> awayPlayers;
  final List<MatchEventModel> homeEvents;
  final List<MatchEventModel> awayEvents;
  final String homeTeamName;
  final String awayTeamName;
  final String homeFormation;
  final String awayFormation;

  const UnifiedPitchWidget({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeEvents,
    required this.awayEvents,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeFormation = '4-4-2',
    this.awayFormation = '4-4-2',
  });

  @override
  State<UnifiedPitchWidget> createState() => _UnifiedPitchWidgetState();
}

class _UnifiedPitchWidgetState extends State<UnifiedPitchWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Team header bar
        _TeamHeaderBar(homeTeam: widget.homeTeamName, awayTeam: widget.awayTeamName),
        // The pitch
        Expanded(
          child: GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.all(_isExpanded ? 0 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isExpanded ? 0 : 16),
                border: Border.all(color: const Color(0x30FFFFFF)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isExpanded ? 0 : 16),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Stack(
                      children: [
                        // Pitch background with markings
                        Positioned.fill(
                          child: CustomPaint(
                            painter: FootballPitchPainter(
                              pitchColor: const Color(0xFF1B5E20),
                              lineColor: Colors.white.withValues(alpha: 0.25),
                              showGrassPattern: true,
                              isFlipped: false,
                            ),
                          ),
                        ),
                        // Away team players (top half, flipped Y)
                        ..._buildFormationPlayers(
                          players: widget.awayPlayers,
                          events: widget.awayEvents,
                          formation: widget.awayFormation,
                          isHomeTeam: false,
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        // Home team players (bottom half, normal Y)
                        ..._buildFormationPlayers(
                          players: widget.homePlayers,
                          events: widget.homeEvents,
                          formation: widget.homeFormation,
                          isHomeTeam: true,
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        // Tap to expand indicator
                        if (!_isExpanded)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.voidBg.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fullscreen, color: AppTheme.parchment, size: 16),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Event legend
        if (!_isExpanded) _EventLegend(),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Build positioned player widgets using exact formation coordinates.
  List<Widget> _buildFormationPlayers({
    required List<LivePlayerInfo> players,
    required List<MatchEventModel> events,
    required String formation,
    required bool isHomeTeam,
    required double maxWidth,
    required double maxHeight,
  }) {
    final slots = FormationTemplates.getSlotsForFormation(formation);
    final result = <Widget>[];

    // Map players to slots by position matching
    final assignedSlots = _mapPlayersToSlots(players, slots);

    for (final slot in assignedSlots) {
      if (slot.assignedPlayerId == null) continue;

      // Home team: scale to bottom half (0.5 - 1.0)
      // Away team: scale to top half (0.0 - 0.5), mirrored
      final xFraction = slot.xPercent;
      final yFraction = isHomeTeam
          ? (0.5 + slot.yPercent * 0.5)
          : (0.5 * (1.0 - slot.yPercent));

      final left = (xFraction * maxWidth - 28).clamp(8.0, maxWidth - 64);
      final top = (yFraction * maxHeight - 36).clamp(8.0, maxHeight - 88);

      final playerEvents = events.where((e) => e.playerId == slot.assignedPlayerId).toList();

      result.add(
        Positioned(
          left: left,
          top: top,
          child: FormationPlayerNode(
            playerId: slot.assignedPlayerId!,
            name: slot.assignedPlayerName ?? 'Player',
            positionSlot: slot.positionLabel,
            events: playerEvents,
            isHomeTeam: isHomeTeam,
            isMini: !_isExpanded,
          ),
        ),
      );
    }

    return result;
  }

  /// Map players to formation slots using position label matching.
  List<PlayerPositionSlot> _mapPlayersToSlots(
    List<LivePlayerInfo> players,
    List<PlayerPositionSlot> slots,
  ) {
    final result = <PlayerPositionSlot>[];
    final usedPlayerIds = <String>{};

    // First pass: exact position label match
    for (final slot in slots) {
      final match = players.firstWhere(
        (p) =>
            !usedPlayerIds.contains(p.id) &&
            _normalizePosition(p.position) == _normalizePosition(slot.positionLabel),
        orElse: () => LivePlayerInfo(id: '', name: '', position: '', team: ''),
      );

      if (match.id.isNotEmpty) {
        usedPlayerIds.add(match.id);
        result.add(
          slot.copyWith(
            assignedPlayerId: match.id,
            assignedPlayerName: match.name,
          ),
        );
      } else {
        result.add(slot);
      }
    }

    // Second pass: fill empty slots with remaining players (fallback)
    final remainingPlayers = players.where((p) => !usedPlayerIds.contains(p.id)).toList();
    int remainingIdx = 0;
    for (int i = 0; i < result.length; i++) {
      if (!result[i].isAssigned && remainingIdx < remainingPlayers.length) {
        final player = remainingPlayers[remainingIdx++];
        result[i] = result[i].copyWith(
          assignedPlayerId: player.id,
          assignedPlayerName: player.name,
        );
      }
    }

    return result;
  }

  String _normalizePosition(String pos) {
    return pos.trim().toUpperCase().replaceAll(RegExp(r'\d'), '');
  }
}

/// UCL-style player node for formation display with jersey, name label, and event icons.
class FormationPlayerNode extends StatelessWidget {
  final String playerId;
  final String name;
  final String positionSlot;
  final List<MatchEventModel> events;
  final bool isHomeTeam;
  final bool isMini;

  const FormationPlayerNode({
    super.key,
    required this.playerId,
    required this.name,
    required this.positionSlot,
    required this.events,
    required this.isHomeTeam,
    this.isMini = false,
  });

  bool get hasGoal => events.any((e) => e.type == 'goal');
  bool get hasYellowCard => events.any((e) => e.type == 'yellowCard');
  bool get hasRedCard => events.any((e) => e.type == 'redCard');
  bool get hasSubOff => events.any((e) => e.type == 'subOff');
  bool get hasSubOn => events.any((e) => e.type == 'subOn');

  @override
  Widget build(BuildContext context) {
    final isFaded = hasRedCard || hasSubOff;

    return SizedBox(
      width: isMini ? 48 : 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player circle with position label inside
          Container(
            width: isMini ? 32 : 38,
            height: isMini ? 32 : 38,
            decoration: BoxDecoration(
              gradient: isHomeTeam
                  ? AppTheme.heroCtaGradient
                  : AppTheme.awayDataGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: isHomeTeam
                  ? AppTheme.playerCircleShadowHome
                  : AppTheme.playerCircleShadowAway,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: isFaded ? 0.55 : 1.0,
              child: Text(
                positionSlot,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isMini ? 10 : 12,
                  fontFamily: AppTheme.displayFontFamily,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Name label
          Container(
            constraints: const BoxConstraints(maxWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x70000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _shortName,
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: isMini ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          // Event icons
          if (events.isNotEmpty) _buildEventIcons(),
        ],
      ),
    );
  }

  String get _shortName {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts.last.length > 8 ? parts.last.substring(0, 8) : parts.last;
    }
    return name.length > 8 ? name.substring(0, 8) : name;
  }

  Widget _buildEventIcons() {
    final icons = <Widget>[];
    final goals = events.where((e) => e.type == 'goal').length;
    for (int i = 0; i < goals; i++) {
      icons.add(_icon('⚽'));
    }
    if (hasYellowCard) icons.add(_icon('🟨'));
    if (hasRedCard) icons.add(_icon('🟥'));
    final subOff = events.where((e) => e.type == 'subOff').firstOrNull;
    if (subOff != null) icons.add(_minuteIcon('↓', subOff.minute, AppTheme.cardinal));
    final subOn = events.where((e) => e.type == 'subOn').firstOrNull;
    if (subOn != null) icons.add(_minuteIcon('↑', subOn.minute, AppTheme.gold));
    return Wrap(alignment: WrapAlignment.center, spacing: 1, children: icons);
  }

  Widget _icon(String emoji) => Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: AppTheme.voidBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(emoji, style: TextStyle(fontSize: isMini ? 9 : 11, color: AppTheme.parchment)),
      );

  Widget _minuteIcon(String arrow, int minute, Color color) => Text(
        '$arrow$minute\'',
        style: TextStyle(color: color, fontSize: isMini ? 8 : 9, fontWeight: FontWeight.bold),
      );
}

/// Team header bar showing both team names.
class _TeamHeaderBar extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;

  const _TeamHeaderBar({required this.homeTeam, required this.awayTeam});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.voidBg,
      child: Row(
        children: [
          // Home dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.cardinal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              homeTeam.toUpperCase(),
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // VS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'VS',
              style: AppTheme.dmSans.copyWith(
                fontSize: 11,
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              awayTeam.toUpperCase(),
              textAlign: TextAlign.end,
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Away dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Event legend row.
class _EventLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Icons.sports_soccer, 'Goal', AppTheme.cardinal),
          const SizedBox(width: 16),
          _legendItem(Icons.rectangle, 'Yellow', AppTheme.redMid),
          const SizedBox(width: 16),
          _legendItem(Icons.rectangle, 'Red', AppTheme.cardinal),
          const SizedBox(width: 16),
          _legendItem(Icons.keyboard_double_arrow_up, 'Sub on', AppTheme.navy),
          const SizedBox(width: 16),
          _legendItem(Icons.keyboard_double_arrow_down, 'Sub off', AppTheme.redDeep),
        ],
      ),
    );
  }

  static Widget _legendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 10,
            color: AppTheme.gold,
          ),
        ),
      ],
    );
  }
}
