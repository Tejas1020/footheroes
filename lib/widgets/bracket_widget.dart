import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/tournament_model.dart';

/// Bracket visualization widget using CustomPainter.
/// Supports knockout tournament brackets with any power-of-2 team count.
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
    final matchHeight = 72.0;
    final matchWidth = 160.0;
    final roundSpacing = 40.0;
    final matchSpacing = 24.0;

    // Height needed to fit all first round matches
    final totalHeight = matchesInFirstRound * (matchHeight + matchSpacing);

    // Width for all rounds
    final totalWidth = totalRounds * matchWidth + (totalRounds - 1) * roundSpacing;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: SizedBox(
          width: totalWidth + 40,
          height: totalHeight + 40,
          child: RepaintBoundary(
            key: captureKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(20),
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
                  // Winner celebration if tournament is complete
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

      // Calculate Y spacing for this round (matches spread out in later rounds)
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
      top: height / 2 - 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade600,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              bracket.winnerName ?? 'Winner',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter that draws the connecting lines between matches.
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
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int roundIndex = 0; roundIndex < rounds.length - 1; roundIndex++) {
      final nextRound = rounds[roundIndex + 1];

      // Calculate Y spacing multipliers
      double currentYMultiplier = 1.0;
      for (int i = 0; i < roundIndex; i++) {
        currentYMultiplier *= 2;
      }

      double nextYMultiplier = currentYMultiplier * 2;

      final currentYSpacing = (matchHeight + matchSpacing) * currentYMultiplier;
      final nextYSpacing = (matchHeight + matchSpacing) * nextYMultiplier;
      final currentYStart = (currentYSpacing - matchHeight - matchSpacing) / 2;
      final nextYStart = (nextYSpacing - matchHeight - matchSpacing) / 2;

      // Draw connections from pairs of matches in current round to their target in next round
      for (int matchIndex = 0; matchIndex < nextRound.matches.length; matchIndex++) {
        // Find the two source matches
        final source1Index = matchIndex * 2;
        final source2Index = matchIndex * 2 + 1;

        final source1Y = currentYStart + source1Index * currentYSpacing + matchHeight / 2;
        final source2Y = currentYStart + source2Index * currentYSpacing + matchHeight / 2;

        final targetX = (roundIndex + 1) * (matchWidth + roundSpacing);
        final targetY = nextYStart + matchIndex * nextYSpacing + matchHeight / 2;

        final sourceX = roundIndex * (matchWidth + roundSpacing) + matchWidth;

        // Draw path from source matches to target match
        final path = Path();
        final midX = sourceX + roundSpacing / 2;

        // From source 1
        path.moveTo(sourceX, source1Y);
        path.lineTo(midX, source1Y);

        // From source 2
        path.moveTo(sourceX, source2Y);
        path.lineTo(midX, source2Y);

        // Vertical line connecting them
        path.moveTo(midX, source1Y);
        path.lineTo(midX, source2Y);

        // Line to target
        path.moveTo(midX, targetY);
        path.lineTo(targetX, targetY);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectionPainter oldDelegate) {
    return rounds != oldDelegate.rounds;
  }
}

/// Individual match card widget.
class _MatchCard extends StatelessWidget {
  final TournamentMatchModel match;
  final bool isSelected;
  final bool isFinal;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.match,
    this.isSelected = false,
    this.isFinal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.isCompleted;
    final isBye = match.isBye;
    final isScheduled = match.isScheduled;
    final hasTeams = match.hasTeams;

    Color cardColor;
    if (isBye) {
      cardColor = Colors.grey.shade200;
    } else if (isCompleted) {
      cardColor = Colors.green.shade50;
    } else if (isScheduled && hasTeams) {
      cardColor = Colors.blue.shade50;
    } else {
      cardColor = Colors.grey.shade100;
    }

    return GestureDetector(
      onTap: hasTeams && !isBye && onTap != null ? onTap : null,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : isFinal
                    ? Colors.amber.shade400
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Home team
            _TeamRow(
              name: match.homeTeamName ?? 'TBD',
              score: match.homeScore,
              isWinner: match.winnerId == match.homeTeamId,
              isBye: isBye && match.homeTeamId != null,
            ),
            const Divider(height: 1),
            // Away team
            _TeamRow(
              name: match.awayTeamName ?? 'TBD',
              score: match.awayScore,
              isWinner: match.winnerId == match.awayTeamId,
              isBye: false,
            ),
            // Status indicator
            if (isBye)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'BYE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Team row within a match card.
class _TeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;
  final bool isBye;

  const _TeamRow({
    required this.name,
    this.score,
    this.isWinner = false,
    this.isBye = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isBye ? Colors.grey.shade600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner ? Colors.green.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.white : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact bracket widget for sharing as an image.
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            tournamentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Winner if complete
          if (bracket.hasWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    bracket.winnerName ?? 'Winner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Compact bracket visualization
          SizedBox(
            height: 200,
            child: TournamentBracketWidget(bracket: bracket),
          ),
          // Footer
          Text(
            'FootHeroes Tournament',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for capturing bracket as an image.
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

/// Wrapper widget for making a bracket capturable.
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

/// Standings table widget for league/group tournaments.
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
    if (standings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No standings available'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withValues(alpha: 0.1)),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('P'), numeric: true),
            DataColumn(label: Text('W'), numeric: true),
            DataColumn(label: Text('D'), numeric: true),
            DataColumn(label: Text('L'), numeric: true),
            DataColumn(label: Text('GF'), numeric: true),
            DataColumn(label: Text('GA'), numeric: true),
            DataColumn(label: Text('GD'), numeric: true),
            DataColumn(label: Text('Pts'), numeric: true),
          ],
          rows: standings.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final isHighlighted = team.teamId == highlightTeamId;

            return DataRow(
              color: WidgetStateProperty.all(
                isHighlighted ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
              ),
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index == 0) const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                      if (index == 0) const SizedBox(width: 4),
                      Text(
                        team.teamName,
                        style: TextStyle(
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text('${team.played}')),
                DataCell(Text('${team.won}')),
                DataCell(Text('${team.drawn}')),
                DataCell(Text('${team.lost}')),
                DataCell(Text('${team.goalsFor}')),
                DataCell(Text('${team.goalsAgainst}')),
                DataCell(
                  Text(
                    '${team.goalDifference >= 0 ? '+' : ''}${team.goalDifference}',
                    style: TextStyle(
                      color: team.goalDifference > 0 ? Colors.green : team.goalDifference < 0 ? Colors.red : null,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${team.points}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Round selector widget for navigating large brackets.
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
      child: Row(
        children: rounds.map((round) {
          final isSelected = round.roundNumber == selectedRound;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(round.roundName),
              selected: isSelected,
              onSelected: (_) => onRoundSelected(round.roundNumber),
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}