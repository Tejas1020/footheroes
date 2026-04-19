import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/team_model.dart';
import '../theme/midnight_pitch_theme.dart';
import '../widgets/football_pitch_widget.dart';

/// Shareable formation card for team tactics.
class FormationShareCard extends StatelessWidget {
  final FormationModel formation;
  final TeamModel? team;
  final GlobalKey repaintKey;

  const FormationShareCard({
    super.key,
    required this.formation,
    this.team,
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
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (team != null) ...[
                    Text(
                      team!.name,
                      style: const TextStyle(
                        color: MidnightPitchTheme.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    formation.name,
                    style: const TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formation.formationType,
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Pitch with formation
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: (0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FootballPitchWidget(
                    slots: formation.slots,
                    showLabels: true,
                    pitchColor: const Color(0xFF1B5E20),
                    lineColor: Colors.white.withValues(alpha: (0.7)),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FootHeroes',
                        style: TextStyle(
                          color: MidnightPitchTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Created ${_formatDate(formation.createdAt)}',
                        style: TextStyle(
                          color: MidnightPitchTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (formation.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Shareable lineup card for match day.
class LineupShareCard extends StatelessWidget {
  final LineupModel lineup;
  final String teamName;
  final String opponentName;
  final GlobalKey repaintKey;

  const LineupShareCard({
    super.key,
    required this.lineup,
    required this.teamName,
    required this.opponentName,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 400,
        height: 650,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade900,
              Colors.indigo.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Match header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'STARTING XI',
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(
                          color: MidnightPitchTheme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            color: MidnightPitchTheme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        opponentName,
                        style: const TextStyle(
                          color: MidnightPitchTheme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lineup.formationType,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Pitch with lineup
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: (0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FootballPitchWidget(
                    slots: lineup.startingXI,
                    showLabels: true,
                    pitchColor: const Color(0xFF1B5E20),
                    lineColor: Colors.white.withValues(alpha: (0.7)),
                  ),
                ),
              ),
            ),
            // Captain/Vice Captain info
            if (lineup.captainId != null || lineup.viceCaptainId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (lineup.captainId != null)
                      _buildBadge('C', 'Captain', Colors.amber),
                    if (lineup.captainId != null && lineup.viceCaptainId != null)
                      const SizedBox(width: 24),
                    if (lineup.viceCaptainId != null)
                      _buildBadge('VC', 'Vice Captain', Colors.blue.shade300),
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
                    'FootHeroes',
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${lineup.assignedCount}/11 Players',
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
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

  Widget _buildBadge(String abbr, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            abbr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: MidnightPitchTheme.primaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Team invite card with QR code.
class TeamInviteCard extends StatelessWidget {
  final TeamModel team;
  final String inviteLink;
  final GlobalKey repaintKey;

  const TeamInviteCard({
    super.key,
    required this.team,
    required this.inviteLink,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 350,
        height: 500,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade800,
              Colors.teal.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team name
            Text(
              team.name.toUpperCase(),
              style: const TextStyle(
                color: MidnightPitchTheme.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: (0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                team.format,
                style: const TextStyle(
                  color: MidnightPitchTheme.primaryText,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: inviteLink,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to join team',
              style: TextStyle(
                color: MidnightPitchTheme.primaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Invite code
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: (0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Code: ',
                    style: TextStyle(
                      color: MidnightPitchTheme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    team.inviteCode,
                    style: const TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FootHeroes',
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${team.memberUids.length} members',
                    style: TextStyle(
                      color: MidnightPitchTheme.secondaryText,
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
}

/// Shareable player card with stats, position badge, and rating.
class PlayerShareCard extends StatelessWidget {
  final String playerName;
  final String position;
  final int goals;
  final int assists;
  final int appearances;
  final double avgRating;

  const PlayerShareCard({
    super.key,
    required this.playerName,
    required this.position,
    this.goals = 0,
    this.assists = 0,
    this.appearances = 0,
    this.avgRating = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MidnightPitchTheme.surfaceDim,
            MidnightPitchTheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player name
                Text(
                  playerName,
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Position badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    position,
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.surfaceDim,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Overall rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD700),
                        letterSpacing: -3,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'RATING',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.mutedText,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Stats grid
                _buildStatRow(Icons.sports_soccer, 'Goals', goals.toString()),
                const SizedBox(height: 16),
                _buildStatRow(Icons.assistant, 'Assists', assists.toString()),
                const SizedBox(height: 16),
                _buildStatRow(Icons.calendar_today, 'Apps', appearances.toString()),
              ],
            ),
          ),
          // FootHeroes wordmark
          Positioned(
            bottom: 16,
            right: 24,
            child: Text(
              'FootHeroes',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: MidnightPitchTheme.electricBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.secondaryText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
      ],
    );
  }
}

/// Utility class for capturing and sharing card images.
class ShareableCardCapture {
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