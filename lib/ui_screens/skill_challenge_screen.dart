import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';

/// Skill Challenge screen — weekly challenge with progress ring,
/// badge preview, and leaderboard.
class SkillChallengeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const SkillChallengeScreen({super.key, this.onBack});

  @override
  ConsumerState<SkillChallengeScreen> createState() => _SkillChallengeScreenState();
}

class _SkillChallengeScreenState extends ConsumerState<SkillChallengeScreen> {
  @override
  void initState() {
    super.initState();
    // Load current challenge on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengeProvider.notifier).loadCurrentChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 32),
                    _buildProgressSection(),
                    const SizedBox(height: 32),
                    _buildBadgePreview(),
                    const SizedBox(height: 32),
                    _buildLeaderboard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // TOP BAR
  // =============================================================================

  Widget _buildTopBar() {
    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(Icons.arrow_back, color: MidnightPitchTheme.electricMint, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Skill Challenge',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                  letterSpacing: -0.44,
                ),
              ),
            ],
          ),
          const Icon(Icons.military_tech, color: MidnightPitchTheme.electricMint, size: 24),
        ],
      ),
    );
  }

  // =============================================================================
  // HERO SECTION
  // =============================================================================

  Widget _buildHeroSection() {
    final challengeState = ref.watch(challengeProvider);
    final challenge = challengeState.currentChallenge;

    if (challengeState.status == ChallengeStatus.loading || challengeState.status == ChallengeStatus.initial) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.35)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: MidnightPitchTheme.championGold),
          ),
        ),
      );
    }

    if (challengeState.status == ChallengeStatus.error || challenge == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            challengeState.error ?? 'No active challenge found',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      );
    }

    final userId = ref.watch(authProvider).userId;
    final isCompleted = userId != null && challenge.isCompletedBy(userId);
    final daysLeft = challenge.expiresAt.difference(DateTime.now()).inDays;
    final timeLeftText = challenge.isExpired
        ? 'Challenge expired'
        : daysLeft > 0
            ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left'
            : 'Ends today';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MidnightPitchTheme.championGold.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          // Glow effect
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MidnightPitchTheme.championGold.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.transparent, BlendMode.dstOver),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEK ${challenge.weekNumber} \u00B7 ${challenge.position.toUpperCase()} CHALLENGE',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: MidnightPitchTheme.championGold,
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isCompleted
                      ? 'Challenge completed! Great work on this week\'s goal.'
                      : 'Complete this challenge to earn your badge and climb the leaderboard.',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    color: const Color(0xFFA0B4C8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      color: isCompleted ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted ? 'Completed' : timeLeftText,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isCompleted ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // PROGRESS SECTION
  // =============================================================================

  Widget _buildProgressSection() {
    final challengeState = ref.watch(challengeProvider);
    final authState = ref.watch(authProvider);
    final challenge = challengeState.currentChallenge;
    final userId = authState.userId;

    if (challenge == null) {
      return const SizedBox.shrink();
    }

    final isCompleted = userId != null && challenge.isCompletedBy(userId);

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: isCompleted ? 1.0 : 0.0),
            child: Center(
              child: Icon(
                isCompleted ? Icons.check : Icons.emoji_events_outlined,
                color: isCompleted ? MidnightPitchTheme.electricMint : MidnightPitchTheme.championGold,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isCompleted ? 'Challenge completed!' : 'Complete to earn your badge',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCompleted ? MidnightPitchTheme.electricMint : MidnightPitchTheme.mutedText,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 280,
          height: 52,
          child: ElevatedButton(
            onPressed: isCompleted || userId == null
                ? null
                : () async {
                    await ref.read(challengeProvider.notifier).markCompleted(challenge.id, userId);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.electricMint,
              foregroundColor: MidnightPitchTheme.surfaceDim,
              disabledBackgroundColor: MidnightPitchTheme.surfaceContainerHigh,
              disabledForegroundColor: MidnightPitchTheme.mutedText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isCompleted ? Icons.check : Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Completed' : 'Mark as completed',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // BADGE PREVIEW
  // =============================================================================

  Widget _buildBadgePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('COMPLETE TO EARN'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141E2C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E2A3A)),
          ),
          child: Row(
            children: [
              // Badge circle with lock overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MidnightPitchTheme.championGold,
                          const Color(0xFFFFDF9B),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MidnightPitchTheme.championGold.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.workspace_premium, color: Color(0xFF5C4400), size: 40),
                  ),
                  // Lock overlay
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.surfaceDim.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock, color: MidnightPitchTheme.primaryText, size: 24),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weak Foot Wonder',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scored 3 with non-dominant foot',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MidnightPitchTheme.mutedText,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // LEADERBOARD
  // =============================================================================

  Widget _buildLeaderboard() {
    const players = [
      _LeaderboardPlayer('You', '1/3', isCurrentUser: true, isCompleted: false),
      _LeaderboardPlayer('Sarah M.', '3/3', isCurrentUser: false, isCompleted: true),
      _LeaderboardPlayer('David K.', '3/3', isCurrentUser: false, isCompleted: true),
      _LeaderboardPlayer('Leo R.', '2/3', isCurrentUser: false, isCompleted: false),
      _LeaderboardPlayer('Elena G.', '2/3', isCurrentUser: false, isCompleted: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel("THIS WEEK'S HEROES"),
        const SizedBox(height: 16),
        ...players.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLeaderboardRow(p),
            )),
      ],
    );
  }

  Widget _buildLeaderboardRow(_LeaderboardPlayer player) {
    if (player.isCurrentUser) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border(
            left: BorderSide(color: MidnightPitchTheme.electricMint, width: 4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: MidnightPitchTheme.electricMint, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'YO',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  player.name,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
              ],
            ),
            Text(
              player.score,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.electricMint,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  player.name.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                player.name,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
            ],
          ),
          if (player.isCompleted)
            Row(
              children: [
                Text(
                  player.score,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.electricMint,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, color: MidnightPitchTheme.electricMint, size: 16),
              ],
            )
          else
            Text(
              player.score,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
        ],
      ),
    );
  }

}

// =============================================================================
// PROGRESS RING PAINTER
// =============================================================================

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E2A3A)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = MidnightPitchTheme.championGold
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) => progress != oldDelegate.progress;
}

// =============================================================================
// HELPERS
// =============================================================================

class _LeaderboardPlayer {
  final String name;
  final String score;
  final bool isCurrentUser;
  final bool isCompleted;

  const _LeaderboardPlayer(this.name, this.score, {this.isCurrentUser = false, this.isCompleted = false});
}

