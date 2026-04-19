import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/tournament_model.dart';

/// Tournament header — sliver app bar + status/format/type badges.
class TournamentHeaderWidget extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback? onBack;

  const TournamentHeaderWidget({
    super.key,
    required this.tournament,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: MidnightPitchTheme.surfaceDim,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: MidnightPitchTheme.primaryText),
        onPressed: onBack ?? () => Navigator.maybePop(context),
      ),
      title: Text(
        tournament.name,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MidnightPitchTheme.primaryText,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.3),
                MidnightPitchTheme.surfaceDim,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusBadge(status: tournament.status),
                      const SizedBox(width: 8),
                      _FormatBadge(format: tournament.format),
                      const SizedBox(width: 8),
                      _TypeBadge(type: tournament.type),
                    ],
                  ),
                  if (tournament.venue != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: MidnightPitchTheme.mutedText),
                        const SizedBox(width: 4),
                        Text(tournament.venue!,
                            style: TextStyle(
                                color: MidnightPitchTheme.mutedText,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      'draft' => (Colors.grey, 'Draft'),
      'registration' => (Colors.blue, 'Open'),
      'active' => (Colors.green, 'Live'),
      'completed' => (Colors.amber, 'Completed'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final String format;
  const _FormatBadge({required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(format,
          style: TextStyle(
              color: MidnightPitchTheme.electricBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final text = switch (type) {
      'knockout' => 'Knockout',
      'league' => 'League',
      'group_knockout' => 'Groups + KO',
      _ => type,
    };
    final color = switch (type) {
      'knockout' => Colors.purple,
      'league' => Colors.teal,
      'group_knockout' => Colors.deepOrange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}