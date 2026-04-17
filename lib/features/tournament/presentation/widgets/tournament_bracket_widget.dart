import 'package:flutter/material.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../models/tournament_model.dart';

/// Tournament bracket section widget — shows bracket rounds and matches.
/// Used inside the Bracket tab of TournamentDetailScreen.
class TournamentBracketSection extends StatelessWidget {
  final TournamentModel tournament;
  final BracketModel? bracket;
  final void Function(TournamentMatchModel match)? onMatchTap;

  const TournamentBracketSection({
    super.key,
    required this.tournament,
    this.bracket,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (bracket == null) {
      return _NoBracketState(tournament: tournament);
    }

    if (bracket!.hasWinner) {
      return _WinnerView(bracket: bracket!, tournament: tournament);
    }

    return _BracketTreeView(
      rounds: bracket!.rounds,
      onMatchTap: onMatchTap,
    );
  }
}

class _NoBracketState extends StatelessWidget {
  final TournamentModel tournament;
  const _NoBracketState({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_outlined, size: 40, color: MidnightPitchTheme.mutedText),
          ),
          const SizedBox(height: 24),
          Text(
            tournament.isDraft
                ? 'Tournament is in draft'
                : tournament.isRegistration
                    ? 'Waiting for teams to register'
                    : 'Bracket not generated yet',
            style: MidnightPitchTheme.bodyMD.copyWith(color: MidnightPitchTheme.primaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${tournament.teamsRegistered}/${tournament.maxTeams} teams registered',
            style: MidnightPitchTheme.labelSM,
          ),
        ],
      ),
    );
  }
}

class _BracketTreeView extends StatelessWidget {
  final List<BracketRound> rounds;
  final void Function(TournamentMatchModel match)? onMatchTap;

  const _BracketTreeView({required this.rounds, this.onMatchTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        final round = rounds[index];
        return _RoundSection(round: round, onMatchTap: onMatchTap);
      },
    );
  }
}

class _RoundSection extends StatelessWidget {
  final BracketRound round;
  final void Function(TournamentMatchModel match)? onMatchTap;

  const _RoundSection({required this.round, this.onMatchTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            round.roundName.toUpperCase(),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.electricMint,
              letterSpacing: 0.1,
            ),
          ),
        ),
        ...round.matches.map((match) => _MatchCard(
          match: match,
          onTap: () => onMatchTap?.call(match),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final TournamentMatchModel match;
  final VoidCallback? onTap;

  const _MatchCard({required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                match.homeTeamName ?? 'TBD',
                style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: MidnightPitchTheme.primaryText),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: MidnightPitchTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Text(
                match.isCompleted ? '${match.homeScore} - ${match.awayScore}' : 'vs',
                style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w800, color: MidnightPitchTheme.primaryText),
              ),
            ),
            Expanded(
              child: Text(
                match.awayTeamName ?? 'TBD',
                style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: MidnightPitchTheme.primaryText),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerView extends StatelessWidget {
  final BracketModel bracket;
  final TournamentModel tournament;

  const _WinnerView({required this.bracket, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _WinnerCelebrationCard(winnerName: bracket.winnerName ?? 'Champion', tournamentName: tournament.name),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: MidnightPitchTheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn('${tournament.maxTeams}', 'Teams'),
                _StatColumn('${bracket.totalMatches}', 'Matches'),
                _StatColumn('${bracket.completedMatches}', 'Played'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerCelebrationCard extends StatelessWidget {
  final String winnerName;
  final String tournamentName;

  const _WinnerCelebrationCard({required this.winnerName, required this.tournamentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MidnightPitchTheme.championGold.withValues(alpha: 0.2), MidnightPitchTheme.surfaceContainer],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 48, color: MidnightPitchTheme.championGold),
          const SizedBox(height: 12),
          Text('CHAMPION', style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 12, fontWeight: FontWeight.w700, color: MidnightPitchTheme.championGold, letterSpacing: 0.2)),
          const SizedBox(height: 8),
          Text(winnerName, style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 24, fontWeight: FontWeight.w900, color: MidnightPitchTheme.primaryText, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(tournamentName, style: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13, color: MidnightPitchTheme.mutedText)),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MidnightPitchTheme.titleMD.copyWith(color: MidnightPitchTheme.electricMint)),
        const SizedBox(height: 4),
        Text(label, style: MidnightPitchTheme.labelSM),
      ],
    );
  }
}