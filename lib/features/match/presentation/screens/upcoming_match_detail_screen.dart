import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../../../../theme/midnight_pitch_theme.dart';
import '../../../../../../../../../../core/router/app_router.dart';
import '../../../../../../../models/match_model.dart';
import '../../../../../../../models/match_roster_model.dart';
import '../../../../../../../providers/match_roster_provider.dart';
import '../../../../../../../providers/auth_provider.dart';
import '../../../../../../../providers/post_match_provider.dart';
import '../../../../../../../widgets/football_pitch_widget.dart';
import '../../../../../../../../widgets/add_player_sheet.dart';

/// Detail screen for an upcoming scheduled match.
/// Shows venue, date/time, roster, and allows starting the match.
///
/// Design enhancements:
/// - Countdown hero with days/hours remaining
/// - Glassmorphic card surfaces with subtle blur
/// - Staggered entrance animations (150-300ms)
/// - Roster strength visual bars
/// - Position-colored player markers (no emoji)
/// - Haptic feedback on key actions
class UpcomingMatchDetailScreen extends ConsumerStatefulWidget {
  final MatchModel match;
  final VoidCallback? onBack;
  final VoidCallback? onStartMatch;

  const UpcomingMatchDetailScreen({
    super.key,
    required this.match,
    this.onBack,
    this.onStartMatch,
  });

  @override
  ConsumerState<UpcomingMatchDetailScreen> createState() => _UpcomingMatchDetailScreenState();
}

class _UpcomingMatchDetailScreenState extends ConsumerState<UpcomingMatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeSlide = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchRosterProvider.notifier).loadRoster(widget.match.matchId);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(matchRosterProvider);
    final match = widget.match;
    final dateStr = _formatDate(match.matchDate);
    final timeStr = _formatTime(match.matchDate);
    final countdown = _getCountdown(match.matchDate);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _buildBackButton(),
        title: Text(
          'MATCH DETAILS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: -0.02,
          ),
        ),
        actions: [_buildShareButton()],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Countdown Hero
              FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_fadeSlide),
                  child: _buildCountdownHero(match, countdown),
                ),
              ),
              const SizedBox(height: 24),
              // Status + Teams
              FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
                  )),
                  child: Column(children: [
                    _buildStatusBadge(match.status),
                    const SizedBox(height: 16),
                    _buildTeams(match),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              // Pitch section
              FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                  )),
                  child: _buildPitchSection(rosterState),
                ),
              ),
              const SizedBox(height: 24),
              // Info section
              FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
                  )),
                  child: _buildInfoSection(dateStr, timeStr, match),
                ),
              ),
              const SizedBox(height: 24),
              // Roster section
              FadeTransition(
                opacity: _fadeSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: _buildRosterSection(rosterState),
                ),
              ),
              if (_isCreator()) ...[
                const SizedBox(height: 16),
                _buildDeleteButton(),
              ],
              const SizedBox(height: 32),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: MidnightPitchTheme.cardShadow,
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: MidnightPitchTheme.electricBlue, size: 18),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        context.go(AppRoutes.home);
      },
    );
  }

  Widget _buildShareButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: MidnightPitchTheme.cardShadow,
        ),
        child: const Icon(Icons.share_outlined, color: MidnightPitchTheme.electricBlue, size: 18),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        // Share functionality placeholder
      },
    );
  }

  Map<String, dynamic> _getCountdown(DateTime matchDate) {
    final now = DateTime.now();
    final diff = matchDate.difference(now);
    if (diff.isNegative) return {'days': 0, 'hours': 0, 'label': 'Match Time'};
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    return {
      'days': days,
      'hours': hours,
      'label': days > 0 ? '$days day${days == 1 ? '' : 's'}' : '$hours hr${hours == 1 ? '' : 's'}',
    };
  }

  Widget _buildCountdownHero(MatchModel match, Map<String, dynamic> countdown) {
    final isToday = _isToday(match.matchDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isToday
              ? [MidnightPitchTheme.championGold, MidnightPitchTheme.amber600]
              : [MidnightPitchTheme.electricBlue, MidnightPitchTheme.indigo800],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isToday ? MidnightPitchTheme.championGold : MidnightPitchTheme.electricBlue)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                isToday ? 'KICK-OFF TODAY' : 'KICK-OFF IN',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (countdown['days'] == 0 && countdown['hours'] == 0)
            Text(
              'NOW',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.headingFontFamily,
                fontSize: 48,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 4,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (countdown['days'] > 0) ...[
                  _buildCountdownUnit(countdown['days'].toString(), 'DAYS'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: TextStyle(fontSize: 36, color: Colors.white54, fontWeight: FontWeight.w300)),
                  ),
                ],
                _buildCountdownUnit(countdown['hours'].toString().padLeft(2, '0'), 'HRS'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: TextStyle(fontSize: 36, color: Colors.white54, fontWeight: FontWeight.w300)),
                ),
                _buildCountdownUnit(
                  (countdown['days'] > 0 ? 0 : (DateTime.now().difference(match.matchDate).inMinutes.abs() % 60))
                      .toString().padLeft(2, '0'),
                  'MIN',
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            _formatDate(match.matchDate),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 44,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = switch (status) {
      'upcoming' => ('UPCOMING', MidnightPitchTheme.championGold),
      'challenge_accepted' => ('CONFIRMED', MidnightPitchTheme.electricBlue),
      'challenge_sent' => ('PENDING', MidnightPitchTheme.championGold),
      _ => (status.toUpperCase(), MidnightPitchTheme.mutedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildTeams(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: MidnightPitchTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: MidnightPitchTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: MidnightPitchTheme.primaryButtonShadow,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  match.homeTeamName.isNotEmpty ? match.homeTeamName : 'Home',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.indigo50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MidnightPitchTheme.indigo200),
                ),
                child: Text(
                  match.format.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: MidnightPitchTheme.electricBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'VS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: MidnightPitchTheme.border, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined, color: MidnightPitchTheme.mutedText, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  match.awayTeamName ?? 'Away',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSection(MatchRosterState rosterState) {
    final homePlayers = rosterState.entries.where((e) => e.team != 'away').toList();
    final awayPlayers = rosterState.entries.where((e) => e.team == 'away').toList();
    final maxPlayers = 11; // Standard squad size for visual ratio

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionPill('LINEUP', MidnightPitchTheme.electricBlue),
            const Spacer(),
            if (homePlayers.isEmpty && awayPlayers.isEmpty)
              _buildSectionPill('NO LINEUPS YET', MidnightPitchTheme.mutedText),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPitchCard(
                homePlayers,
                widget.match.homeTeamName.isNotEmpty
                    ? widget.match.homeTeamName
                    : 'Home',
                true,
                maxPlayers,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'VS',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPitchCard(
                awayPlayers,
                widget.match.awayTeamName ?? 'Away',
                false,
                maxPlayers,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPitchCard(List<MatchRosterEntry> players, String teamName, bool isHome, int maxPlayers) {
    final color = isHome ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText;
    final strength = (players.length / maxPlayers).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showPitchDialog(players, teamName, isHome);
      },
      child: Container(
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                children: [
                  // Team name + strength
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          teamName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.05,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${players.length}',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.headingFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Strength bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            // Mini pitch
            Container(
              height: 100,
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF1B4D1F), const Color(0xFF143D16)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.35,
                    child: CustomPaint(
                      painter: FootballPitchPainter(
                        pitchColor: const Color(0xFF1B4D1F),
                        lineColor: Colors.white,
                        isFlipped: !isHome,
                      ),
                    ),
                  ),
                  if (players.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_add_outlined,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to add',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        '${players.length}',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.headingFontFamily,
                          fontSize: 32,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Tap hint
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fullscreen, size: 12, color: color.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'TAP TO VIEW',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.6),
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPitchDialog(List<MatchRosterEntry> players, String teamName, bool isHome) {
    showDialog(
      context: context,
      builder: (ctx) => _PitchDetailDialog(
        players: players,
        teamName: teamName,
        isHome: isHome,
      ),
    );
  }

  Widget _buildSectionPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String dateStr, String timeStr, MatchModel match) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MidnightPitchTheme.surfaceContainer,
            MidnightPitchTheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: MidnightPitchTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            iconColor: MidnightPitchTheme.championGold,
            label: 'Date',
            value: dateStr,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.access_time,
            iconColor: MidnightPitchTheme.electricBlue,
            label: 'Kick-off',
            value: timeStr,
          ),
          if (match.venue != null && match.venue!.isNotEmpty) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              iconColor: MidnightPitchTheme.rose400,
              label: 'Venue',
              value: match.venue!,
            ),
          ],
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.sports_soccer,
            iconColor: MidnightPitchTheme.emerald500,
            label: 'Format',
            value: match.format.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: MidnightPitchTheme.border.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection(MatchRosterState rosterState) {
    final homePlayers = rosterState.entries.where((e) => e.team != 'away').toList();
    final awayPlayers = rosterState.entries.where((e) => e.team == 'away').toList();
    final isCreator = _isCreator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROSTER',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.15,
              ),
            ),
            if (isCreator)
              _buildAddPlayerButton(),
          ],
        ),
        const SizedBox(height: 16),
        // Home team card
        _buildTeamRosterCard(
          label: 'HOME',
          players: homePlayers,
          accentColor: MidnightPitchTheme.electricBlue,
          canRemove: isCreator,
        ),
        const SizedBox(height: 12),
        // Away team card
        _buildTeamRosterCard(
          label: 'AWAY',
          players: awayPlayers,
          accentColor: MidnightPitchTheme.slate500,
          canRemove: isCreator,
        ),
      ],
    );
  }

  Widget _buildAddPlayerButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _addPlayer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: MidnightPitchTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'ADD',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRosterCard({
    required String label,
    required List<MatchRosterEntry> players,
    required Color accentColor,
    required bool canRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.12), width: 1),
        boxShadow: MidnightPitchTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${players.length} player${players.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
                const Spacer(),
                // Roster strength indicator
                _buildRosterStrengthBadge(players.length, accentColor),
              ],
            ),
          ),
          // Player list
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.group_outlined,
                    color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No players yet',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 13,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: players.map((player) => _buildPlayerRow(player, canRemove, accentColor)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRosterStrengthBadge(int count, Color color) {
    final strength = (count / 11).clamp(0.0, 1.0);
    final label = strength >= 1.0
        ? 'FULL'
        : strength >= 0.7
            ? 'STRONG'
            : strength >= 0.4
                ? 'BUILDING'
                : 'LIMITED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strength >= 0.7
            ? MidnightPitchTheme.success.withValues(alpha: 0.15)
            : strength >= 0.4
                ? MidnightPitchTheme.championGold.withValues(alpha: 0.15)
                : MidnightPitchTheme.liveRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            strength >= 0.7 ? Icons.check_circle : strength >= 0.4 ? Icons.hourglass_top : Icons.warning_amber,
            size: 12,
            color: strength >= 0.7
                ? MidnightPitchTheme.success
                : strength >= 0.4
                    ? MidnightPitchTheme.championGold
                    : MidnightPitchTheme.liveRed,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: strength >= 0.7
                  ? MidnightPitchTheme.success
                  : strength >= 0.4
                      ? MidnightPitchTheme.championGold
                      : MidnightPitchTheme.liveRed,
            ),
          ),
        ],
      ),
    );
  }

  void _addPlayer() async {
    final appwriteService = ref.read(appwriteServiceProvider);
    final player = await showAddPlayerSheet(context, appwriteService);
    if (player == null) return;

    final success = await ref.read(matchRosterProvider.notifier).addPlayer(
      widget.match.matchId,
      player,
      team: player.team,
    );

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${player.name} added to roster' : 'Failed to add player'),
        backgroundColor: success ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.liveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removePlayer(MatchRosterEntry player) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Remove Player?', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: Text(
          'Remove ${player.playerName} from the roster?',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.liveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    final success = await ref.read(matchRosterProvider.notifier).removePlayer(player.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${player.playerName} removed' : 'Failed to remove player'),
        backgroundColor: success ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.liveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPlayerRow(MatchRosterEntry player, bool canRemove, Color accentColor) {
    final positionColor = _getPositionColor(player.position);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MidnightPitchTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar with position color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  positionColor.withValues(alpha: 0.8),
                  positionColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: positionColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: player.isRegistered
                ? const Icon(Icons.verified, size: 18, color: Colors.white)
                : Text(
                    player.playerName.isNotEmpty ? player.playerName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                if (player.playerEmail != null && player.playerEmail!.isNotEmpty)
                  Text(
                    player.playerEmail!,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          // Position badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: positionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular  (6),
              border: Border.all(color: positionColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              player.position.isNotEmpty ? player.position : 'N/A',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: positionColor,
              ),
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removePlayer(player),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.liveRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.remove_circle_outline, size: 18, color: MidnightPitchTheme.liveRed),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    final pos = position.toUpperCase().trim();
    if (pos.contains('GK')) return const Color(0xFFFFB300); // Gold
    if (pos.contains('DEF') || pos.contains('CB') || pos.contains('LB') || pos.contains('RB') || pos.contains('WB'))
      return const Color(0xFF1565C0); // Blue
    if (pos.contains('MID') || pos.contains('CM') || pos.contains('CAM') || pos.contains('CDM') || pos.contains('LM') || pos.contains('RM'))
      return const Color(0xFF2E7D32); // Green
    return const Color(0xFFC62828); // Red (attackers)
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: MidnightPitchTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onStartMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: MidnightPitchTheme.surfaceDim,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 22),
            const SizedBox(width: 8),
            Text(
              'START MATCH',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCreator() {
    final userId = ref.read(authProvider).userId;
    return userId != null && userId == widget.match.createdBy;
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () => _confirmDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.liveRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MidnightPitchTheme.liveRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.liveRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline, color: MidnightPitchTheme.liveRed, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete Match',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.liveRed,
                    ),
                  ),
                  Text(
                    'Permanently remove this match',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MidnightPitchTheme.liveRed),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Delete Match?', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: Text(
          'This will permanently delete ${widget.match.homeTeamName} vs ${widget.match.awayTeamName ?? "Opponent"}. This cannot be undone.',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(postMatchProvider.notifier).deleteMatch(widget.match.matchId);
              if (!mounted) return;
              if (success) {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.maybePop(context);
                }
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to delete match')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.liveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Full-screen dialog showing a football pitch with all players marked by position-colored pins
class _PitchDetailDialog extends StatelessWidget {
  final List<MatchRosterEntry> players;
  final String teamName;
  final bool isHome;

  const _PitchDetailDialog({
    required this.players,
    required this.teamName,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHome ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText;
    final byPos = <String, List<MatchRosterEntry>>{};
    for (final p in players) {
      byPos.putIfAbsent(p.position.trim().toUpperCase(), () => []).add(p);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teamName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${players.length} PLAYERS',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: MidnightPitchTheme.mutedText),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: MidnightPitchTheme.border.withValues(alpha: 0.5)),
            // Pitch body
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Position chips
                    if (players.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: byPos.entries.map((e) {
                          final posColor = _getPositionColor(e.key);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: posColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: posColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: posColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${e.key}: ${e.value.length}',
                                  style: TextStyle(
                                    fontFamily: MidnightPitchTheme.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: posColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Full pitch
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: FootballPitchPainter(
                                  pitchColor: const Color(0xFF1B5E20),
                                  lineColor: Colors.white.withValues(alpha: 0.9),
                                  isFlipped: !isHome,
                                ),
                              ),
                              if (players.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group_add_outlined,
                                        size: 48,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No players in roster',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._buildDialogMarkers(byPos),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Player list
                    if (players.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 110),
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: players.map((p) {
                              final posColor = _getPositionColor(p.position);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: posColor.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _getPositionIcon(p.position),
                                        size: 14,
                                        color: posColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p.playerName,
                                        style: TextStyle(
                                          fontFamily: MidnightPitchTheme.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: MidnightPitchTheme.primaryText,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: posColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.position.isNotEmpty ? p.position : 'N/A',
                                        style: TextStyle(
                                          fontFamily: MidnightPitchTheme.fontFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: posColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPositionIcon(String position) {
    final pos = position.toUpperCase().trim();
    if (pos.contains('GK')) return Icons.person;
    if (pos.contains('DEF') || pos.contains('CB') || pos.contains('LB') || pos.contains('RB'))
      return Icons.shield;
    if (pos.contains('MID') || pos.contains('CM') || pos.contains('CAM') || pos.contains('CDM'))
      return Icons.control_point;
    return Icons.sports_soccer;
  }

  Color _getPositionColor(String position) {
    final pos = position.toUpperCase().trim();
    if (pos.contains('GK')) return const Color(0xFFFFB300);
    if (pos.contains('DEF') || pos.contains('CB') || pos.contains('LB') || pos.contains('RB') ||
        pos.contains('LWB') || pos.contains('RWB'))
      return const Color(0xFF1565C0);
    if (pos.contains('MID') || pos.contains('CM') || pos.contains('CAM') || pos.contains('CDM') ||
        pos.contains('LM') || pos.contains('RM'))
      return const Color(0xFF2E7D32);
    return const Color(0xFFC62828);
  }

  List<Widget> _buildDialogMarkers(Map<String, List<MatchRosterEntry>> byPos) {
    const pitchH = 400.0;
    final markers = <Widget>[];
    var idx = 0;

    for (final entry in byPos.entries) {
      final label = entry.key;
      final group = entry.value;

      for (var i = 0; i < group.length; i++) {
        final player = group[i];
        final pos = _rosterEntryPosition(player);
        final offset = group.length > 1 ? (i - (group.length - 1) / 2) * 0.08 : 0.0;
        final x = (pos[0] + offset).clamp(0.06, 0.94);
        final y = pos[1];

        markers.add(_DialogPinMarker(
          key: ValueKey('dialog_pin_${idx++}_${player.playerId}'),
          player: player,
          x: x * 300,
          y: y * pitchH,
          positionLabel: label,
        ));
      }
    }

    return markers;
  }

  List<double> _rosterEntryPosition(MatchRosterEntry entry) {
    // Returns normalized (x, y) coordinates for pitch placement
    final pos = entry.position.toUpperCase().trim();
    if (pos.contains('GK')) return [0.5, 0.92];
    if (pos.contains('LB') || pos == 'LB' || pos == 'LWB') return [0.15, 0.75];
    if (pos.contains('CB') || pos == 'CB') return [0.5, 0.75];
    if (pos.contains('RB') || pos == 'RB' || pos == 'RWB') return [0.85, 0.75];
    if (pos.contains('CDM') || pos == 'CDM') return [0.5, 0.62];
    if (pos.contains('LM') || pos == 'LM' || pos == 'LWB') return [0.15, 0.50];
    if (pos.contains('CM') || pos == 'CM') return [0.5, 0.50];
    if (pos.contains('RM') || pos == 'RM' || pos == 'RWB') return [0.85, 0.50];
    if (pos.contains('CAM') || pos == 'CAM') return [0.5, 0.38];
    if (pos.contains('LW') || pos == 'LW') return [0.15, 0.25];
    if (pos.contains('RW') || pos == 'RW') return [0.85, 0.25];
    if (pos.contains('ST') || pos.contains('CF') || pos == 'ST') return [0.5, 0.18];
    return [0.5, 0.5];
  }
}

/// Player pin marker for the dialog pitch — position-colored with icon
class _DialogPinMarker extends StatelessWidget {
  final MatchRosterEntry player;
  final double x;
  final double y;
  final String positionLabel;

  const _DialogPinMarker({
    super.key,
    required this.player,
    required this.x,
    required this.y,
    required this.positionLabel,
  });

  Color _getColor() {
    final pos = positionLabel.toUpperCase().trim();
    if (pos.contains('GK')) return const Color(0xFFFFB300);
    if (pos.contains('DEF') || pos.contains('CB') || pos.contains('LB') || pos.contains('RB') ||
        pos.contains('LWB') || pos.contains('RWB'))
      return const Color(0xFF1565C0);
    if (pos.contains('MID') || pos.contains('CM') || pos.contains('CAM') || pos.contains('CDM') ||
        pos.contains('LM') || pos.contains('RM'))
      return const Color(0xFF2E7D32);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Positioned(
      left: x - 36,
      top: y - 44,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 80),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                _shortName(player.playerName),
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Pin icon — high contrast emoji for green pitch visibility
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(2),
              child: Text(
                '📍',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                positionLabel,
                style: const TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts.last.length > 8 ? parts.last.substring(0, 8) : parts.last;
    }
    return name.length > 8 ? name.substring(0, 8) : name;
  }
}