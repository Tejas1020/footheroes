import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../models/drill_model.dart';
import '../../../models/challenge_model.dart';
import '../../../providers/learning_hub_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_profile_provider.dart';

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
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildPositionSelector(),
            Expanded(
              child: hubState.status == LearningHubStatus.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.navy),
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
        color: AppTheme.cardinal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.cardinal),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: AppTheme.cardinal))),
          GestureDetector(
            onTap: () => ref.read(learningHubProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppTheme.cardinal, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.voidBg,
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
                      child: const Icon(Icons.arrow_back, color: AppTheme.navy, size: 24),
                    ),
                  Text(
                    'Learning Hub',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.parchment,
                      letterSpacing: -0.44,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.navy.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _selectedPosition,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
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
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: AppTheme.parchment, size: 20),
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
                    ? AppTheme.navy
                    : AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  pos,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.voidBg
                        : AppTheme.gold,
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
        color: AppTheme.cardSurface,
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
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gold,
                  letterSpacing: 0.08,
                ),
              ),
              Text(
                '${state.drillsCompletedThisWeek}/${state.weeklyDrillTarget}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.elevatedSurface,
              valueColor: const AlwaysStoppedAnimation(AppTheme.navy),
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
        color: AppTheme.cardSurface,
        // Removed borderRadius to allow non-uniform border (left only)
        border: const Border(
          left: BorderSide(color: AppTheme.rose, width: 4),
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
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.rose,
                  letterSpacing: 0.1,
                ),
              ),
              Icon(Icons.emoji_events, color: AppTheme.rose, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _completeChallenge(challenge.challengeId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose,
              foregroundColor: AppTheme.voidBg,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.gold),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.3),
              border: Border(bottom: BorderSide(color: AppTheme.gold)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "WEEKLY STANDOUTS",
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.navy,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(Icons.bolt_rounded, color: AppTheme.rose, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
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
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Updated weekly from Premier League data',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gold,
                        ),
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

  Widget _buildPlayerRow(String rank, String name, String goals, bool isHighlighted, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.parchment)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == '1' ? AppTheme.rose.withValues(alpha: 0.1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rank,
              style: TextStyle(
                fontFamily: AppTheme.displayFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: rank == '1' ? AppTheme.rose : AppTheme.gold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: rank == '1' ? FontWeight.w700 : FontWeight.w600,
                color: AppTheme.parchment,
              ),
            ),
          ),
          Text(
            goals,
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'GOALS',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AppTheme.gold,
            ),
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
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.gold,
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
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.sports_soccer,
                color: AppTheme.navy.withValues(alpha: 0.3),
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
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drill.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parchment,
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
                        color: isSaved ? AppTheme.navy : AppTheme.gold,
                        size: 24,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onDrillTap?.call(drill.drillId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: AppTheme.voidBg,
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
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.gold,
                letterSpacing: 0.08,
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToFullDrillLibrary(context),
              child: Text(
                'See all',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_soccer, color: AppTheme.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.parchment,
                  ),
                ),
                Text(
                  '${drill.soloOrGroup} · ${drill.duration} min',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.gold),
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
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.gold,
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
        color: AppTheme.elevatedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedParchment,
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
        backgroundColor: AppTheme.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}