import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/match_model.dart';
import '../../../../models/match_event_model.dart';

/// Halftime summary modal — shows score and key events before 2nd half.
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
    final homeEvents = events.where((e) => e.type == 'goal').toList();
    final homeGoals = homeEvents.length;
    final awayGoals = 0; // Simplified — would need team info from match

    return Dialog(
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 40,
              color: MidnightPitchTheme.championGold,
            ),
            const SizedBox(height: 12),
            Text(
              'HALF TIME',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: MidnightPitchTheme.championGold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$homeGoals — $awayGoals',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: MidnightPitchTheme.primaryText,
                letterSpacing: -2,
              ),
            ),
            Text(
              '${match.homeTeamId} vs ${match.awayTeamId}',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
            const SizedBox(height: 20),
            if (events.isNotEmpty) ...[
              Text(
                'FIRST HALF EVENTS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFF1E2A3A),
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
                      'goal' => MidnightPitchTheme.electricMint,
                      'yellowCard' => MidnightPitchTheme.championGold,
                      'redCard' => MidnightPitchTheme.liveRed,
                      _ => MidnightPitchTheme.skyBlue,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            "${event.minute}'",
                            style: TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: MidnightPitchTheme.mutedText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.playerName,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 13,
                                color: MidnightPitchTheme.primaryText,
                              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: MidnightPitchTheme.electricMint,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'START 2ND HALF',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}