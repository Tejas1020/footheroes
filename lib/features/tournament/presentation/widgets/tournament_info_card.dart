import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/tournament_model.dart';

/// Tournament info card shown in the Info tab.
class TournamentInfoCard extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentInfoCard({super.key, required this.tournament});

  String _getTypeText(String type) {
    return switch (type) {
      'knockout' => 'Knockout',
      'league' => 'League',
      'group_knockout' => 'Groups + Knockout',
      _ => type,
    };
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
            'Tournament Details',
            style: MidnightPitchTheme.titleMD.copyWith(
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Format', value: tournament.format),
          _InfoRow(label: 'Type', value: _getTypeText(tournament.type)),
          _InfoRow(
              label: 'Teams',
              value: '${tournament.teamsRegistered}/${tournament.maxTeams}'),
          if (tournament.venue != null)
            _InfoRow(label: 'Venue', value: tournament.venue!),
          if (tournament.startDate != null)
            _InfoRow(label: 'Start Date', value: _formatDate(tournament.startDate!)),
          if (tournament.endDate != null)
            _InfoRow(label: 'End Date', value: _formatDate(tournament.endDate!)),
          if (tournament.description != null) ...[
            const SizedBox(height: 16),
            Text(tournament.description!, style: MidnightPitchTheme.bodySM),
          ],
          if (tournament.sponsorName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sponsored by ${tournament.sponsorName}',
                  style: TextStyle(
                      color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: MidnightPitchTheme.labelSM),
          Text(value,
              style: MidnightPitchTheme.bodySM
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}