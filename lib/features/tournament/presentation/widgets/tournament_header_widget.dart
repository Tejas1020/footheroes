import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../models/tournament_model.dart';

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
      backgroundColor: AppTheme.voidBg,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.parchment),
        onPressed: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            context.go('/tournaments');
          }
        },
      ),
      title: Text(
        tournament.name,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.parchment,
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
                AppTheme.voidBg,
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
                            size: 16, color: AppTheme.gold),
                        const SizedBox(width: 4),
                        Text(tournament.venue!,
                            style: TextStyle(
                                color: AppTheme.gold,
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
      'draft' => (AppTheme.gold, 'Draft'),
      'registration' => (AppTheme.redMid, 'Open'),
      'active' => (AppTheme.gold, 'Live'),
      'completed' => (AppTheme.parchment, 'Completed'),
      _ => (AppTheme.gold, status),
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
        color: AppTheme.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(format,
          style: TextStyle(
              color: AppTheme.navy,
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
      'knockout' => AppTheme.navy,
      'league' => AppTheme.blueMid,
      'group_knockout' => AppTheme.cardinal,
      _ => AppTheme.gold,
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