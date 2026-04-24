import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../models/match_model.dart';
import '../../../../../../../../../../models/match_event_model.dart';

/// Halftime summary modal using Dark Colour System.
class HalftimeSummaryModal extends StatelessWidget {
  final MatchModel match;
  final List<MatchEventModel> events;
  final VoidCallback onContinue;

  const HalftimeSummaryModal({
    super.key,
    required this.match,
    required this.events,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final homeGoals = events.where((e) => e.type == 'goal' && e.team == 'home').length;
    final awayGoals = events.where((e) => e.type == 'goal' && e.team == 'away').length;

    return Dialog(
      backgroundColor: AppTheme.abyss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 40,
              color: AppTheme.cardinal,
            ),
            const SizedBox(height: 12),
            Text(
              'HALF TIME',
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.cardinal,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$homeGoals — $awayGoals',
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 48,
                color: AppTheme.parchment,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${match.homeTeamName} vs ${match.awayTeamName}',
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 20),
            if (events.isNotEmpty) ...[
              Text(
                'FIRST HALF EVENTS',
                style: AppTheme.labelSmall,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppTheme.cardBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final icon = switch (event.type) {
                      'goal' => Icons.sports_soccer,
                      'assist' => Icons.handshake,
                      'yellowCard' => Icons.square,
                      'redCard' => Icons.square,
                      _ => Icons.circle,
                    };
                    final color = switch (event.type) {
                      'goal' => AppTheme.cardinal,
                      'yellowCard' => AppTheme.parchment,
                      'redCard' => AppTheme.cardinal,
                      _ => AppTheme.gold,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            "${event.minute}'",
                            style: AppTheme.bebasDisplay.copyWith(
                              fontSize: 14,
                              color: AppTheme.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.playerName,
                              style: AppTheme.bodyBold.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onContinue,
                style: AppTheme.primaryButton,
                child: const Text('START 2ND HALF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}