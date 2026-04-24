import 'dart:math';
import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../models/match_event_model.dart';
import '../../../../../../../../../features/match/data/models/live_match_models.dart';

/// Single unified football pitch showing both teams simultaneously.
/// Top half = Away team (attacking downward). Bottom half = Home team (attacking upward).
class UnifiedPitchWidget extends StatefulWidget {
  final List<LivePlayerInfo> homePlayers;
  final List<LivePlayerInfo> awayPlayers;
  final List<MatchEventModel> homeEvents;
  final List<MatchEventModel> awayEvents;
  final Map<String, String> homeLineup; // playerId -> positionSlot
  final Map<String, String> awayLineup;
  final String homeTeamName;
  final String awayTeamName;
  final String formation;

  const UnifiedPitchWidget({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeEvents,
    required this.awayEvents,
    required this.homeLineup,
    required this.awayLineup,
    required this.homeTeamName,
    required this.awayTeamName,
    this.formation = '4-4-2',
  });

  @override
  State<UnifiedPitchWidget> createState() => _UnifiedPitchWidgetState();
}

class _UnifiedPitchWidgetState extends State<UnifiedPitchWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final homePositioned = _buildPositionedPlayers(
      players: widget.homePlayers,
      lineup: widget.homeLineup,
      events: widget.homeEvents,
      isHomeTeam: true,
    );
    final awayPositioned = _buildPositionedPlayers(
      players: widget.awayPlayers,
      lineup: widget.awayLineup,
      events: widget.awayEvents,
      isHomeTeam: false,
    );

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
                color: const Color(0xFF1B5E20),
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  stops: [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(_isExpanded ? 0 : 16),
                border: Border.all(color: const Color(0x30FFFFFF)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isExpanded ? 0 : 16),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Stack(
                      children: [
                        // Pitch grass texture (simulated with stripes)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GrassPainter(),
                          ),
                        ),
                        // Pitch markings
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _PitchPainter(),
                        ),
                        // Away team players (top half)
                        ...awayPositioned.map((p) => Positioned(
                          left: (p.xFraction * constraints.maxWidth - 28).clamp(8.0, constraints.maxWidth - 64),
                          top: (p.yFraction * constraints.maxHeight - 36).clamp(8.0, constraints.maxHeight - 88),
                          child: PlayerNode(player: p, isMini: !_isExpanded),
                        )),
                        // Home team players (bottom half)
                        ...homePositioned.map((p) => Positioned(
                          left: (p.xFraction * constraints.maxWidth - 28).clamp(8.0, constraints.maxWidth - 64),
                          top: (p.yFraction * constraints.maxHeight - 36).clamp(8.0, constraints.maxHeight - 88),
                          child: PlayerNode(player: p, isMini: !_isExpanded),
                        )),
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

  List<PositionedPlayer> _buildPositionedPlayers({
    required List<LivePlayerInfo> players,
    required Map<String, String> lineup,
    required List<MatchEventModel> events,
    required bool isHomeTeam,
  }) {
    // Group players by row
    final Map<int, List<LivePlayerInfo>> rowToPlayers = {};
    for (final player in players) {
      final slot = lineup[player.id];
      if (slot == null) continue;
      final row = _positionToRow(slot);
      rowToPlayers.putIfAbsent(row, () => []).add(player);
    }

    // Sort players within each row by horizontal position
    for (final row in rowToPlayers.keys) {
      rowToPlayers[row]!.sort((a, b) {
        final slotA = lineup[a.id] ?? '';
        final slotB = lineup[b.id] ?? '';
        return _horizontalOrder(slotA).compareTo(_horizontalOrder(slotB));
      });
    }

    // Assign X/Y fractions
    final List<PositionedPlayer> result = [];
    final rowKeys = rowToPlayers.keys.toList()..sort();

    for (final rowIndex in rowKeys) {
      final playersInRow = rowToPlayers[rowIndex]!;
      final count = playersInRow.length;

      for (int i = 0; i < count; i++) {
        final player = playersInRow[i];
        final slot = lineup[player.id] ?? '';

        // X: evenly spaced with 10% padding each side
        final xFraction = 0.10 + (i + 1) * (0.80 / (count + 1));

        // Y: divide team's half into bands
        // Home team half: Y from 0.95 to 0.55
        // Away team half: Y from 0.05 to 0.45
        final teamStart = isHomeTeam ? 0.95 : 0.05;
        final teamEnd = isHomeTeam ? 0.55 : 0.45;
        final rowFraction = rowKeys.length > 1 ? rowIndex / (rowKeys.length - 1) : 0.5;
        final yFraction = teamStart + (teamEnd - teamStart) * rowFraction;

        final playerEvents = events.where((e) => e.playerId == player.id).toList();

        result.add(PositionedPlayer(
          playerId: player.id,
          name: player.name,
          positionSlot: slot,
          xFraction: xFraction,
          yFraction: yFraction,
          events: playerEvents,
          isHomeTeam: isHomeTeam,
        ));
      }
    }

    return result;
  }

  int _positionToRow(String slot) {
    switch (slot) {
      case 'GK':
        return 0;
      case 'CB':
      case 'LB':
      case 'RB':
      case 'LWB':
      case 'RWB':
        return 1;
      case 'CDM':
      case 'CM':
      case 'CAM':
      case 'LM':
      case 'RM':
      case 'LAM':
      case 'RAM':
        return 2;
      case 'LW':
      case 'RW':
      case 'ST':
      case 'CF':
        return 3;
      default:
        return 1;
    }
  }

  int _horizontalOrder(String slot) {
    const order = {
      'LB': 0, 'LWB': 0, 'CB1': 1, 'CB2': 2, 'CB': 1, 'RB': 3, 'RWB': 3,
      'LM': 0, 'LAM': 0, 'CM1': 1, 'CM2': 2, 'CM': 1, 'CDM': 1, 'CAM': 2, 'RM': 3, 'RAM': 3,
      'LW': 0, 'ST1': 1, 'ST2': 2, 'ST': 1, 'CF': 1, 'RW': 3,
      'GK': 0,
    };
    return order[slot] ?? 1;
  }
}

/// Grass stripe painter using Dark Colour System
class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 12;
    final paint1 = Paint()..color = const Color(0xFF2E7D32);
    final paint2 = Paint()..color = const Color(0xFF1B5E20);

    for (int i = 0; i < 12; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        i % 2 == 0 ? paint1 : paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Positioned player data with pixel coordinates computed.
class PositionedPlayer {
  final String playerId;
  final String name;
  final String positionSlot;
  final double xFraction;
  final double yFraction;
  final List<MatchEventModel> events;
  final bool isHomeTeam;

  const PositionedPlayer({
    required this.playerId,
    required this.name,
    required this.positionSlot,
    required this.xFraction,
    required this.yFraction,
    required this.events,
    required this.isHomeTeam,
  });

  bool get hasGoal => events.any((e) => e.type == 'goal');
  bool get hasYellowCard => events.any((e) => e.type == 'yellowCard');
  bool get hasRedCard => events.any((e) => e.type == 'redCard');
  bool get hasSubOff => events.any((e) => e.type == 'subOff');
  bool get hasSubOn => events.any((e) => e.type == 'subOn');
}

/// UCL-style player node with jersey, name label, and event icons.
class PlayerNode extends StatelessWidget {
  final PositionedPlayer player;
  final bool isMini;

  const PlayerNode({super.key, required this.player, this.isMini = false});

  @override
  Widget build(BuildContext context) {
    final isFaded = player.hasRedCard || player.hasSubOff;
    final fontSize = isMini ? 10.0 : 10.0;

    return SizedBox(
      width: isMini ? 48 : 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player circle: bg GradientA (home) or GradientC (away), size 38px
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: player.isHomeTeam
                  ? AppTheme.heroCtaGradient
                  : AppTheme.awayDataGradient,
              shape: BoxShape.circle,
              boxShadow: player.isHomeTeam
                  ? AppTheme.playerCircleShadowHome
                  : AppTheme.playerCircleShadowAway,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: isFaded ? 0.55 : 1.0,
              child: Text(
                _initials(player.name),
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  fontFamily: AppTheme.displayFontFamily,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Name label: DM Sans 10sp #F5ECD8, bg #00000070, padding 2px 6px, radius 4px
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x70000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _firstName,
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: isMini ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          // Event icons
          if (player.events.isNotEmpty) _buildEventIcons(),
        ],
      ),
    );
  }

  String get _firstName {
    final parts = player.name.trim().split(' ');
    return parts.length >= 2 ? parts[0] : player.name;
  }

  Widget _buildEventIcons() {
    final icons = <Widget>[];
    final goals = player.events.where((e) => e.type == 'goal').length;
    for (int i = 0; i < goals; i++) {
      icons.add(_icon('⚽'));
    }
    if (player.hasYellowCard) icons.add(_icon('🟨'));
    if (player.hasRedCard) icons.add(_icon('🟥'));
    final subOff = player.events.where((e) => e.type == 'subOff').firstOrNull;
    if (subOff != null) icons.add(_minuteIcon('↓', subOff.minute, AppTheme.cardinal));
    final subOn = player.events.where((e) => e.type == 'subOn').firstOrNull;
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

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
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
      decoration: const BoxDecoration(
        color: AppTheme.voidBg,
        border: Border(
          bottom: BorderSide(color: Color(0x15C1121F)),
        ),
      ),
      child: Row(
        children: [
          // Home dot: #C1121F filled 10px circle
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
          // VS: #669BBC DM Sans 11sp
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
          // Away dot: #003049 filled 10px circle
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

/// Event legend row per spec.
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

/// Custom painter for full pitch with all markings using Dark Colour System.
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0x40FFFFFF) // white at 25% opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(8, 8, w - 16, h - 16), paint);

    // Halfway line
    canvas.drawLine(Offset(8, h * 0.5), Offset(w - 8, h * 0.5), paint);

    // Centre circle
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.15, paint);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      2,
      Paint()..color = const Color(0x40FFFFFF)..style = PaintingStyle.fill,
    );

    // TOP penalty box (away team's goal) — at y=8
    final penBoxW = w * 0.5;
    final penBoxH = h * 0.15;
    canvas.drawRect(
      Rect.fromLTWH((w - penBoxW) / 2, 8, penBoxW, penBoxH), paint);

    // TOP 6-yard box
    final sixYardW = w * 0.25;
    final sixYardH = h * 0.05;
    canvas.drawRect(
      Rect.fromLTWH((w - sixYardW) / 2, 8, sixYardW, sixYardH), paint);

    // TOP penalty arc
    canvas.drawArc(
      Rect.fromLTWH((w - penBoxW) / 2, 8 + penBoxH - 30, penBoxW, 60),
      0, pi, false, paint);

    // BOTTOM penalty box (home team's goal) — at bottom
    canvas.drawRect(
      Rect.fromLTWH((w - penBoxW) / 2, h - 8 - penBoxH, penBoxW, penBoxH), paint);

    // BOTTOM 6-yard box
    canvas.drawRect(
      Rect.fromLTWH((w - sixYardW) / 2, h - 8 - sixYardH, sixYardW, sixYardH), paint);

    // BOTTOM penalty arc
    canvas.drawArc(
      Rect.fromLTWH((w - penBoxW) / 2, h - 8 - penBoxH - 30, penBoxW, 60),
      pi, pi, false, paint);

    // Penalty spots
    canvas.drawCircle(
      Offset(w * 0.5, 8 + penBoxH * 0.75),
      2,
      Paint()..color = const Color(0x40FFFFFF)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h - 8 - penBoxH * 0.75),
      2,
      Paint()..color = const Color(0x40FFFFFF)..style = PaintingStyle.fill,
    );

    // Corner arcs
    canvas.drawArc(Rect.fromLTWH(8, 8, 15, 15), 0, pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(w - 23, 8, 15, 15), pi / 2, pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(8, h - 23, 15, 15), -pi / 2, pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(w - 23, h - 23, 15, 15), pi, pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
