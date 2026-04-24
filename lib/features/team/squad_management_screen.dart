import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../providers/squad_provider.dart';
import '../../../repositories/team_repository.dart' show TeamMember;
import '../../../models/team_model.dart';
import '../../../models/session_plan_model.dart';

/// Redesigned squad management using Dark Colour System.
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

class _SquadManagementScreenState extends ConsumerState<SquadManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
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
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SquadTopBar(
              team: teamState.currentTeam,
              onBack: widget.onBack,
              onInvite: () => _showInviteDialog(context),
              onSettings: () => _showTeamSettings(context),
            ),
            Expanded(
              child: isLoading
                  ? _LoadingSkeleton()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: AnimatedBuilder(
                        animation: _entryController,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _entryController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _entryController.value)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (squadState.error != null)
                                    _ErrorBanner(
                                      error: squadState.error!,
                                      onDismiss: () => ref.read(squadProvider.notifier).clearError(),
                                    ),
                                  _QuickActions(team: teamState.currentTeam, squadState: squadState, teamId: widget.teamId),
                                  const SizedBox(height: 28),
                                  _NextMatchCard(),
                                  const SizedBox(height: 28),
                                  _PaymentSplitCard(teamState.currentTeam, squadState),
                                  const SizedBox(height: 28),
                                  _UpcomingSessionsCard(squadState.upcomingSessions),
                                  const SizedBox(height: 28),
                                  _SquadRoster(squadState),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final team = ref.read(teamProvider).currentTeam;
    if (team == null) return;
    showDialog(
      context: context,
      builder: (context) => _SquadDialog(
        title: 'Invite to Team',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with your teammates:',
              style: TextStyle(color: AppTheme.gold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.standardCard.copyWith(
                color: AppTheme.elevatedSurface,
              ),
              child: Text(
                team.inviteCode,
                style: AppTheme.bebasDisplay.copyWith(
                  fontSize: 32,
                  color: AppTheme.cardinal,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _DialogButton('Close', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showTeamSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SquadBottomSheet(
        children: [
          _SheetItem(
            icon: Icons.edit_outlined,
            label: 'Edit Team Details',
            color: AppTheme.cardinal,
            onTap: () { Navigator.pop(context); }
          ),
          _SheetItem(
            icon: Icons.people_outline,
            label: 'Manage Members',
            color: AppTheme.gold,
            onTap: () { Navigator.pop(context); }
          ),
          _SheetItem(
            icon: Icons.delete_outline,
            label: 'Leave Team',
            color: AppTheme.cardinal,
            onTap: () { Navigator.pop(context); }
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _SquadTopBar extends StatelessWidget {
  final TeamModel? team;
  final VoidCallback? onBack;
  final VoidCallback onInvite;
  final VoidCallback onSettings;

  const _SquadTopBar({
    this.team,
    this.onBack,
    required this.onInvite,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final teamName = team?.name ?? 'FC United';
    final formatLabel = team?.format.toUpperCase() ?? '11-A-SIDE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.abyss,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            _TopBarIconButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: onBack!,
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.heroCtaGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: AppTheme.parchment, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parchment,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatLabel,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _TopBarIconButton(
            icon: Icons.settings_outlined,
            onTap: onSettings,
          ),
          const SizedBox(width: 8),
          _InviteButton(onTap: onInvite),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: AppTheme.cardBorder,
        ),
        child: Icon(icon, color: AppTheme.parchment, size: 20),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InviteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.heroCtaGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardinal.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          'INVITE',
          style: AppTheme.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.parchment,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatefulWidget {
  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: _SkeletonCard(shimmer: _shimmer.value),
            )),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double shimmer;
  const _SkeletonCard({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: AppTheme.standardCard,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: shimmer.clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  AppTheme.cardinal.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardinal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardinal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.cardinal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTheme.dmSans.copyWith(
                fontSize: 13,
                color: AppTheme.cardinal,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppTheme.cardinal, size: 20),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  final TeamModel? team;
  final SquadState squadState;
  final String? teamId;

  const _QuickActions({this.team, required this.squadState, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.auto_awesome,
            label: 'Lineup',
            color: AppTheme.cardinal,
            onTap: () {
              if (team != null && squadState.nextMatch != null) {
                // Navigate to lineup
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.scoreboard,
            label: 'Result',
            color: AppTheme.rose,
            onTap: () => _showResultEntry(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.forum_outlined,
            label: 'Chat',
            color: AppTheme.gold,
            onTap: () => _showTeamChat(context, ref),
          ),
        ),
      ],
    );
  }

  void _showResultEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SquadDialog(
        title: 'Record Result',
        content: const Text(
          'Match result entry will be available here. Enter the score and match stats.',
          style: TextStyle(color: AppTheme.parchment),
        ),
        actions: [
          _DialogButton('Cancel', onTap: () => Navigator.pop(context)),
          _DialogButton('Enter', isPrimary: true, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showTeamChat(BuildContext context, WidgetRef ref) {
    final squadState = ref.read(squadProvider);
    final chatTeamId = squadState.team?.teamId ?? teamId ?? '';
    if (chatTeamId.isEmpty) return;
    context.go('${AppRoutes.profile}/squad/chat/$chatTeamId?name=${Uri.encodeComponent(squadState.team?.name ?? 'Team')}');
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: AppTheme.standardCard,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(color: AppTheme.gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder data
    const dateStr = 'Sat 26 Apr · 10:00am';
    const locationStr = 'Tottenham Marshes';
    const confirmed = 8;
    const maybe = 3;
    const out = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppTheme.accentBar(),
                const SizedBox(width: 8),
                Text(
                  'NEXT MATCH',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardinal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'IN 5 DAYS',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.cardinal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: AppTheme.premiumCard,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppTheme.accentBar(),
                  const SizedBox(width: 12),
                  Text(
                    dateStr,
                    style: AppTheme.bebasDisplay.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    locationStr,
                    style: AppTheme.dmSans.copyWith(fontSize: 13, color: AppTheme.gold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _RsvpChip(color: AppTheme.cardinal, count: confirmed, label: 'GOING'),
                  const SizedBox(width: 8),
                  _RsvpChip(color: AppTheme.rose, count: maybe, label: 'MAYBE'),
                  const SizedBox(width: 8),
                  _RsvpChip(color: AppTheme.navy, count: out, label: 'OUT'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: AppTheme.primaryButton,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('SEND REMINDER'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RsvpChip extends StatelessWidget {
  final Color color;
  final int count;
  final String label;
  const _RsvpChip({required this.color, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _PaymentSplitCard extends StatelessWidget {
  final TeamModel? team;
  final SquadState squadState;

  const _PaymentSplitCard(this.team, this.squadState);

  @override
  Widget build(BuildContext context) {
    final paidCount = squadState.paidCount;
    final memberCount = squadState.rosterCount;
    const totalAmount = 70.0;
    final perPlayer = memberCount > 0 ? totalAmount / memberCount : 5.0;
    final progress = memberCount > 0 ? paidCount / memberCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'MATCH FEE',
              style: AppTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: AppTheme.standardCard,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '£${perPlayer.toStringAsFixed(0)}',
                        style: AppTheme.bebasDisplay.copyWith(fontSize: 32, color: AppTheme.parchment),
                      ),
                      Text(
                        'per player',
                        style: AppTheme.labelSmall,
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showChaseUnpaid(context, squadState),
                    style: AppTheme.primaryButton.copyWith(
                      backgroundColor: WidgetStatePropertyAll(AppTheme.cardinal.withValues(alpha: 0.1)),
                      foregroundColor: const WidgetStatePropertyAll(AppTheme.cardinal),
                    ),
                    child: const Text('CHASE'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroCtaGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COLLECTED: £${(paidCount * perPlayer).toStringAsFixed(0)}',
                    style: AppTheme.labelSmall,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: AppTheme.cardinal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChaseUnpaid(BuildContext context, SquadState squadState) {
    showDialog(
      context: context,
      builder: (context) => _SquadDialog(
        title: 'Unpaid Members',
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: squadState.roster.isEmpty
              ? const Center(child: Text('No members', style: TextStyle(color: AppTheme.gold)))
              : ListView.builder(
                  itemCount: squadState.roster.length,
                  itemBuilder: (context, index) {
                    final member = squadState.roster[index];
                    return ListTile(
                      leading: _PlayerAvatar(initials: member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '??'),
                      title: Text(member.name, style: AppTheme.bodyBold),
                      subtitle: Text(member.position, style: AppTheme.labelSmall),
                    );
                  },
                ),
        ),
        actions: [
          _DialogButton('Close', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _UpcomingSessionsCard extends StatelessWidget {
  final List<SessionPlanModel> sessions;
  const _UpcomingSessionsCard(this.sessions);

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppTheme.accentBar(),
            const SizedBox(width: 8),
            Text(
              'UPCOMING SESSIONS',
              style: AppTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...sessions.take(2).map((s) => _SessionCard(session: s)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionPlanModel session;
  const _SessionCard({required this.session});

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'pm' : 'am';
    return '$h:$m$ampm';
  }

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.standardCard,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${session.sessionDate.day}',
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 18, color: AppTheme.cardinal),
                ),
                Text(
                  months[session.sessionDate.month - 1].toUpperCase(),
                  style: AppTheme.dmSans.copyWith(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.gold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: AppTheme.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(session.sessionDate),
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.cardinal),
        ],
      ),
    );
  }
}

class _SquadRoster extends StatelessWidget {
  final SquadState squadState;
  const _SquadRoster(this.squadState);

  @override
  Widget build(BuildContext context) {
    final members = squadState.roster;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppTheme.accentBar(),
                const SizedBox(width: 8),
                Text(
                  'SQUAD',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
            Text(
              '${squadState.rosterCount} MEMBERS',
              style: AppTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: AppTheme.standardCard,
          child: Column(
            children: members.take(6).map((member) {
              return _PlayerRow(member: member);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final TeamMember member;

  const _PlayerRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorderColor)),
      ),
      child: Row(
        children: [
          _PlayerAvatar(
            initials: member.name.isNotEmpty
                ? member.name.substring(0, 1).toUpperCase()
                : '??',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTheme.bodyBold,
                ),
                Text(
                  member.position.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          if (member.isCaptain)
            const Icon(Icons.star, color: AppTheme.cardinal, size: 16),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String initials;
  const _PlayerAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppTheme.elevatedSurface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTheme.bebasDisplay.copyWith(
          fontSize: 16,
          color: AppTheme.parchment,
        ),
      ),
    );
  }
}

class _SquadDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _SquadDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.abyss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.bebasDisplay.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DialogButton(this.label, {required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: isPrimary ? AppTheme.primaryButton : null,
      child: Text(
        label,
        style: AppTheme.dmSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isPrimary ? AppTheme.parchment : AppTheme.gold,
        ),
      ),
    );
  }
}

class _SquadBottomSheet extends StatelessWidget {
  final List<Widget> children;
  const _SquadBottomSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.abyss,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTheme.bodyBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
