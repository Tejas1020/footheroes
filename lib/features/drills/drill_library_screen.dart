import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/drill_provider.dart';
import '../providers/subscription_provider.dart';

/// Drill Library screen — position-specific drills with filter chips,
/// unlocked/locked cards, and bottom nav.
class DrillLibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const DrillLibraryScreen({super.key, this.onBack});

  @override
  ConsumerState<DrillLibraryScreen> createState() => _DrillLibraryScreenState();
}

class _DrillLibraryScreenState extends ConsumerState<DrillLibraryScreen> {
  int _selectedCategory = 0;
  int _selectedType = -1; // -1 = no filter

  static const _categories = ['All', 'Technical', 'Tactical', 'Fitness', 'Mental'];
  static const _types = ['Solo', 'Partner', 'Team', 'No equipment', 'Cones only'];

  @override
  void initState() {
    super.initState();
    // Load drills on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(drillProvider.notifier).loadAllDrills();
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildCategoryFilters(),
                    const SizedBox(height: 16),
                    _buildTypeFilters(),
                    const SizedBox(height: 32),
                    _buildDrillCards(),
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
      color: MidnightPitchTheme.surfaceDim.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: MidnightPitchTheme.primaryText, size: 18),
          ),
          Text(
            'FOOTHEROES',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: MidnightPitchTheme.electricBlue,
              letterSpacing: 4,
            ),
          ),
          IconButton(
            onPressed: () => _showDrillSettings(context),
            icon: const Icon(Icons.settings_outlined),
            color: MidnightPitchTheme.electricBlue,
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // HEADER
  // =============================================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Train like a striker',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Position-specific drills \u00b7 10 available free',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 13,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // FILTER CHIPS
  // =============================================================================

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = index == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = index);
                ref.read(drillProvider.notifier).filterByCategory(label);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.1)
                      : MidnightPitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? Border.all(color: MidnightPitchTheme.electricBlue)
                      : Border.all(color: MidnightPitchTheme.surfaceContainerHigh),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _types.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = index == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedType = isActive ? -1 : index);
                if (isActive) {
                  ref.read(drillProvider.notifier).filterByType(null);
                } else if (index < 3) {
                  // Only Solo, Partner, Team map to soloOrGroup filter
                  ref.read(drillProvider.notifier).filterByType(label);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MidnightPitchTheme.surfaceContainerHigh),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =============================================================================
  // DRILL CARDS
  // =============================================================================

  Widget _buildDrillCards() {
    final drillState = ref.watch(drillProvider);
    final hasProAccess = ref.watch(subscriptionProvider).hasProAccess;

    if (drillState.status == DrillStatus.loading || drillState.status == DrillStatus.initial) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: MidnightPitchTheme.electricBlue),
        ),
      );
    }

    if (drillState.status == DrillStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            drillState.error ?? 'Failed to load drills',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      );
    }

    if (drillState.filteredDrills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'No drills match your filters',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      );
    }

    return Column(
      children: drillState.filteredDrills.asMap().entries.map((entry) {
        final drill = entry.value;
        final isAdvanced = drill.isAdvanced;
        final isLocked = isAdvanced && !hasProAccess;

        Color levelColor;
        IconData icon;
        Color iconColor;
        if (drill.isBeginner) {
          levelColor = MidnightPitchTheme.electricBlue;
          icon = Icons.grid_view_outlined;
          iconColor = MidnightPitchTheme.electricBlue;
        } else if (drill.isIntermediate) {
          levelColor = MidnightPitchTheme.electricBlue;
          icon = Icons.groups;
          iconColor = MidnightPitchTheme.electricBlue;
        } else {
          levelColor = MidnightPitchTheme.championGold;
          icon = isLocked ? Icons.lock : Icons.workspace_premium_outlined;
          iconColor = MidnightPitchTheme.championGold;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: entry.key < drillState.filteredDrills.length - 1 ? 24 : 0),
          child: _buildDrillCard(
            title: drill.title,
            description: drill.description,
            level: drill.skillLevel,
            levelColor: levelColor,
            type: drill.soloOrGroup,
            duration: '${drill.duration} min',
            icon: icon,
            iconColor: iconColor,
            isLocked: isLocked,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrillCard({
    required String title,
    required String description,
    required String level,
    required Color levelColor,
    required String type,
    required String duration,
    required IconData icon,
    required Color iconColor,
    required bool isLocked,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: MidnightPitchTheme.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with level badge
            Stack(
              children: [
                Container(
                  height: 192,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: MidnightPitchTheme.surfaceContainerHigh,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.sports_soccer, size: 48, color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3)),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MidnightPitchTheme.surfaceContainerLow,
                        ],
                      ),
                    ),
                  ),
                ),
                // Level badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                // Locked overlay
                if (isLocked) ...[
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        color: MidnightPitchTheme.surfaceContainerLow.withValues(alpha: 0.4),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.lock, size: 40, color: MidnightPitchTheme.championGold, fill: 1.0),
                    ),
                  ),
                  // Pro badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.championGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'UNLOCK WITH PRO',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: MidnightPitchTheme.surfaceDim,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _buildTag(type),
                          const SizedBox(width: 8),
                          _buildTag(duration),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      color: MidnightPitchTheme.mutedText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isLocked)
                        Row(
                          children: [
                            Text(
                              'LOCKED',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.mutedText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.lock_outline, color: MidnightPitchTheme.mutedText, size: 18),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Text(
                              'Start drill',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.electricBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: MidnightPitchTheme.electricBlue, size: 18),
                          ],
                        ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: MidnightPitchTheme.mutedText,
        ),
      ),
    );
  }

  void _showDrillSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune, color: MidnightPitchTheme.electricBlue),
              title: const Text('Filter Preferences', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter preferences coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: MidnightPitchTheme.mutedText),
              title: const Text('Downloaded Drills', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloaded drills coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: MidnightPitchTheme.mutedText),
              title: const Text('Drill History', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drill history coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

