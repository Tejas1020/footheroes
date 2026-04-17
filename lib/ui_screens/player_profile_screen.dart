import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../providers/player_stats_provider.dart';
import '../providers/player_profile_provider.dart';
import '../models/match_model.dart';
import '../models/career_stats.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shareable_cards.dart';
import '../widgets/skeleton_loader.dart';

/// Player Profile & Stats screen — the digital identity card for every player.
///
/// Shows career record, position-specific stats, recent form,
/// and earned badges. Profile can be shared externally.
class PlayerProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const PlayerProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;
  CareerStats? careerStats;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.name ?? 'Player';
    final initials = _getInitials(userName);
    final matchState = ref.watch(matchProvider);
    final userId = authState.userId;

    final profileAsync = ref.watch(currentUserProfileProvider);
    final position = profileAsync.valueOrNull?.careerStats?.primaryPosition ?? 'ST';

    final statsAsync = userId != null
        ? ref.watch(playerStatsProvider(userId))
        : null;
    careerStats = statsAsync?.valueOrNull;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, initials),
              const SizedBox(height: 16),
              _buildProfileHero(context, initials, userName, position),
              const SizedBox(height: 32),
              _buildCareerStats(),
              const SizedBox(height: 32),
              _buildRecentForm(ref, matchState.recentMatches),
              const SizedBox(height: 32),
              _buildPositionStats(position),
              const SizedBox(height: 32),
              _buildBadges(),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  String _formatMatchDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // =============================================================================
  // TOP BAR
  // =============================================================================

  Widget _buildTopBar(BuildContext context, String initials) {
    return Container(
      height: 64,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
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
                'PLAYER ELITE',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.primaryText,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _isSharing ? null : _shareProfile,
                icon: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MidnightPitchTheme.electricMint,
                        ),
                      )
                    : const Icon(Icons.share, size: 20),
                color: MidnightPitchTheme.mutedText,
                iconSize: 24,
              ),
              IconButton(
                onPressed: _showSettingsSheet,
                icon: const Icon(Icons.settings, size: 20),
                color: MidnightPitchTheme.mutedText,
                iconSize: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 48, height: 4,
              decoration: BoxDecoration(color: MidnightPitchTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text('SETTINGS', style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily, fontSize: 16,
              fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText,
            )),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.person_outline, color: MidnightPitchTheme.mutedText),
              title: Text('Edit Profile', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              trailing: Icon(Icons.chevron_right, color: MidnightPitchTheme.mutedText),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_outline, color: MidnightPitchTheme.mutedText),
              title: Text('Privacy', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              trailing: Icon(Icons.chevron_right, color: MidnightPitchTheme.mutedText),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon')),
                );
              },
            ),
            const Divider(color: MidnightPitchTheme.surfaceContainerHigh),
            ListTile(
              leading: Icon(Icons.delete_forever, color: MidnightPitchTheme.liveRed),
              title: Text('Delete Account', style: TextStyle(color: MidnightPitchTheme.liveRed)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAccountDialog();
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Text('Delete your account?', style: TextStyle(color: MidnightPitchTheme.liveRed)),
        content: const Text(
          'This permanently deletes your profile, stats, and match history. This cannot be undone.',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: MidnightPitchTheme.mutedText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                await ref.read(authProvider.notifier).deleteAccount(userId);
              }
            },
            child: Text('Delete permanently', style: TextStyle(color: MidnightPitchTheme.liveRed)),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // PROFILE HERO
  // =============================================================================

  Widget _buildProfileHero(BuildContext context, String initials, String userName, String position) {
    return RepaintBoundary(
      key: _shareCardKey,
      child: PlayerShareCard(
        playerName: userName,
        position: position,
        goals: careerStats?.goals ?? 0,
        assists: careerStats?.assists ?? 0,
        appearances: careerStats?.appearances ?? 0,
        avgRating: careerStats?.avgRating ?? 0.0,
      ),
    );
  }

  // =============================================================================
  // CAREER STATS — Horizontal Scroll
  // =============================================================================

  Widget _buildCareerStats() {
    final stats = careerStats;

    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MidnightPitchTheme.sectionLabel('CAREER STATS'),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (_) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SkeletonLoader(height: 24, width: 60),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final winRate = stats.appearances > 0
        ? '${(stats.wins / stats.appearances * 100).toStringAsFixed(0)}%'
        : '0%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('CAREER STATS'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(_StatItem(stats.appearances.toString(), 'Apps')),
                const SizedBox(width: 16),
                _buildStatCard(_StatItem(stats.goals.toString(), 'Goals')),
                const SizedBox(width: 16),
                _buildStatCard(_StatItem(stats.assists.toString(), 'Assists')),
                const SizedBox(width: 16),
                _buildStatCard(_StatItem(winRate, 'Win rate')),
                const SizedBox(width: 16),
                _buildStatCard(_StatItem(stats.avgRating.toStringAsFixed(1), 'Avg rating')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MidnightPitchTheme.primaryText,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label.toUpperCase(),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // RECENT FORM
  // =============================================================================

  Widget _buildRecentForm(WidgetRef ref, List<MatchModel> recentMatches) {
    if (recentMatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MidnightPitchTheme.sectionLabel('RECENT FORM'),
            const SizedBox(height: 16),
            const EmptyStateWidget(
              icon: Icons.sports_soccer_outlined,
              title: 'No Matches Yet',
              subtitle: 'Play matches to see your recent form',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('RECENT FORM'),
          const SizedBox(height: 16),
          Row(
            children: recentMatches.take(5).map((match) {
              final result = _getMatchResult(match);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildResultBadge(result),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildHighlightedMatch(ref, recentMatches.first),
        ],
      ),
    );
  }

  String _getMatchResult(MatchModel match) {
    if (match.status != 'completed') return '-';
    if (match.homeScore > match.awayScore) return 'W';
    if (match.homeScore < match.awayScore) return 'L';
    return 'D';
  }

  Widget _buildResultBadge(String result) {
    Color color;
    switch (result) {
      case 'W':
        color = MidnightPitchTheme.electricMint;
        break;
      case 'D':
        color = MidnightPitchTheme.surfaceContainerHighest;
        break;
      case 'L':
        color = MidnightPitchTheme.liveRed;
        break;
      default:
        color = MidnightPitchTheme.mutedText;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        result,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: result == 'D' || result == '-'
              ? MidnightPitchTheme.primaryText
              : MidnightPitchTheme.surfaceDim,
        ),
      ),
    );
  }

  Widget _buildHighlightedMatch(WidgetRef ref, MatchModel match) {
    final result = _getMatchResult(match);
    final ourScore = match.homeScore;
    final theirScore = match.awayScore;

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MidnightPitchTheme.ghostBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Match',
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                      TextSpan(
                        text: '$ourScore-$theirScore ${result == 'W' ? 'W' : result == 'L' ? 'L' : 'D'}',
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMatchDate(match.matchDate),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                careerStats?.avgRating.toStringAsFixed(1) ?? '0.0',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.championGold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'RATING',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // POSITION STATS — Simple text rows
  // =============================================================================

  Widget _buildPositionStats(String position) {
    final stats = careerStats;

    String label;
    List<Widget> statRows;

    if (position == 'GK') {
      label = 'GOALKEEPER STATS';
      statRows = [
        _buildStatRow('Clean sheets', '${stats?.cleanSheets ?? 0}'),
        _buildStatRow('Save percentage', '0%'),
      ];
    } else if (position == 'CB' || position == 'LB' || position == 'RB') {
      label = 'DEFENDER STATS';
      statRows = [
        _buildStatRow('Clean sheets', '${stats?.cleanSheets ?? 0}'),
        _buildStatRow('Tackles', '0'),
      ];
    } else if (position == 'CDM' || position == 'CM' || position == 'CAM' || position == 'LM' || position == 'RM') {
      label = 'MIDFIELDER STATS';
      statRows = [
        _buildStatRow('Key passes', '0'),
        _buildStatRow('Assists', '${stats?.assists ?? 0}'),
      ];
    } else {
      label = 'STRIKER STATS';
      statRows = [
        _buildStatRow('Goals', '${stats?.goals ?? 0}'),
        _buildStatRow('Shots on target', '0'),
        _buildStatRow('Conversion rate', '0%'),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel(label),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: statRows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // BADGES — Horizontal Scroll
  // =============================================================================

  Widget _buildBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidnightPitchTheme.sectionLabel('BADGES'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEarnedBadge(Icons.military_tech, 'Hat-trick Hero'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.workspace_premium_outlined, 'Assist King'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.bolt_outlined, '50 Club'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.emoji_events_outlined, 'Golden Boot'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.shield_moon_outlined, 'The Wall'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.auto_awesome, 'Playmaker'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.star_outline, 'Unbeaten'),
                const SizedBox(width: 16),
                _buildLockedBadge(Icons.cleaning_services_outlined, 'Clean Sheet King'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.championGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: MidnightPitchTheme.championGold, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: MidnightPitchTheme.championGold, fill: 1.0),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.championGold,
              letterSpacing: -0.02,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: MidnightPitchTheme.ghostBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: MidnightPitchTheme.mutedText),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: -0.02,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // SHARE PROFILE
  // =============================================================================

  Future<void> _shareProfile() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _shareCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/footheroes_card.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Check out my stats on FootHeroes! footheroes.com',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate card. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
} // End of PlayerProfileScreen

// =============================================================================
// Helpers
// =============================================================================

class _StatItem {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);
}