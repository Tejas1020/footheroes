import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../models/match_event_model.dart';

/// Player event selector — shows selectable list of active players
/// filtered by redCardedPlayerIds (sent-off players are excluded).
class PlayerEventSelector extends ConsumerWidget {
  final List<PlayerInfo> allPlayers;
  final List<String> redCardedPlayerIds;
  final void Function(PlayerInfo player) onPlayerTap;

  const PlayerEventSelector({
    super.key,
    required this.allPlayers,
    required this.redCardedPlayerIds,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlayers = allPlayers.where((p) => !redCardedPlayerIds.contains(p.id)).toList();
    final sentOffPlayers = allPlayers.where((p) => redCardedPlayerIds.contains(p.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activePlayers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROSTER — tap to log event',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                    letterSpacing: 0.1,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    '+ ADD',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...activePlayers.map((player) => _PlayerRowWidget(player: player, onTap: () => onPlayerTap(player))),
        ],
        if (sentOffPlayers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'SENT OFF',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.cardinal,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          ...sentOffPlayers.map((player) => _SentOffPlayerRow(player: player)),
        ],
      ],
    );
  }
}

class PlayerInfo {
  final String id;
  final String name;
  final String position;
  const PlayerInfo({required this.id, required this.name, required this.position});
}

class _PlayerRowWidget extends ConsumerWidget {
  final PlayerInfo player;
  final VoidCallback onTap;

  const _PlayerRowWidget({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(liveMatchProvider);
    final events = matchState.events.where((e) => e.playerId == player.id).toList();
    final rating = matchState.playerRatings[player.id] ?? 6.0;
    final hasCard = events.any((e) => e.type == 'redCard' || e.type == 'yellowCard');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.parchment,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.parchment,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              player.position,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildEventSummary(events),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasCard
                              ? AppTheme.cardinal
                              : events.isNotEmpty
                                  ? AppTheme.navy
                                  : AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rating >= 7
                        ? AppTheme.navy.withValues(alpha: 0.2)
                        : rating >= 5
                            ? AppTheme.rose.withValues(alpha: 0.2)
                            : AppTheme.cardinal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: rating >= 7
                          ? AppTheme.navy
                          : rating >= 5
                              ? AppTheme.rose
                              : AppTheme.cardinal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.add_circle_outline, color: AppTheme.gold, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildEventSummary(List<MatchEventModel> events) {
    if (events.isEmpty) return 'No events logged';
    final goals = events.where((e) => e.type == 'goal').length;
    final assists = events.where((e) => e.type == 'assist').length;
    final yellows = events.where((e) => e.type == 'yellowCard').length;
    final reds = events.where((e) => e.type == 'redCard').length;
    final parts = <String>[];
    if (goals > 0) parts.add('${goals}G');
    if (assists > 0) parts.add('${assists}A');
    if (yellows > 0) parts.add('$yellows YC');
    if (reds > 0) parts.add('Red Card');
    return parts.isEmpty ? 'No events logged' : parts.join(' • ');
  }
}

class _SentOffPlayerRow extends StatelessWidget {
  final PlayerInfo player;
  const _SentOffPlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.5,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardinal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.square, color: AppTheme.cardinal, size: 16),
              const SizedBox(width: 8),
              Text(
                player.name,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gold,
                ),
              ),
              const Spacer(),
              Text(
                'Sent off',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  color: AppTheme.cardinal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}