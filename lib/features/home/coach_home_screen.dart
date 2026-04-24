import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../models/team_model.dart';

/// Coach Home screen — displays user's teams and allows selection
/// to enter coach mode for a specific team.
class CoachHomeScreen extends ConsumerStatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  ConsumerState<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends ConsumerState<CoachHomeScreen> {
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
      ref.read(teamProvider.notifier).loadUserTeams(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final isLoading = teamState.status == TeamStatus.loading ||
        teamState.status == TeamStatus.initial;

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.navy,
                      ),
                    )
                  : teamState.teams.isEmpty
                      ? _buildEmptyState()
                      : _buildTeamList(teamState.teams),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.voidBg,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          const Icon(Icons.sports, color: AppTheme.navy, size: 28),
          const SizedBox(width: 12),
          Text(
            'COACH MODE',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.parchment,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: AppTheme.gold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Teams Yet',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a team to access coach features',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home/squad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: AppTheme.voidBg,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Go to Squad',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(List<TeamModel> teams) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    return GestureDetector(
      onTap: () {
        // Navigate to formation builder for this team
        context.go('/coach/${team.teamId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.elevatedSurface,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: AppTheme.navy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.parchment,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        team.format.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.gold,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  Icons.people_outline,
                  '${team.memberUids.length} Players',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.event_outlined,
                  'Next Match',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
