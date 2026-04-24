import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/player_stats_provider.dart';
import '../../../providers/player_profile_provider.dart';
import '../../../models/match_model.dart';
import '../../../models/career_stats.dart';
/// Player Profile & Stats screen — Full Visual Upgrade per spec.
class PlayerProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const PlayerProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.name ?? 'Player';
    final initials = _getInitials(userName);
    final matchState = ref.watch(matchProvider);
    final userId = authState.userId;

    final profileAsync = ref.watch(currentUserProfileProvider);
    final position = profileAsync.valueOrNull?.careerStats?.primaryPosition ?? 'CM';

    final statsAsync = userId != null
        ? ref.watch(playerStatsProvider(userId))
        : null;
    final careerStats = statsAsync?.valueOrNull;

    final recentForm = matchState.recentMatches.take(5).map((m) => _getMatchResult(m)).toList();
    final earnedBadges = _getEarnedBadges(careerStats);

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Radial glow background
            Positioned.fill(
              child: Container(decoration: AppTheme.radialGlowOverlay),
            ),
            Column(
              children: [
                _buildTopBar(context, initials),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  children: [
                    // Hero player card
                    _buildHeroCard(userName, position, careerStats, recentForm),
                    const SizedBox(height: 32),

                    // Stats row: Apps / Goals / Assists
                    _buildQuickStats(careerStats),
                    const SizedBox(height: 32),

                    // TROPHY CASE section
                    _buildTrophyCase(earnedBadges),
                    const SizedBox(height: 32),

                    // FOOTHEROES VERIFIED strip
                    _buildVerifiedStrip(userId),
                    const SizedBox(height: 32),

                    // Share button
                    _buildShareButton(),
                    const SizedBox(height: 12),
                    _buildSignOutButton(),
                    const SizedBox(height: 8),
                    _buildDeleteAccountButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context, String initials) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.voidBg,
      ),
      child: Row(
        children: [
          // Avatar circle: GradientC (navy gradient) bg
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppTheme.awayDataGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTheme.bebasDisplay.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'PLAYER PROFILE',
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Settings icon: #800E13, container #2E0012 bg radius 10px
          GestureDetector(
            onTap: _showSettingsSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
                border: AppTheme.cardBorder,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.settings_outlined,
                color: AppTheme.redMid,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO PLAYER CARD
  // ============================================================

  Widget _buildHeroCard(
    String userName,
    String position,
    CareerStats? careerStats,
    List<String> recentForm,
  ) {
    final abilities = _computeAbilities(careerStats);

    return RepaintBoundary(
      key: _shareCardKey,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardSurfaceGradient,
              borderRadius: BorderRadius.circular(16),
              border: AppTheme.cardBorderAlt,
              boxShadow: AppTheme.premiumCardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top accent line
                  Container(height: 2.5, decoration: const BoxDecoration(gradient: AppTheme.appBarAccentGradient)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName.toUpperCase(),
                                    style: AppTheme.bebasDisplay.copyWith(
                                      fontSize: 40,
                                      height: 1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.heroCtaGradient,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          position,
                                          style: AppTheme.bebasDisplay.copyWith(
                                            fontSize: 13,
                                            color: AppTheme.parchment,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'ELITE PLAYER',
                                        style: AppTheme.dmSans.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.gold,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppTheme.heroCtaGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.shieldShadow,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.shield,
                                color: AppTheme.gold,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Rating + Recent Form
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTheme.gradientText(
                                    careerStats?.avgRating.toStringAsFixed(1) ?? '0.0',
                                    AppTheme.bebasDisplay.copyWith(fontSize: 64, height: 1),
                                  ),
                                  Text(
                                    'AVG RATING',
                                    style: AppTheme.dmSans.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.gold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (recentForm.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('RECENT FORM', style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.gold, letterSpacing: 2.0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: recentForm.map((r) {
                                      final bg = r == 'W' ? const Color(0xFF2E7D32) : r == 'L' ? AppTheme.cardinal : const Color(0xFFF9A825);
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 6)]),
                                          alignment: Alignment.center,
                                          child: Text(r, style: AppTheme.bebasDisplay.copyWith(fontSize: 13, color: r == 'D' ? AppTheme.voidBg : AppTheme.parchment)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Ability bars
                        Text('PLAYER ABILITIES', style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.gold, letterSpacing: 2.0)),
                        const SizedBox(height: 12),
                        ...abilities.map((a) => _buildAbilityBar(a.label, a.value, a.color)),
                        const SizedBox(height: 20),
                        // Verified QR strip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroCtaGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: AppTheme.parchment, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'FOOTHEROES VERIFIED',
                                  style: AppTheme.dmSans.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.parchment),
                                ),
                              ),
                              const Icon(Icons.qr_code, color: AppTheme.gold, size: 28),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: AppTheme.radialGlowOverlay,
            ),
          ),
        ],
      ),
    );
  }

  List<({String label, double value, Color color})> _computeAbilities(CareerStats? s) {
    if (s == null || s.appearances == 0) {
      return [
        (label: 'ATTACK', value: 0.3, color: AppTheme.cardinal),
        (label: 'CREATE', value: 0.3, color: AppTheme.cardinal),
        (label: 'DEFEND', value: 0.3, color: AppTheme.navy),
        (label: 'DISCIPLINE', value: 0.7, color: const Color(0xFFF9A825)),
        (label: 'CONSISTENCY', value: 0.3, color: AppTheme.gold),
      ];
    }
    final attack = ((s.goalsPerGame / 1.0).clamp(0.0, 1.0) * 0.5 + (s.avgRating / 10.0) * 0.5).clamp(0.1, 1.0);
    final create = ((s.assistsPerGame / 0.8).clamp(0.0, 1.0) * 0.5 + (s.avgRating / 10.0) * 0.5).clamp(0.1, 1.0);
    final defend = ((s.cleanSheets / s.appearances).clamp(0.0, 1.0) * 0.4 + (s.winRate / 100.0) * 0.6).clamp(0.1, 1.0);
    final discipline = (1.0 - (s.cardsPerGame / 0.5).clamp(0.0, 1.0)).clamp(0.1, 1.0);
    final consistency = (s.winRate / 100.0 * 0.4 + (s.avgRating / 10.0) * 0.6).clamp(0.1, 1.0);
    return [
      (label: 'ATTACK', value: attack, color: AppTheme.cardinal),
      (label: 'CREATE', value: create, color: AppTheme.rose),
      (label: 'DEFEND', value: defend, color: AppTheme.navy),
      (label: 'DISCIPLINE', value: discipline, color: const Color(0xFFF9A825)),
      (label: 'CONSISTENCY', value: consistency, color: AppTheme.gold),
    ];
  }

  Widget _buildAbilityBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedParchment,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${(value * 100).round()}',
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 14,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK STATS ROW
  // ============================================================

  Widget _buildQuickStats(CareerStats? stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: AppTheme.cardBorderLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${stats?.appearances ?? 0}', 'APPS'),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: const Color(0x30C1121F),
          ),
          _buildStatItem('${stats?.goals ?? 0}', 'GOALS'),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: const Color(0x30C1121F),
          ),
          _buildStatItem('${stats?.assists ?? 0}', 'ASSISTS'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 32,
            color: AppTheme.parchment,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TROPHY CASE
  // ============================================================

  Widget _buildTrophyCase(List<IconData> earnedBadges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'TROPHY CASE',
              style: AppTheme.dmSans.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.gold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (earnedBadges.isEmpty)
          Text(
            'Complete milestones to earn trophies',
            style: AppTheme.dmSans.copyWith(
              fontSize: 13,
              color: const Color(0x40F5ECD8),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: earnedBadges.map((icon) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroCtaGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppTheme.parchment, size: 24),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ============================================================
  // VERIFIED STRIP
  // ============================================================

  Widget _buildVerifiedStrip(String? userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppTheme.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOOTHEROES VERIFIED',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.parchment,
                  ),
                ),
                if (userId != null)
                  Text(
                    'ID: ${userId.substring(0, math.min(8, userId.length))}',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 10,
                      color: AppTheme.mutedParchment,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.qr_code,
            color: AppTheme.parchment,
            size: 32,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARE BUTTON
  // ============================================================

  Widget _buildShareButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isSharing ? null : _shareProfile,
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.parchment),
                )
              : const Icon(Icons.share_rounded, size: 18),
          label: Text(_isSharing ? 'GENERATING...' : 'SHARE PLAYER CARD'),
          style: AppTheme.primaryButton,
        ),
      );

  Widget _buildSignOutButton() => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).signOut();
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('SIGN OUT'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.gold,
            side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _buildDeleteAccountButton() => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _showDeleteAccountDialog,
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: const Text('DELETE ACCOUNT'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.cardinal,
            side: BorderSide(color: AppTheme.cardinal.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  List<IconData> _getEarnedBadges(CareerStats? stats) {
    if (stats == null) return [];
    final List<IconData> badges = [];
    if (stats.hatTricks > 0) badges.add(Icons.military_tech);
    if (stats.assists > 10) badges.add(Icons.assistant_rounded);
    if (stats.appearances > 50) badges.add(Icons.bolt_outlined);
    if (stats.goals > 20) badges.add(Icons.emoji_events_outlined);
    if (stats.motmAwards > 0) badges.add(Icons.workspace_premium_outlined);
    return badges;
  }

  String _getMatchResult(MatchModel match) {
    if (match.status != 'completed') return '-';
    if (match.homeScore > match.awayScore) return 'W';
    if (match.homeScore < match.awayScore) return 'L';
    return 'D';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('ACCOUNT SETTINGS',
                  style: AppTheme.labelSmall.copyWith(letterSpacing: 2)),
              const SizedBox(height: 16),
              _settingsItem(Icons.person_outline, 'Edit Profile', () {}),
              _settingsItem(Icons.logout_rounded, 'Logout',
                  () => ref.read(authProvider.notifier).signOut()),
              _settingsItem(Icons.delete_forever_rounded, 'Delete Account',
                  _showDeleteAccountDialog,
                  color: AppTheme.cardinal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap,
          {Color? color}) =>
      ListTile(
        leading: Icon(icon, color: color ?? AppTheme.gold),
        title: Text(label,
            style: AppTheme.bodyBold
                .copyWith(color: color ?? AppTheme.parchment)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.abyss,
        title: Text('Delete Account?',
            style: AppTheme.bebasDisplay
                .copyWith(color: AppTheme.cardinal)),
        content: Text('This action cannot be undone. All stats and history will be lost.',
            style: AppTheme.bodyReg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppTheme.gold))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = ref.read(authProvider).userId;
              if (userId != null) await ref.read(authProvider.notifier).deleteAccount(userId);
            },
            style: AppTheme.primaryButton,
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProfile() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _shareCardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/player_card.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Check out my FootHeroes player card!'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share profile.')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
