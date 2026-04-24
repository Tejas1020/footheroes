import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/team_model.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../widgets/football_pitch_widget.dart';

/// Shareable formation card using Dark Colour System.
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
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: AppTheme.cardBorder,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (team != null) ...[
                    Text(
                      team!.name.toUpperCase(),
                      style: AppTheme.dmSans.copyWith(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    formation.name.toUpperCase(),
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.parchment,
                      fontSize: 32,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    formation.formationType,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.cardinal,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Pitch
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: AppTheme.standardCard,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: FootballPitchWidget(
                    slots: formation.slots,
                    showLabels: true,
                    pitchColor: AppTheme.redDeep,
                    lineColor: AppTheme.parchment.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOOTHEROES',
                        style: AppTheme.bebasDisplay.copyWith(
                          color: AppTheme.cardinal,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Created ${_formatDate(formation.createdAt)}',
                        style: AppTheme.labelSmall,
                      ),
                    ],
                  ),
                  if (formation.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardinal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: AppTheme.dmSans.copyWith(
                          color: AppTheme.cardinal,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
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

/// Shareable lineup card using Dark Colour System.
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
          gradient: AppTheme.cardSurfaceGradient,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: AppTheme.cardBorder,
        ),
        child: Column(
          children: [
            // Match header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'STARTING XI',
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _teamText(teamName, isHome: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'VS',
                          style: AppTheme.bebasDisplay.copyWith(
                            color: AppTheme.gold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _teamText(opponentName, isHome: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lineup.formationType,
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.cardinal,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Pitch
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: AppTheme.standardCard,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: FootballPitchWidget(
                    slots: lineup.startingXI,
                    showLabels: true,
                    pitchColor: AppTheme.redDeep,
                    lineColor: AppTheme.parchment.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            // Captain info
            if (lineup.captainId != null || lineup.viceCaptainId != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (lineup.captainId != null)
                      _buildBadge('C', 'Captain', AppTheme.cardinal),
                    if (lineup.captainId != null && lineup.viceCaptainId != null)
                      const SizedBox(width: 24),
                    if (lineup.viceCaptainId != null)
                      _buildBadge('VC', 'Vice Captain', AppTheme.navy),
                  ],
                ),
              ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOOTHEROES',
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.cardinal,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${lineup.assignedCount}/11 PLAYERS',
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamText(String name, {required bool isHome}) {
    return Expanded(
      child: Text(
        name.toUpperCase(),
        textAlign: isHome ? TextAlign.right : TextAlign.left,
        style: AppTheme.bebasDisplay.copyWith(
          color: AppTheme.parchment,
          fontSize: 20,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBadge(String abbr, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(abbr, style: AppTheme.bebasDisplay.copyWith(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.dmSans.copyWith(fontSize: 12, color: AppTheme.parchment)),
      ],
    );
  }
}

/// Team invite card using Dark Colour System.
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
        height: 520,
        decoration: BoxDecoration(
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: AppTheme.cardBorder,
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'JOIN THE SQUAD',
              style: AppTheme.dmSans.copyWith(
                color: AppTheme.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                team.name.toUpperCase(),
                style: AppTheme.bebasDisplay.copyWith(
                  color: AppTheme.parchment,
                  fontSize: 36,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.parchment,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: inviteLink,
                version: QrVersions.auto,
                size: 180,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.voidBg),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.voidBg),
              ),
            ),
            const SizedBox(height: 40),
            // Invite code
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CODE: ',
                    style: AppTheme.dmSans.copyWith(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    team.inviteCode,
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.cardinal,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOOTHEROES',
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.cardinal,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${team.memberUids.length} MEMBERS',
                    style: AppTheme.labelSmall,
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

/// Digital Player ID card using Dark Colour System.
class PlayerShareCard extends StatelessWidget {
  final String playerName;
  final String position;
  final int goals;
  final int assists;
  final int appearances;
  final double avgRating;
  final int cleanSheets;
  final List<String> recentForm;
  final List<IconData> earnedBadges;
  final GlobalKey? repaintKey;

  const PlayerShareCard({
    super.key,
    required this.playerName,
    required this.position,
    this.goals = 0,
    this.assists = 0,
    this.appearances = 0,
    this.avgRating = 0.0,
    this.cleanSheets = 0,
    this.recentForm = const [],
    this.earnedBadges = const [],
    this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 350,
        height: 580,
        decoration: BoxDecoration(
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardinal.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Glow
            Positioned(
              top: -100, left: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardinal.withValues(alpha: 0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerName.toUpperCase(),
                              style: AppTheme.bebasDisplay.copyWith(
                                fontSize: 32,
                                color: AppTheme.parchment,
                                height: 1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardinal,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    position,
                                    style: AppTheme.bebasDisplay.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.parchment,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ELITE PLAYER',
                                  style: AppTheme.dmSans.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.gold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.cardinal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, size: 28, color: AppTheme.cardinal),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 92,
                          color: AppTheme.cardinal,
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'AVG\nRATING',
                          style: AppTheme.labelSmall.copyWith(height: 1.1),
                        ),
                      ),
                      const Spacer(),
                      if (recentForm.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('RECENT FORM', style: AppTheme.labelSmall.copyWith(fontSize: 8)),
                            const SizedBox(height: 8),
                            Row(
                              children: recentForm.take(5).map((r) {
                                final bg = r == 'W'
                                    ? const Color(0xFF2E7D32)
                                    : r == 'L'
                                        ? AppTheme.cardinal
                                        : const Color(0xFFF9A825);
                                return Container(
                                  width: 24, height: 24,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                                  alignment: Alignment.center,
                                  child: Text(r, style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: r == 'D' ? AppTheme.voidBg : AppTheme.parchment)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Stats Grid
                  _buildHeritageStatsGrid(),

                  const SizedBox(height: 40),

                  // Trophy Case
                  Text('TROPHY CASE', style: AppTheme.labelSmall.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 16),
                  if (earnedBadges.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text(
                        'NO TROPHIES YET',
                        style: AppTheme.labelSmall.copyWith(color: AppTheme.gold.withValues(alpha: 0.4)),
                      ),
                    )
                  else
                    Row(
                      children: earnedBadges.take(5).map((icon) {
                        return Container(
                          width: 48, height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardinal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.2)),
                          ),
                          child: Icon(icon, size: 24, color: AppTheme.cardinal),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FOOTHEROES VERIFIED',
                            style: AppTheme.bebasDisplay.copyWith(
                              fontSize: 16,
                              color: AppTheme.cardinal,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'ID: FH-${playerName.hashCode.toString().substring(0, 4)}',
                            style: AppTheme.labelSmall.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                      const Icon(Icons.qr_code, size: 40, color: AppTheme.gold),
                    ],
                  ),
                ],
              ),
            ),

            // Accent Bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 4,
                decoration: const BoxDecoration(gradient: AppTheme.appBarAccentGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeritageStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.standardCard.copyWith(
        color: AppTheme.elevatedSurface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCol('APPS', appearances.toString()),
          _buildHeritageDivider(),
          _buildStatCol('GOALS', goals.toString()),
          _buildHeritageDivider(),
          _buildStatCol('ASSISTS', assists.toString()),
          if (position == 'GK' || position == 'CB' || position == 'LB' || position == 'RB') ...[
            _buildHeritageDivider(),
            _buildStatCol('CLEAN', cleanSheets.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildHeritageDivider() => Container(width: 1, height: 32, color: AppTheme.dividerColor);

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.bebasDisplay.copyWith(fontSize: 28, color: AppTheme.parchment),
        ),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(fontSize: 8),
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
