import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/tournament_model.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Bracket visualization widget using Dark Colour System.
class TournamentBracketWidget extends StatelessWidget {
  final BracketModel bracket;
  final void Function(TournamentMatchModel match)? onMatchTap;
  final String? selectedMatchId;
  final bool showShareButton;
  final GlobalKey? captureKey;

  const TournamentBracketWidget({
    super.key,
    required this.bracket,
    this.onMatchTap,
    this.selectedMatchId,
    this.showShareButton = false,
    this.captureKey,
  });

  @override
  Widget build(BuildContext context) {
    final totalRounds = bracket.rounds.length;
    final firstRound = bracket.rounds.first;
    final matchesInFirstRound = firstRound.matches.length;

    // Calculate dimensions based on bracket size
    final matchHeight = 84.0;
    final matchWidth = 180.0;
    final roundSpacing = 48.0;
    final matchSpacing = 32.0;

    final totalHeight = matchesInFirstRound * (matchHeight + matchSpacing);
    final totalWidth = totalRounds * matchWidth + (totalRounds - 1) * roundSpacing;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalWidth + 80,
          height: totalHeight + 80,
          child: RepaintBoundary(
            key: captureKey,
            child: Container(
              color: AppTheme.voidBg,
              padding: const EdgeInsets.all(40),
              child: Stack(
                children: [
                  // Draw bracket connections
                  CustomPaint(
                    size: Size(totalWidth, totalHeight),
                    painter: BracketConnectionPainter(
                      rounds: bracket.rounds,
                      matchHeight: matchHeight,
                      matchWidth: matchWidth,
                      roundSpacing: roundSpacing,
                      matchSpacing: matchSpacing,
                    ),
                  ),
                  // Draw match cards
                  ..._buildMatchCards(
                    context: context,
                    totalWidth: totalWidth,
                    matchHeight: matchHeight,
                    matchWidth: matchWidth,
                    roundSpacing: roundSpacing,
                    matchSpacing: matchSpacing,
                  ),
                  // Winner celebration
                  if (bracket.hasWinner)
                    _buildWinnerCelebration(context, totalWidth, totalHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMatchCards({
    required BuildContext context,
    required double totalWidth,
    required double matchHeight,
    required double matchWidth,
    required double roundSpacing,
    required double matchSpacing,
  }) {
    final widgets = <Widget>[];

    for (int roundIndex = 0; roundIndex < bracket.rounds.length; roundIndex++) {
      final round = bracket.rounds[roundIndex];

      double yMultiplier = 1.0;
      for (int i = 0; i < roundIndex; i++) {
        yMultiplier *= 2;
      }

      final ySpacing = (matchHeight + matchSpacing) * yMultiplier;
      final yStart = (ySpacing - matchHeight - matchSpacing) / 2;

      for (int matchIndex = 0; matchIndex < round.matches.length; matchIndex++) {
        final match = round.matches[matchIndex];
        final x = roundIndex * (matchWidth + roundSpacing).toDouble();
        final y = yStart + matchIndex * ySpacing;

        widgets.add(
          Positioned(
            left: x,
            top: y,
            child: _MatchCard(
              match: match,
              isSelected: selectedMatchId == match.matchId,
              onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
              isFinal: roundIndex == bracket.rounds.length - 1,
              width: matchWidth,
              height: matchHeight,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildWinnerCelebration(BuildContext context, double width, double height) {
    return Positioned(
      left: width + 20,
      top: height / 2 - 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.heroCtaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardinal.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppTheme.parchment, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHAMPIONS',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.parchment.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  (bracket.winnerName ?? 'Winner').toUpperCase(),
                  style: AppTheme.bebasDisplay.copyWith(
                    color: AppTheme.parchment,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BracketConnectionPainter extends CustomPainter {
  final List<BracketRound> rounds;
  final double matchHeight;
  final double matchWidth;
  final double roundSpacing;
  final double matchSpacing;

  BracketConnectionPainter({
    required this.rounds,
    required this.matchHeight,
    required this.matchWidth,
    required this.roundSpacing,
    required this.matchSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int roundIndex = 0; roundIndex < rounds.length - 1; roundIndex++) {
      final nextRound = rounds[roundIndex + 1];

      double currentYMultiplier = 1.0;
      for (int i = 0; i < roundIndex; i++) {
        currentYMultiplier *= 2;
      }
      double nextYMultiplier = currentYMultiplier * 2;

      final currentYSpacing = (matchHeight + matchSpacing) * currentYMultiplier;
      final nextYSpacing = (matchHeight + matchSpacing) * nextYMultiplier;
      final currentYStart = (currentYSpacing - matchHeight - matchSpacing) / 2;
      final nextYStart = (nextYSpacing - matchHeight - matchSpacing) / 2;

      for (int matchIndex = 0; matchIndex < nextRound.matches.length; matchIndex++) {
        final source1Index = matchIndex * 2;
        final source2Index = matchIndex * 2 + 1;

        final source1Y = currentYStart + source1Index * currentYSpacing + matchHeight / 2;
        final source2Y = currentYStart + source2Index * currentYSpacing + matchHeight / 2;

        final targetX = (roundIndex + 1) * (matchWidth + roundSpacing);
        final targetY = nextYStart + matchIndex * nextYSpacing + matchHeight / 2;

        final sourceX = roundIndex * (matchWidth + roundSpacing) + matchWidth;

        final path = Path();
        final midX = sourceX + roundSpacing / 2;

        path.moveTo(sourceX, source1Y);
        path.lineTo(midX, source1Y);
        path.moveTo(sourceX, source2Y);
        path.lineTo(midX, source2Y);
        path.moveTo(midX, source1Y);
        path.lineTo(midX, source2Y);
        path.moveTo(midX, targetY);
        path.lineTo(targetX, targetY);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectionPainter oldDelegate) => rounds != oldDelegate.rounds;
}

class _MatchCard extends StatelessWidget {
  final TournamentMatchModel match;
  final bool isSelected;
  final bool isFinal;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const _MatchCard({
    required this.match,
    this.isSelected = false,
    this.isFinal = false,
    this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.isCompleted;
    final isBye = match.isBye;

    return GestureDetector(
      onTap: !isBye && onTap != null ? onTap : null,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.cardinal 
                : isFinal ? AppTheme.rose.withValues(alpha: 0.5) : AppTheme.cardBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.cardinal.withValues(alpha: 0.2), blurRadius: 12)
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              _TeamRow(
                name: match.homeTeamName ?? 'TBD',
                score: match.homeScore,
                isWinner: isCompleted && match.winnerId == match.homeTeamId,
                isHome: true,
              ),
              Container(height: 1, color: AppTheme.cardBorderColor),
              _TeamRow(
                name: match.awayTeamName ?? 'TBD',
                score: match.awayScore,
                isWinner: isCompleted && match.winnerId == match.awayTeamId,
                isHome: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;
  final bool isHome;

  const _TeamRow({
    required this.name,
    this.score,
    required this.isWinner,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = isHome ? AppTheme.cardinal : AppTheme.navy;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: isWinner ? teamColor.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 4, height: 12,
              decoration: BoxDecoration(
                color: isWinner ? teamColor : AppTheme.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 14,
                  color: isWinner ? AppTheme.parchment : AppTheme.gold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (score != null)
              Text(
                score.toString(),
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 18,
                  color: isWinner ? teamColor : AppTheme.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CompactBracketWidget extends StatelessWidget {
  final BracketModel bracket;
  final String tournamentName;

  const CompactBracketWidget({
    super.key,
    required this.bracket,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.voidBg,
        gradient: AppTheme.cardSurfaceGradient,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tournamentName.toUpperCase(),
            style: AppTheme.bebasDisplay.copyWith(
              color: AppTheme.parchment,
              fontSize: 24,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (bracket.hasWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardinal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppTheme.cardinal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    (bracket.winnerName ?? 'Winner').toUpperCase(),
                    style: AppTheme.bebasDisplay.copyWith(
                      color: AppTheme.parchment,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: TournamentBracketWidget(bracket: bracket),
          ),
          const SizedBox(height: 16),
          Text(
            'FOOTHEROES TOURNAMENT',
            style: AppTheme.labelSmall.copyWith(letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class StandingsTableWidget extends StatelessWidget {
  final List<TournamentTeamModel> standings;
  final String? highlightTeamId;

  const StandingsTableWidget({
    super.key,
    required this.standings,
    this.highlightTeamId,
  });

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: AppTheme.standardCard,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.elevatedSurface),
          columnSpacing: 16,
          horizontalMargin: 16,
          headingTextStyle: AppTheme.labelSmall,
          dataTextStyle: AppTheme.dmSans.copyWith(fontSize: 13, color: AppTheme.parchment),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('TEAM')),
            DataColumn(label: Text('P'), numeric: true),
            DataColumn(label: Text('W'), numeric: true),
            DataColumn(label: Text('PTS'), numeric: true),
          ],
          rows: standings.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final isHighlighted = team.teamId == highlightTeamId;

            return DataRow(
              color: WidgetStateProperty.all(isHighlighted ? AppTheme.cardinal.withValues(alpha: 0.1) : null),
              cells: [
                DataCell(Text('${index + 1}', style: AppTheme.bebasDisplay.copyWith(fontSize: 14))),
                DataCell(Text(team.teamName.toUpperCase(), style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: isHighlighted ? AppTheme.cardinal : AppTheme.parchment))),
                DataCell(Text('${team.played}')),
                DataCell(Text('${team.won}')),
                DataCell(Text('${team.points}', style: AppTheme.bodyBold.copyWith(color: AppTheme.cardinal))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class RoundSelectorWidget extends StatelessWidget {
  final List<BracketRound> rounds;
  final int selectedRound;
  final void Function(int roundNumber) onRoundSelected;

  const RoundSelectorWidget({
    super.key,
    required this.rounds,
    required this.selectedRound,
    required this.onRoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: rounds.map((round) {
          final isSelected = round.roundNumber == selectedRound;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(round.roundName.toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onRoundSelected(round.roundNumber),
              backgroundColor: AppTheme.elevatedSurface,
              selectedColor: AppTheme.cardinal,
              labelStyle: AppTheme.bebasDisplay.copyWith(
                fontSize: 12,
                color: isSelected ? AppTheme.parchment : AppTheme.gold,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BracketCaptureKey {
  final GlobalKey key = GlobalKey();

  Future<ui.Image?> captureImage() async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 2.0);
    } catch (_) {
      return null;
    }
  }

  Future<ByteData?> capturePngBytes() async {
    final image = await captureImage();
    if (image == null) return null;
    return await image.toByteData(format: ui.ImageByteFormat.png);
  }
}

class CapturableBracketWidget extends StatelessWidget {
  final Widget child;
  final GlobalKey boundaryKey;

  const CapturableBracketWidget({
    super.key,
    required this.child,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: child,
    );
  }
}