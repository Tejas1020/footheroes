import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../../../../theme/midnight_pitch_theme.dart';
import '../../../../../../../../../../core/router/app_router.dart';
import '../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../providers/match_timer_provider.dart';

class HalfTimeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onStartSecondHalf;
  final VoidCallback? onEndMatch;

  const HalfTimeScreen({
    super.key,
    this.onStartSecondHalf,
    this.onEndMatch,
  });

  @override
  ConsumerState<HalfTimeScreen> createState() => _HalfTimeScreenState();
}

class _HalfTimeScreenState extends ConsumerState<HalfTimeScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(liveMatchProvider);
    final match = matchState.currentMatch;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        title: const Text('HALF TIME'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              context.go('${AppRoutes.match}/live');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Card
              _buildScoreCard(match?.homeScore ?? 0, match?.awayScore ?? 0),
              const SizedBox(height: 32),

              // Events List
              Text(
                '1ST HALF EVENTS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 16),
              _buildEventsList(matchState.events
                  .where((e) => e.minute <= 45)
                  .toList()),
              const SizedBox(height: 32),

              // Coach Notes
              Text(
                'COACH NOTES',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add notes for the team talk...',
                  hintStyle: TextStyle(
                    color: MidnightPitchTheme.mutedText,
                  ),
                  filled: true,
                  fillColor: MidnightPitchTheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButton(
                label: 'START 2ND HALF',
                color: MidnightPitchTheme.electricBlue,
                onTap: widget.onStartSecondHalf ?? () => _startSecondHalf(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'END MATCH',
                color: MidnightPitchTheme.liveRed,
                onTap: widget.onEndMatch ?? () => _showEndMatchDialog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(int homeScore, int awayScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'HALF TIME',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'HOME',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$homeScore',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'AWAY',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$awayScore',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No events recorded',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (context, index) => Divider(
          color: MidnightPitchTheme.surfaceContainerHigh,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventRow(event);
        },
      ),
    );
  }

  Widget _buildEventRow(dynamic event) {
    final minute = event.minute;
    final type = event.type;
    final playerName = event.playerName;

    IconData icon;
    Color color;
    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        color = MidnightPitchTheme.electricBlue;
        break;
      case 'assist':
        icon = Icons.handshake;
        color = MidnightPitchTheme.electricBlue;
        break;
      case 'yellowCard':
        icon = Icons.square;
        color = const Color(0xFFFFEB3B);
        break;
      case 'redCard':
        icon = Icons.square;
        color = MidnightPitchTheme.liveRed;
        break;
      default:
        icon = Icons.circle;
        color = MidnightPitchTheme.mutedText;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            "$minute'",
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              playerName,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: MidnightPitchTheme.surfaceDim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
      ),
    );
  }

  void _startSecondHalf() {
    ref.read(matchTimerProvider.notifier).startSecondHalf();
    Navigator.of(context).pop();
  }

  void _showEndMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Text(
          'End Match?',
          style: TextStyle(color: MidnightPitchTheme.primaryText),
        ),
        content: Text(
          'Are you sure you want to end the match? This cannot be undone.',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: MidnightPitchTheme.mutedText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endMatch();
            },
            child: Text(
              'END MATCH',
              style: TextStyle(color: MidnightPitchTheme.liveRed),
            ),
          ),
        ],
      ),
    );
  }

  void _endMatch() async {
    await ref.read(liveMatchProvider.notifier).endMatch();
    if (mounted) {
      Navigator.of(context).pop(); // Pop half time screen
      Navigator.of(context).pop(); // Pop live match screen
      // Navigate to match summary (handled by parent)
    }
  }
}