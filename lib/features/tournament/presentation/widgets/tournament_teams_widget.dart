import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/tournament_model.dart';

/// Tournament teams widget — displays registered teams.
class TournamentTeamsWidget extends StatelessWidget {
  final TournamentModel tournament;
  final bool isOrganizer;
  final void Function(TournamentModel tournament)? onEditTournament;
  final void Function(TournamentModel tournament)? onOpenRegistration;
  final void Function(TournamentModel tournament)? onStartTournament;

  const TournamentTeamsWidget({
    super.key,
    required this.tournament,
    this.isOrganizer = false,
    this.onEditTournament,
    this.onOpenRegistration,
    this.onStartTournament,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeamsSection(),
        if (isOrganizer) ...[
          const SizedBox(height: 16),
          _buildOrganizerActions(context),
        ],
      ],
    );
  }

  Widget _buildTeamsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Teams',
                style: MidnightPitchTheme.titleMD.copyWith(
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              Text(
                '${tournament.teamsRegistered}/${tournament.maxTeams}',
                style: MidnightPitchTheme.labelSM,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tournament.teamIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No teams registered yet',
                style: MidnightPitchTheme.bodySM,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tournament.teamIds.asMap().entries.map((entry) {
                final index = entry.key;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Team ${index + 1}',
                    style: MidnightPitchTheme.bodySM,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildOrganizerActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizer Actions',
            style: MidnightPitchTheme.titleMD.copyWith(
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          if (tournament.isDraft) ...[
            _actionButton(
              label: 'Edit Tournament',
              icon: Icons.edit,
              onTap: () => onEditTournament?.call(tournament),
              color: MidnightPitchTheme.surfaceContainerHigh,
              textColor: MidnightPitchTheme.primaryText,
            ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'Open Registration',
              icon: Icons.add_circle_outline,
              onTap: () => onOpenRegistration?.call(tournament),
              color: Colors.blue,
              textColor: Colors.white,
            ),
          ],
          if (tournament.isRegistration) ...[
            _actionButton(
              label: tournament.canStart ? 'Start Tournament' : 'Need at least 2 teams to start',
              icon: Icons.play_arrow,
              onTap: tournament.canStart ? () => onStartTournament?.call(tournament) : null,
              color: MidnightPitchTheme.electricBlue,
              textColor: Colors.black,
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}