import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../providers/squad_provider.dart';
import '../repositories/team_repository.dart' show TeamMember;
import '../models/team_model.dart';
import '../models/session_plan_model.dart';

/// Squad Management screen — team hub with quick actions, next match,
/// payment split, and squad overview.
class SquadManagementScreen extends ConsumerStatefulWidget {
  final String? teamId;
  final VoidCallback? onBack;
  final void Function(String matchId)? onNavigateToLineup;
  final void Function(String drillId)? onNavigateToDrills;

  const SquadManagementScreen({
    super.key,
    this.teamId,
    this.onBack,
    this.onNavigateToLineup,
    this.onNavigateToDrills,
  });

  @override
  ConsumerState<SquadManagementScreen> createState() => _SquadManagementScreenState();
}

class _SquadManagementScreenState extends ConsumerState<SquadManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(teamProvider.notifier).loadUserTeams(userId).then((_) {
        final team = ref.read(teamProvider).currentTeam;
        if (team != null) {
          ref.read(squadProvider.notifier).loadSquad(team.teamId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final squadState = ref.watch(squadProvider);
    final isLoading = teamState.status == TeamStatus.loading || squadState.status == SquadStatus.loading;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(teamState.currentTeam),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: MidnightPitchTheme.electricMint),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (squadState.error != null)
                            _buildErrorBanner(squadState.error!),
                          _buildQuickActions(teamState.currentTeam),
                          const SizedBox(height: 32),
                          _buildNextMatch(squadState.nextMatch, squadState.rsvpStatus),
                          const SizedBox(height: 32),
                          _buildPaymentSplit(teamState.currentTeam, squadState),
                          const SizedBox(height: 32),
                          _buildUpcomingSessions(squadState.upcomingSessions),
                          const SizedBox(height: 32),
                          _buildSquadOverview(squadState),
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
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
          GestureDetector(
            onTap: () => ref.read(squadProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: Colors.red, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(TeamModel? team) {
    final teamName = team?.name ?? 'FC United';
    final formatLabel = team?.format.toUpperCase() ?? '11-A-SIDE';

    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: MidnightPitchTheme.electricMint),
                ),
              const Icon(Icons.groups, color: MidnightPitchTheme.electricMint, size: 24),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    teamName,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MidnightPitchTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      formatLabel,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MidnightPitchTheme.mutedText,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showTeamSettings(context),
                icon: const Icon(Icons.settings_outlined),
                color: MidnightPitchTheme.mutedText,
                iconSize: 22,
              ),
              GestureDetector(
                onTap: () => _showInviteDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricMint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'INVITE',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.surfaceDim,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(TeamModel? team) {
    final squadState = ref.watch(squadProvider);
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            Icons.auto_awesome,
            'Lineup',
            MidnightPitchTheme.skyBlue,
            () {
              if (team != null && squadState.nextMatch != null) {
                widget.onNavigateToLineup?.call(squadState.nextMatch!.matchId);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            Icons.scoreboard,
            'Result',
            MidnightPitchTheme.championGold,
            () => _showResultEntry(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            Icons.forum_outlined,
            'Chat',
            MidnightPitchTheme.electricMint,
            () => _showTeamChat(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color iconColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
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
    );
  }

  Widget _buildNextMatch(dynamic nextMatch, Map<String, String> rsvpStatus) {
    final confirmed = rsvpStatus.values.where((v) => v == 'yes').length;
    final maybe = rsvpStatus.values.where((v) => v == 'maybe').length;
    final out = rsvpStatus.values.where((v) => v == 'no').length;

    String dateStr = 'No upcoming match';
    String locationStr = 'TBD';
    String daysUntilStr = '';

    // For now, use placeholder data
    // In production, nextMatch would come from squadState.nextMatch
    dateStr = 'Sat 26 Apr · 10:00am';
    daysUntilStr = 'IN 5 DAYS';
    locationStr = 'Tottenham Marshes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MidnightPitchTheme.sectionLabel('Next match'),
            if (daysUntilStr.isNotEmpty)
              Text(
                daysUntilStr,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricMint,
                  letterSpacing: 0.15,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Icon(
                  Icons.sports_soccer,
                  size: 120,
                  color: MidnightPitchTheme.primaryText.withValues(alpha: 0.1),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.skyBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: MidnightPitchTheme.mutedText, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        locationStr,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          color: MidnightPitchTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildRsvpChip(MidnightPitchTheme.electricMint, '$confirmed GOING'),
                      _buildRsvpChip(MidnightPitchTheme.championGold, '$maybe MAYBE'),
                      _buildRsvpChip(MidnightPitchTheme.liveRed, '$out OUT'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _sendMatchReminder(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MidnightPitchTheme.surfaceContainerHigh,
                        foregroundColor: MidnightPitchTheme.electricMintLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'SEND REMINDER',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSplit(TeamModel? team, SquadState squadState) {
    final paidCount = squadState.paidCount;
    final memberCount = squadState.rosterCount;
    final totalAmount = 70.0;
    final perPlayer = memberCount > 0 ? totalAmount / memberCount : 5.0;
    final collected = perPlayer * paidCount;
    final progress = memberCount > 0 ? paidCount / memberCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Match fee'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\u00a3${perPlayer.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: MidnightPitchTheme.primaryText,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: ' per player',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: MidnightPitchTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'COLLECTED: \u00a3${collected.toStringAsFixed(0)} / \u00a3${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: MidnightPitchTheme.skyBlue,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showChaseUnpaid(squadState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CHASE UNPAID',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MidnightPitchTheme.electricMintLight,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              MidnightPitchTheme.progressBar(progress, height: 8),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESS',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 0.15,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.electricMint,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessions(List<SessionPlanModel> sessions) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MidnightPitchTheme.sectionLabel('Upcoming Sessions'),
        const SizedBox(height: 16),
        ...sessions.take(2).map((session) => _buildSessionCard(session)),
      ],
    );
  }

  Widget _buildSessionCard(SessionPlanModel session) {
    final dayName = _getDayName(session.sessionDate.weekday);
    final dayNum = session.sessionDate.day;
    final monthName = _getMonthName(session.sessionDate.month);
    final hour = session.sessionDate.hour > 12 ? session.sessionDate.hour - 12 : session.sessionDate.hour;
    final minute = session.sessionDate.minute.toString().padLeft(2, '0');
    final ampm = session.sessionDate.hour >= 12 ? 'pm' : 'am';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: MidnightPitchTheme.championGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: MidnightPitchTheme.championGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  '$dayName $dayNum $monthName · $hour:$minute$ampm',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.totalDrills} drills',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.electricMint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadOverview(SquadState squadState) {
    final members = squadState.roster;
    final memberCount = squadState.rosterCount;

    final statusColors = {
      'yes': MidnightPitchTheme.electricMint,
      'maybe': MidnightPitchTheme.championGold,
      'no': MidnightPitchTheme.liveRed,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SQUAD \u00b7 $memberCount MEMBERS',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.08,
              ),
            ),
            Text(
              'MANAGE',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.skyBlue,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: members.take(6).map((member) {
              final status = squadState.rsvpStatus[member.userId] ?? 'no reply';
              final statusColor = statusColors[status] ?? MidnightPitchTheme.mutedText;
              return _buildPlayerRow(member, statusColor, status);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(TeamMember member, Color statusColor, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildInitialsAvatar(member.name.isNotEmpty ? member.name.substring(0, 2).toUpperCase() : '??'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.isNotEmpty ? member.name : 'Team Member',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                if (member.position.isNotEmpty)
                  Text(
                    member.position.toUpperCase(),
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 0.15,
                    ),
                  ),
              ],
            ),
          ),
          if (member.isCaptain)
            Icon(Icons.star, color: MidnightPitchTheme.championGold, size: 16),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MidnightPitchTheme.surfaceContainerHighest, MidnightPitchTheme.surfaceDim],
        ),
        border: Border.all(color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: MidnightPitchTheme.electricMintLight,
        ),
      ),
    );
  }

  void _showChaseUnpaid(SquadState squadState) {
    final unpaidMembers = squadState.roster.where((m) {
      return !squadState.payments.containsKey(m.userId) || squadState.payments[m.userId] == false;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpaid Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: unpaidMembers.isEmpty
              ? const Center(child: Text('All members have paid!'))
              : ListView.builder(
                  itemCount: unpaidMembers.length,
                  itemBuilder: (context, index) {
                    final member = unpaidMembers[index];
                    return ListTile(
                      leading: _buildInitialsAvatar(member.name.substring(0, 2).toUpperCase()),
                      title: Text(member.name),
                      trailing: TextButton(
                        onPressed: () {
                          ref.read(squadProvider.notifier).markPaid(member.userId, true);
                          Navigator.pop(context);
                        },
                        child: const Text('Mark Paid'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showInviteDialog(BuildContext context) {
    final team = ref.read(teamProvider).currentTeam;
    if (team == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite to Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with your teammates:',
              style: TextStyle(color: MidnightPitchTheme.mutedText),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                team.inviteCode,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MidnightPitchTheme.electricMint,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTeamSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: MidnightPitchTheme.electricMint),
              title: const Text('Edit Team Details', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit team coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: MidnightPitchTheme.mutedText),
              title: const Text('Manage Members', style: TextStyle(color: MidnightPitchTheme.primaryText)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage members coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: MidnightPitchTheme.liveRed),
              title: const Text('Leave Team', style: TextStyle(color: MidnightPitchTheme.liveRed)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leave team coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResultEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: const Text('Record Result', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: const Text(
          'Match result entry will be available here. Enter the score and match stats.',
          style: TextStyle(color: MidnightPitchTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Result entry coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.championGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Enter Result'),
          ),
        ],
      ),
    );
  }

  void _showTeamChat(BuildContext context) {
    final squadState = ref.read(squadProvider);
    final teamId = squadState.team?.teamId ?? widget.teamId ?? '';
    if (teamId.isEmpty) return;
    context.go('${AppRoutes.profile}/squad/chat/$teamId?name=${squadState.team?.name ?? 'Team'}');
  }

  void _sendMatchReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder sent to all team members'),
        backgroundColor: MidnightPitchTheme.electricMint,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}