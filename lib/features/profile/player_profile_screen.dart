import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_stats_provider.dart';
import '../../providers/team_provider.dart';
import '../../core/router/app_router.dart';
import '../../widgets/skeleton_loader.dart';

/// Player Profile Screen - Redesigned with bold card layout
/// Following Vibrant & Block-based style with proper touch targets
class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(child: _buildAppBar(context)),

            // Profile Header
            SliverToBoxAdapter(child: _buildProfileHeader(ref)),

            // Stats Grid
            SliverToBoxAdapter(child: _buildStatsGrid(ref)),

            // Career Section
            SliverToBoxAdapter(child: _buildCareerSection(ref)),

            // Achievements
            SliverToBoxAdapter(child: _buildAchievementsSection(ref)),

            // Settings Menu
            SliverToBoxAdapter(child: _buildSettingsSection(context)),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MidnightPitchTheme.ghostBorder),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back, color: MidnightPitchTheme.primaryText, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'My Profile',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.headingFontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Edit profile
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MidnightPitchTheme.ghostBorder),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.edit_outlined, color: MidnightPitchTheme.primaryText, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.email?.split('@').first ?? 'Player';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final teamState = ref.watch(teamProvider);
    final currentTeam = teamState.currentTeam;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar with gradient
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              gradient: MidnightPitchTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: MidnightPitchTheme.surfaceDim,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Team badge
          if (currentTeam != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, size: 16, color: MidnightPitchTheme.electricBlue),
                  const SizedBox(width: 6),
                  Text(
                    currentTeam.name,
                    style: const TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.electricBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            child: const Text(
              '⚽ Forward',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================

  Widget _buildStatsGrid(WidgetRef ref) {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Statistics'),
          const SizedBox(height: 12),
          statsAsync.when(
            loading: () => const SkeletonCard(height: 200, childCount: 1),
            error: (_, __) => _buildStatsError(),
            data: (stats) {
              if (stats == null) return _buildStatsError();
              return Column(
                children: [
                  // Main stats row
                  Row(
                    children: [
                      Expanded(child: _buildStatTile(
                        value: '${stats.goals}',
                        label: 'Goals',
                        icon: Icons.sports_soccer,
                        color: MidnightPitchTheme.electricBlue,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatTile(
                        value: '${stats.assists}',
                        label: 'Assists',
                        icon: Icons.assistant,
                        color: MidnightPitchTheme.electricBlue,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatTile(
                        value: stats.avgRating.toStringAsFixed(1),
                        label: 'Avg Rating',
                        icon: Icons.star,
                        color: MidnightPitchTheme.championGold,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatTile(
                        value: '${stats.appearances}',
                        label: 'Appearances',
                        icon: Icons.sports_score,
                        color: MidnightPitchTheme.primaryText,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Secondary stats row
                  _buildSecondaryStatsRow(stats),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
        boxShadow: MidnightPitchTheme.ambientShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatsRow(stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('${stats.wins}', 'Wins', MidnightPitchTheme.electricBlue),
          _buildDivider(),
          _buildMiniStat('${stats.draws}', 'Draws', MidnightPitchTheme.championGold),
          _buildDivider(),
          _buildMiniStat('${stats.losses}', 'Losses', MidnightPitchTheme.liveRed),
          _buildDivider(),
          _buildMiniStat('${stats.cleanSheets}', 'Clean Sheets', MidnightPitchTheme.electricBlue),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: MidnightPitchTheme.ghostBorder,
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      child: const Center(
        child: Text(
          'Stats unavailable',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAREER SECTION
  // ============================================================

  Widget _buildCareerSection(WidgetRef ref) {
    final statsAsync = ref.watch(currentUserStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Career'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Unable to load career data'),
              data: (stats) {
                if (stats == null) return const Text('No career data');
                return Column(
                  children: [
                    _buildCareerRow('Win Rate', '${stats.winRate.toStringAsFixed(1)}%'),
                    const SizedBox(height: 12),
                    _buildCareerRow('Goals per Game', stats.appearances > 0
                        ? (stats.goals / stats.appearances).toStringAsFixed(2)
                        : '0.00'),
                    const SizedBox(height: 12),
                    _buildCareerRow('Total Goals', '${stats.goals}'),
                    const SizedBox(height: 12),
                    _buildCareerRow('Total Assists', '${stats.assists}'),
                    const SizedBox(height: 12),
                    _buildCareerRow('Best Position', stats.primaryPosition.isNotEmpty
                        ? stats.primaryPosition
                        : 'Forward'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.secondaryText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACHIEVEMENTS SECTION
  // ============================================================

  Widget _buildAchievementsSection(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MidnightPitchTheme.sectionLabel('Achievements'),
              Text(
                '3 / 12 unlocked',
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAchievementBadge(
                  icon: Icons.emoji_events,
                  label: 'First Goal',
                  color: MidnightPitchTheme.championGold,
                  isLocked: false,
                ),
                const SizedBox(width: 12),
                _buildAchievementBadge(
                  icon: Icons.star,
                  label: 'Hat-trick',
                  color: MidnightPitchTheme.electricBlue,
                  isLocked: false,
                ),
                const SizedBox(width: 12),
                _buildAchievementBadge(
                  icon: Icons.workspace_premium,
                  label: 'MVP Season',
                  color: MidnightPitchTheme.electricBlue,
                  isLocked: false,
                ),
                const SizedBox(width: 12),
                _buildAchievementBadge(
                  icon: Icons.lock,
                  label: '50 Goals',
                  color: MidnightPitchTheme.mutedText,
                  isLocked: true,
                ),
                const SizedBox(width: 12),
                _buildAchievementBadge(
                  icon: Icons.lock,
                  label: '100 Games',
                  color: MidnightPitchTheme.mutedText,
                  isLocked: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLocked,
  }) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: isLocked ? 0.2 : 0.4)),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLocked ? MidnightPitchTheme.mutedText : MidnightPitchTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETTINGS SECTION
  // ============================================================

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('Settings'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _buildDivider2(),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildDivider2(),
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy',
                  onTap: () {},
                ),
                _buildDivider2(),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _buildDivider2(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {},
                ),
                _buildDivider2(),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  color: MidnightPitchTheme.liveRed,
                  onTap: () {
                    // TODO: Sign out
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? MidnightPitchTheme.electricBlue).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: color ?? MidnightPitchTheme.electricBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color ?? MidnightPitchTheme.primaryText,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: MidnightPitchTheme.mutedText,
        size: 24,
      ),
    );
  }

  Widget _buildDivider2() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: MidnightPitchTheme.ghostBorder, height: 1),
    );
  }
}
