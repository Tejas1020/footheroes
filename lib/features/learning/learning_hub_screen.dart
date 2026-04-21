import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../models/drill_model.dart';
import '../models/challenge_model.dart';
import '../providers/learning_hub_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/player_profile_provider.dart';

/// Learning Hub screen — curated content feed with pro stats, drills,
/// tactical breakdowns, and fitness sessions for the player's position.
class LearningHubScreen extends ConsumerStatefulWidget {
  final String? position;
  final VoidCallback? onBack;
  final void Function(String drillId)? onDrillTap;

  const LearningHubScreen({
    super.key,
    this.position,
    this.onBack,
    this.onDrillTap,
  });

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen> {
  String _selectedPosition = 'ST';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePosition();
      _loadData();
    });
  }

  void _initializePosition() {
    // Read user's primary position from their profile
    final profileAsync = ref.read(currentUserProfileProvider);
    final position = profileAsync.valueOrNull?.careerStats?.primaryPosition;
    if (position != null && position.isNotEmpty) {
      _selectedPosition = position;
    } else {
      _selectedPosition = widget.position ?? 'ST';
    }
  }

  void _loadData() {
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(learningHubProvider.notifier).loadContent(_selectedPosition, userId);
    }
  }

  void _changePosition(String position) {
    setState(() => _selectedPosition = position);
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(learningHubProvider.notifier).changePosition(position, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubState = ref.watch(learningHubProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildPositionSelector(),
            Expanded(
              child: hubState.status == LearningHubStatus.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: MidnightPitchTheme.electricBlue),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hubState.error != null)
                            _buildErrorBanner(hubState.error!),
                          _buildWeeklyProgress(hubState),
                          const SizedBox(height: 16),
                          _buildChallengeCard(hubState.currentChallenge),
                          const SizedBox(height: 24),
                          _buildProStatsCard([]),
                          const SizedBox(height: 24),
                          _buildRecommendedDrills(hubState.recommendedDrills),
                          const SizedBox(height: 24),
                          _buildPositionDrills(hubState.positionDrills),
                          const SizedBox(height: 24),
                          _buildSavedDrills(hubState.savedDrillIds, hubState.positionDrills),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.error.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: MidnightPitchTheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: MidnightPitchTheme.error))),
          GestureDetector(
            onTap: () => ref.read(learningHubProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: MidnightPitchTheme.error, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onBack != null)
                    GestureDetector(
                      onTap: () {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          router.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Icon(Icons.arrow_back, color: MidnightPitchTheme.electricBlue, size: 24),
                    ),
                  Text(
                    'Learning Hub',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MidnightPitchTheme.primaryText,
                      letterSpacing: -0.44,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _selectedPosition,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.electricBlue,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Content curated for ${_getPositionName(_selectedPosition).toLowerCase()}s',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: MidnightPitchTheme.primaryText, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSelector() {
    final positions = ['GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final isSelected = pos == _selectedPosition;
          return GestureDetector(
            onTap: () => _changePosition(pos),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? MidnightPitchTheme.electricBlue
                    : MidnightPitchTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  pos,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? MidnightPitchTheme.surfaceDim
                        : MidnightPitchTheme.mutedText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyProgress(LearningHubState state) {
    final progress = state.weeklyProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY PROGRESS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.08,
                ),
              ),
              Text(
                '${state.drillsCompletedThisWeek}/${state.weeklyDrillTarget}',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: MidnightPitchTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(MidnightPitchTheme.electricBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel? challenge) {
    if (challenge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: MidnightPitchTheme.championGold, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEK ${challenge.weekNumber} CHALLENGE',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.championGold,
                  letterSpacing: 0.1,
                ),
              ),
              Icon(Icons.emoji_events, color: MidnightPitchTheme.championGold, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _completeChallenge(challenge.challengeId),
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.championGold,
              foregroundColor: MidnightPitchTheme.surfaceDim,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildProStatsCard(List<dynamic> standouts) {
    // Use placeholder data if no real data
    final players = standouts.take(3).toList().isNotEmpty
        ? standouts.take(3).toList()
        : [
            {'rank': '1', 'name': 'Haaland', 'goals': '4', 'isHighlighted': false},
            {'rank': '2', 'name': 'Salah', 'goals': '3', 'isHighlighted': false},
            {'rank': '3', 'name': 'Watkins', 'goals': '2', 'isHighlighted': false},
          ];

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: MidnightPitchTheme.ambientShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.electricBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "THIS WEEK'S TOP ${_getPositionName(_selectedPosition).toUpperCase()}S",
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MidnightPitchTheme.electricBlue,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const Icon(Icons.query_stats, color: MidnightPitchTheme.electricBlue, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                ...players.asMap().entries.map((entry) {
                  final isLast = entry.key == players.length - 1;
                  final p = entry.value;
                  return _buildPlayerRow(
                    p is Map ? p['rank'] ?? '${entry.key + 1}' : '${entry.key + 1}',
                    p is Map ? p['name'] ?? 'Player' : 'Player',
                    p is Map ? p['goals'] ?? '0' : '0',
                    p is Map ? (p['isHighlighted'] ?? false) : false,
                    isLast,
                  );
                }),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: MidnightPitchTheme.ghostBorder)),
                  ),
                  child: Text(
                    'Updated weekly from Premier League data',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(String rank, String name, String goals, bool isHighlighted, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: !isLast
          ? BoxDecoration(border: Border(bottom: BorderSide(color: MidnightPitchTheme.ghostBorder)))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                rank,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted ? MidnightPitchTheme.electricBlueLight : MidnightPitchTheme.mutedText,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                goals,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'GOALS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedDrills(List<DrillModel> drills) {
    if (drills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED FOR YOU',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: drills.length,
            itemBuilder: (context, index) {
              final drill = drills[index];
              return _buildDrillCard(drill);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrillCard(DrillModel drill) {
    final notifier = ref.read(learningHubProvider.notifier);
    final isSaved = notifier.isDrillSaved(drill.drillId);
    final userId = ref.read(authProvider).userId;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: MidnightPitchTheme.performanceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.sports_soccer,
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.3),
                size: 48,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.electricBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drill.title,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag(drill.soloOrGroup),
                    const SizedBox(width: 8),
                    _buildTag('${drill.duration} min'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (userId != null) {
                          if (isSaved) {
                            notifier.unsaveDrill(drill.drillId, userId);
                          } else {
                            notifier.saveDrill(drill.drillId, userId);
                          }
                        }
                      },
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: isSaved ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText,
                        size: 24,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onDrillTap?.call(drill.drillId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MidnightPitchTheme.electricBlue,
                        foregroundColor: MidnightPitchTheme.surfaceDim,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Start'),
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

  Widget _buildPositionDrills(List<DrillModel> drills) {
    if (drills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ALL $_selectedPosition DRILLS',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.08,
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToFullDrillLibrary(context),
              child: Text(
                'See all',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...drills.take(3).map((drill) => _buildDrillListItem(drill)),
      ],
    );
  }

  Widget _buildDrillListItem(DrillModel drill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_soccer, color: MidnightPitchTheme.electricBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.title,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  '${drill.soloOrGroup} · ${drill.duration} min',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: MidnightPitchTheme.mutedText),
        ],
      ),
    );
  }

  Widget _buildSavedDrills(List<String> savedIds, List<DrillModel> allDrills) {
    final savedDrills = allDrills.where((d) => savedIds.contains(d.drillId)).toList();
    if (savedDrills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAVED DRILLS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 12),
        ...savedDrills.map((drill) => _buildDrillListItem(drill)),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: MidnightPitchTheme.secondaryText,
        ),
      ),
    );
  }

  void _completeChallenge(String challengeId) {
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(learningHubProvider.notifier).completeChallenge(challengeId, userId);
    }
  }

  String _getPositionName(String code) {
    const positions = {
      'GK': 'Goalkeeper',
      'CB': 'Centre Back',
      'LB': 'Left Back',
      'RB': 'Right Back',
      'CDM': 'Defensive Midfielder',
      'CM': 'Central Midfielder',
      'CAM': 'Attacking Midfielder',
      'LW': 'Left Winger',
      'RW': 'Right Winger',
      'ST': 'Striker',
    };
    return positions[code] ?? 'Player';
  }

  void _navigateToFullDrillLibrary(BuildContext context) {
    // Navigate to drill library filtered by position
    if (widget.onDrillTap != null) {
      // If callback provided, use it
      return;
    }
    // Otherwise show a snackbar indicating the feature
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View all $_selectedPosition drills'),
        backgroundColor: MidnightPitchTheme.electricBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}