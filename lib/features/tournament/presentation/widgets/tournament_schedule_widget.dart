import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/tournament_model.dart';

/// Tournament schedule widget — displays match schedule in the Info tab.
class TournamentScheduleWidget extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentScheduleWidget({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.startDate == null && tournament.endDate == null) {
      return const SizedBox.shrink();
    }
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
            'Schedule',
            style: MidnightPitchTheme.titleMD.copyWith(
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          if (tournament.startDate != null)
            _ScheduleRow(
              label: 'Start',
              date: tournament.startDate!,
              icon: Icons.play_arrow,
            ),
          if (tournament.endDate != null)
            _ScheduleRow(
              label: 'End',
              date: tournament.endDate!,
              icon: Icons.stop,
            ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;

  const _ScheduleRow({required this.label, required this.date, required this.icon});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: MidnightPitchTheme.electricMint, size: 20),
          const SizedBox(width: 12),
          Text(label, style: MidnightPitchTheme.labelSM),
          const Spacer(),
          Text(
            _formatDate(date),
            style: MidnightPitchTheme.bodySM.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}