import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../providers/match_timer_provider.dart';
import '../../../../../../../../../../models/match_event_model.dart';

/// Team column showing abbreviation circle, label, and name.
class TeamColumn extends StatelessWidget {
  final String label;
  final String name;
  final int score;
  final Color accentColor;

  const TeamColumn({
    super.key,
    required this.label,
    required this.name,
    required this.score,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor.withValues(alpha: 0.1),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name.substring(0, name.length.clamp(0, 3)).toUpperCase() : '???',
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 18,
            color: accentColor,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(name,
          style: AppTheme.bodyBold.copyWith(fontSize: 11),
          overflow: TextOverflow.ellipsis),
      Text(label,
          style: AppTheme.labelSmall),
    ]);
  }
}

/// Center score display with half/period label.
class ScoreCenter extends StatelessWidget {
  final LiveMatchState matchState;
  final MatchTimerState timerState;

  const ScoreCenter({super.key, required this.matchState, required this.timerState});

  @override
  Widget build(BuildContext context) {
    final label = timerState.status == TimerStatus.halftime
        ? 'HALF TIME'
        : timerState.status == TimerStatus.finished
            ? 'FULL TIME'
            : timerState.currentHalf == 1
                ? '1ST HALF'
                : '2ND HALF';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        '${matchState.homeScore} - ${matchState.awayScore}',
        style: AppTheme.bebasDisplay.copyWith(
          fontSize: 36,
          color: AppTheme.parchment,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: AppTheme.labelSmall.copyWith(fontSize: 10),
        ),
      ),
    ]);
  }
}

/// Control button used in match timer controls.
class ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ControlBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: AppTheme.bodyBold.copyWith(
                fontSize: 12,
                color: color,
              )),
        ]),
      ),
    );
  }
}

/// Single event row in the match events list — tappable to edit/void.
class EventRow extends StatelessWidget {
  final MatchEventModel event;
  final VoidCallback? onTap;
  const EventRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (event.type) {
      'goal' => (Icons.sports_soccer, AppTheme.cardinal),
      'assist' => (Icons.handshake, AppTheme.gold),
      'yellowCard' => (Icons.square, AppTheme.parchment),
      'redCard' => (Icons.square, AppTheme.cardinal),
      'subOn' => (Icons.keyboard_double_arrow_up, AppTheme.gold),
      'subOff' => (Icons.keyboard_double_arrow_down, AppTheme.cardinal),
      _ => (Icons.circle, AppTheme.gold),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(
            "${event.minute}'",
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 16,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.playerName,
              style: AppTheme.bodyBold,
            ),
          ),
          Text(
            event.displayFull.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined, color: AppTheme.gold.withValues(alpha: 0.5), size: 16),
        ]),
      ),
    );
  }
}