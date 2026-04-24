import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:footheroes/theme/app_theme.dart';
import '../models/tournament_model.dart';

/// Tournament card for displaying tournament info in lists.
class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap;
  final VoidCallback? onRegisterTap;
  final bool showStatus;
  final bool isOrganizer;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
    this.onRegisterTap,
    this.showStatus = true,
    this.isOrganizer = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(tournament.status);
    final statusText = _getStatusText(tournament.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Format badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tournament.format,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Tournament name
              Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Type and teams count
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: AppTheme.gold),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeText(tournament.type),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.groups, size: 16, color: AppTheme.gold),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.teamsRegistered}/${tournament.maxTeams} teams',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
              if (tournament.venue != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppTheme.gold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament.venue!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.gold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (tournament.startDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTheme.gold),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(tournament.startDate, tournament.endDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ],
              // Sponsor badge
              if (tournament.sponsorName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchment,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.parchment),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppTheme.parchment),
                      const SizedBox(width: 6),
                      Text(
                        'Sponsored by ${tournament.sponsorName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.parchment,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Action button
              if (tournament.isRegistration && !isOrganizer && onRegisterTap != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: tournament.isFull ? null : onRegisterTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      tournament.isFull ? 'Tournament Full' : 'Register Team',
                    ),
                  ),
                ),
              ],
              // Organizer actions
              if (isOrganizer && tournament.isDraft) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTap,
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Open Registration'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.gold;
      case 'registration':
        return AppTheme.redMid;
      case 'active':
        return AppTheme.gold;
      case 'completed':
        return AppTheme.parchment;
      default:
        return AppTheme.gold;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'registration':
        return 'Open';
      case 'active':
        return 'Live';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'knockout':
        return 'Knockout';
      case 'league':
        return 'League';
      case 'group_knockout':
        return 'Groups + Knockout';
      default:
        return type;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'TBD';
    final startStr = '${start.day}/${start.month}/${start.year}';
    if (end == null) return startStr;
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr - $endStr';
  }
}

/// Compact tournament card for smaller displays.
class TournamentCardCompact extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap;

  const TournamentCardCompact({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              tournament.format,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          tournament.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_getTypeText(tournament.type)} • ${tournament.teamsRegistered}/${tournament.maxTeams} teams',
          style: TextStyle(
            color: AppTheme.gold,
            fontSize: 12,
          ),
        ),
        trailing: _buildStatusChip(context),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final statusColor = _getStatusColor(tournament.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(tournament.status),
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.gold;
      case 'registration':
        return AppTheme.redMid;
      case 'active':
        return AppTheme.gold;
      case 'completed':
        return AppTheme.parchment;
      default:
        return AppTheme.gold;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'registration':
        return 'Open';
      case 'active':
        return 'Live';
      case 'completed':
        return 'Done';
      default:
        return status;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'knockout':
        return 'Knockout';
      case 'league':
        return 'League';
      case 'group_knockout':
        return 'Groups';
      default:
        return type;
    }
  }
}

/// Shareable tournament bracket card for social sharing.
class TournamentBracketShareCard extends StatelessWidget {
  final TournamentModel tournament;
  final BracketModel bracket;
  final GlobalKey repaintKey;

  const TournamentBracketShareCard({
    super.key,
    required this.tournament,
    required this.bracket,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 400,
        height: 600,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tournament.format,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeText(tournament.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tournament.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Winner celebration (if complete)
            if (bracket.hasWinner)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.parchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WINNER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          bracket.winnerName ?? 'Champion',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // Bracket summary
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    '${tournament.maxTeams}',
                    'Teams',
                  ),
                  _buildStatColumn(
                    '${bracket.totalMatches}',
                    'Matches',
                  ),
                  _buildStatColumn(
                    '${bracket.completedMatches}',
                    'Played',
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FootHeroes Tournament',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getStatusText(tournament.status),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'knockout':
        return 'Knockout';
      case 'league':
        return 'League';
      case 'group_knockout':
        return 'Groups + Knockout';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'registration':
        return 'Registration Open';
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Tournament Complete';
      default:
        return status;
    }
  }
}

/// Winner celebration card for completed tournaments.
class WinnerCelebrationCard extends StatelessWidget {
  final String winnerName;
  final String tournamentName;
  final GlobalKey? repaintKey;

  const WinnerCelebrationCard({
    super.key,
    required this.winnerName,
    required this.tournamentName,
    this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: 350,
      height: 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.parchment,
            AppTheme.parchment,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          // Winner label
          const Text(
            'CHAMPION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Winner name
          Text(
            winnerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Tournament name
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  tournamentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'FootHeroes Tournament',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (repaintKey != null) {
      return RepaintBoundary(key: repaintKey, child: content);
    }
    return content;
  }
}

/// Tournament creation form card.
class TournamentFormCard extends StatelessWidget {
  final TournamentModel? initialTournament;
  final void Function(TournamentModel tournament) onSubmit;
  final VoidCallback? onCancel;
  final List<String> availableFormats;
  final List<String> availableTypes;

  const TournamentFormCard({
    super.key,
    this.initialTournament,
    required this.onSubmit,
    this.onCancel,
    this.availableFormats = const ['5v5', '7v7', '9v9', '11v11'],
    this.availableTypes = const ['knockout', 'league', 'group_knockout'],
  });

  @override
  Widget build(BuildContext context) {
    // This is just a container - actual form is in the tournament creation screen
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              initialTournament == null ? 'Create Tournament' : 'Edit Tournament',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              initialTournament == null
                  ? 'Set up a new tournament for your teams'
                  : 'Update tournament details',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility for capturing tournament cards as images.
class TournamentCardCapture {
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}