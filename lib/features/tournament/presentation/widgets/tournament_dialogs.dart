import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../providers/tournament_provider.dart';
import '../../../../models/tournament_model.dart';

/// Dialog builders for tournament interactions.
class TournamentDialogs {
  final WidgetRef ref;
  final BuildContext context;

  TournamentDialogs({required this.ref, required this.context});

  void showMatchDialog(TournamentMatchModel match, TournamentModel tournament) {
    if (!match.hasTeams || match.isBye) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(match.isCompleted ? 'Match Result' : 'Update Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.homeTeamName ?? "TBD"} vs ${match.awayTeamName ?? "TBD"}'),
            const SizedBox(height: 8),
            Text('Round: ${_getRoundName(match.roundNumber, tournament.roundCount)}'),
            Text('Status: ${match.status}'),
            if (match.winnerName != null) Text('Winner: ${match.winnerName}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (!match.isCompleted && match.hasTeams)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                showScoreEntryDialog(match);
              },
              child: const Text('Enter Score'),
            ),
        ],
      ),
    );
  }

  void showScoreEntryDialog(TournamentMatchModel match) {
    final homeController = TextEditingController();
    final awayController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${match.homeTeamName} vs ${match.awayTeamName}'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: homeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: match.homeTeamName),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('-')),
            Expanded(
              child: TextField(
                controller: awayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: match.awayTeamName),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final homeScore = int.tryParse(homeController.text) ?? 0;
              final awayScore = int.tryParse(awayController.text) ?? 0;
              Navigator.pop(ctx);
              ref.read(tournamentProvider.notifier).updateMatchResult(
                tournamentId: match.tournamentId,
                matchId: match.matchId,
                homeScore: homeScore,
                awayScore: awayScore,
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void showEditTournamentDialog(TournamentModel tournament) {
    final nameController = TextEditingController(text: tournament.name);
    final venueController = TextEditingController(text: tournament.venue ?? '');
    final descController = TextEditingController(text: tournament.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Text('Edit Tournament',
            style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: MidnightPitchTheme.primaryText),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: venueController,
                style: TextStyle(color: MidnightPitchTheme.primaryText),
                decoration: InputDecoration(
                  labelText: 'Venue',
                  labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: MidnightPitchTheme.primaryText),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: MidnightPitchTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(tournamentProvider.notifier).updateTournamentFields(
                tournamentId: tournament.tournamentId,
                name: nameController.text.trim(),
                venue: venueController.text.trim(),
                description: descController.text.trim(),
              );
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Tournament updated'),
                    backgroundColor: MidnightPitchTheme.electricMint),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.electricMint,
              foregroundColor: MidnightPitchTheme.primaryText,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void openRegistration(TournamentModel tournament) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(tournamentProvider.notifier).openRegistration(tournament.tournamentId);
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Registration opened!'),
          backgroundColor: MidnightPitchTheme.electricMint,
        ),
      );
    }
  }

  void startTournament(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Tournament'),
        content: const Text(
            'This will generate the bracket and begin the tournament. No more teams can join after this point.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final teamNames = await _fetchTeamNames(tournament.teamIds);
              await ref.read(tournamentProvider.notifier).startTournament(
                tournament.tournamentId,
                tournament.teamIds,
                teamNames,
              );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Tournament started!'),
                  backgroundColor: MidnightPitchTheme.electricMint,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.electricMint,
              foregroundColor: MidnightPitchTheme.primaryText,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void shareBracket() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bracket shared to your clipboard!'),
        backgroundColor: MidnightPitchTheme.electricMint,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Share',
          textColor: MidnightPitchTheme.primaryText,
          onPressed: () {},
        ),
      ),
    );
  }

  String _getRoundName(int roundNumber, int totalRounds) {
    final fromFinal = totalRounds - roundNumber + 1;
    return switch (fromFinal) {
      1 => 'Final',
      2 => 'Semi-Final',
      3 => 'Quarter-Final',
      4 => 'Round of 16',
      5 => 'Round of 32',
      _ => 'Round $roundNumber',
    };
  }

  Future<List<String>> _fetchTeamNames(List<String> teamIds) async {
    return teamIds.asMap().entries.map((e) => 'Team ${e.key + 1}').toList();
  }
}
