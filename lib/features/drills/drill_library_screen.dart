import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/drill_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../../widgets/premium_app_bar.dart';
import '../../../../widgets/motion_card.dart';

/// Redesigned Drill Library screen using Dark Colour System.
class DrillLibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const DrillLibraryScreen({super.key, this.onBack});

  @override
  ConsumerState<DrillLibraryScreen> createState() => _DrillLibraryScreenState();
}

class _DrillLibraryScreenState extends ConsumerState<DrillLibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _selectedCategory = 0;

  static const _categories = ['All', 'Technical', 'Tactical', 'Fitness', 'Mental'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(drillProvider.notifier).loadAllDrills();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              
              // Header
              SliverToBoxAdapter(child: _buildHeader()),
              
              // Categories
              SliverToBoxAdapter(child: _buildCategoryFilters()),
              
              // Drills
              _buildDrillSliver(),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          Positioned(
            top: 0, left: 0, right: 0,
            child: PremiumAppBar(
              title: 'DRILL LIBRARY',
              scrollOffset: _scrollOffset,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.accentBar(),
              const SizedBox(width: 8),
              Text('TRAIN LIKE A PRO', style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'POSITION-SPECIFIC DRILLS',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  color: isActive ? AppTheme.cardinal : AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive ? null : AppTheme.cardBorder,
                ),
                child: Text(
                  label.toUpperCase(),
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 14,
                    color: isActive ? AppTheme.parchment : AppTheme.gold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDrillSliver() {
    final drillState = ref.watch(drillProvider);
    final hasProAccess = ref.watch(subscriptionProvider).hasProAccess;

    if (drillState.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppTheme.cardinal)),
      );
    }

    final drills = drillState.filteredDrills;

    if (drills.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text('NO DRILLS MATCH YOUR FILTERS', style: AppTheme.labelSmall)),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final drill = drills[index];
            final isLocked = drill.isAdvanced && !hasProAccess;
            return _buildDrillCard(drill, isLocked);
          },
          childCount: drills.length,
        ),
      ),
    );
  }

  Widget _buildDrillCard(dynamic drill, bool isLocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: MotionCard(
          onTap: () {},
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Placeholder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Icon(Icons.sports_soccer_rounded, 
                      size: 64, 
                      color: AppTheme.cardinal.withValues(alpha: 0.1)),
                    if (isLocked)
                      Positioned(
                        top: 16, right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.rose, shape: BoxShape.circle),
                          child: const Icon(Icons.lock_rounded, color: AppTheme.parchment, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(drill.skillLevel.toUpperCase(), 
                          style: AppTheme.labelSmall.copyWith(color: AppTheme.cardinal)),
                        Text('${drill.duration} MIN', 
                          style: AppTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(drill.title.toUpperCase(), 
                      style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(drill.description, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.dmSans.copyWith(fontSize: 13, color: AppTheme.gold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
