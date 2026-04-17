import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tournament_provider.dart';
import '../providers/team_provider.dart';
import '../models/tournament_model.dart';
import '../widgets/tournament_card_widget.dart';
import '../core/router/app_router.dart';

/// Tournament home screen - lists user's tournaments and public tournaments.
/// Allows creating new tournaments and browsing available ones to join.
class TournamentHomeScreen extends ConsumerStatefulWidget {
  const TournamentHomeScreen({super.key});

  @override
  ConsumerState<TournamentHomeScreen> createState() => _TournamentHomeScreenState();
}

class _TournamentHomeScreenState extends ConsumerState<TournamentHomeScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournaments();
    });
  }

  void _loadTournaments() {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) return;

    ref.read(tournamentProvider.notifier).loadTournaments(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopAppBar(),
            _buildTabBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.tournamentCreate);
        },
        backgroundColor: MidnightPitchTheme.electricMint,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // =============================================================================
  // TOP APP BAR
  // =============================================================================

  Widget _buildTopAppBar() {
    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tournaments',
                style: MidnightPitchTheme.titleLG.copyWith(
                  color: MidnightPitchTheme.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Compete, organize, win',
                style: MidnightPitchTheme.labelSM.copyWith(
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showTournamentSearch(context),
            icon: const Icon(Icons.search),
            color: MidnightPitchTheme.mutedText,
            iconSize: 24,
            tooltip: 'Search tournaments',
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // TAB BAR
  // =============================================================================

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildTab('My Tournaments', 0),
          const SizedBox(width: 16),
          _buildTab('Join', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MidnightPitchTheme.electricMint.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? MidnightPitchTheme.electricMint
                : MidnightPitchTheme.mutedText,
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // CONTENT
  // =============================================================================

  Widget _buildContent() {
    final tournamentState = ref.watch(tournamentProvider);
    final isLoading = tournamentState.isLoading;

    if (isLoading && tournamentState.myTournaments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: MidnightPitchTheme.electricMint,
          strokeWidth: 2,
        ),
      );
    }

    if (tournamentState.hasError) {
      return _buildErrorState(tournamentState.error ?? 'Failed to load tournaments');
    }

    return _selectedTab == 0
        ? _buildMyTournaments(tournamentState.myTournaments)
        : _buildPublicTournaments(tournamentState.publicTournaments);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: MidnightPitchTheme.liveRed,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: MidnightPitchTheme.bodySM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTournaments,
              style: ElevatedButton.styleFrom(
                backgroundColor: MidnightPitchTheme.electricMint,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // MY TOURNAMENTS
  // =============================================================================

  Widget _buildMyTournaments(List<TournamentModel> tournaments) {
    if (tournaments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No tournaments yet',
        subtitle: 'Create your first tournament or join an existing one',
        actionLabel: 'Create Tournament',
        onAction: () => context.push(AppRoutes.tournamentCreate),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTournaments(),
      color: MidnightPitchTheme.electricMint,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        children: [
          _buildTournamentSection(
            'Active',
            tournaments.where((t) => t.isActive).toList(),
            showOrganizerActions: true,
          ),
          _buildTournamentSection(
            'Registration Open',
            tournaments.where((t) => t.isRegistration).toList(),
          ),
          _buildTournamentSection(
            'Completed',
            tournaments.where((t) => t.isCompleted).toList(),
          ),
          _buildTournamentSection(
            'Drafts',
            tournaments.where((t) => t.isDraft).toList(),
            showOrganizerActions: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentSection(
    String title,
    List<TournamentModel> tournaments, {
    bool showOrganizerActions = false,
  }) {
    if (tournaments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: MidnightPitchTheme.labelSM,
          ),
        ),
        ...tournaments.map((tournament) => TournamentCard(
          tournament: tournament,
          onTap: () => _navigateToTournament(tournament),
          isOrganizer: showOrganizerActions,
        )),
      ],
    );
  }

  // =============================================================================
  // PUBLIC TOURNAMENTS (JOIN TAB)
  // =============================================================================

  Widget _buildPublicTournaments(List<TournamentModel> tournaments) {
    final registrationTournaments = tournaments.where((t) => t.isRegistration).toList();

    if (registrationTournaments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'No open tournaments',
        subtitle: 'Check back later for new tournaments to join',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTournaments(),
      color: MidnightPitchTheme.electricMint,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: registrationTournaments.length,
        itemBuilder: (context, index) {
          final tournament = registrationTournaments[index];
          return TournamentCard(
            tournament: tournament,
            onTap: () => _navigateToTournament(tournament),
            onRegisterTap: () => _showRegistrationDialog(tournament),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: MidnightPitchTheme.titleMD.copyWith(
                color: MidnightPitchTheme.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: MidnightPitchTheme.bodySM,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MidnightPitchTheme.electricMint,
                  foregroundColor: Colors.black,
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // ACTIONS
  // =============================================================================

  void _navigateToTournament(TournamentModel tournament) {
    context.push('${AppRoutes.tournamentDetail}/${tournament.tournamentId}');
  }

  void _showRegistrationDialog(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${tournament.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format: ${tournament.format}'),
            Text('Type: ${_getTypeText(tournament.type)}'),
            Text('Teams: ${tournament.teamsRegistered}/${tournament.maxTeams}'),
            if (tournament.venue != null)
              Text('Venue: ${tournament.venue}'),
            if (tournament.startDate != null)
              Text('Date: ${_formatDate(tournament.startDate!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _registerForTournament(tournament);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.electricMint,
              foregroundColor: Colors.black,
            ),
            child: const Text('Register Team'),
          ),
        ],
      ),
    );
  }

  void _registerForTournament(TournamentModel tournament) {
    final teamState = ref.read(teamProvider);
    final userTeams = teamState.teams;

    if (userTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to create or join a team first'),
          backgroundColor: MidnightPitchTheme.liveRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Text('Select Team', style: TextStyle(color: MidnightPitchTheme.primaryText)),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: userTeams.length,
            itemBuilder: (context, index) {
              final team = userTeams[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: MidnightPitchTheme.electricMint),
                ),
                title: Text(team.name, style: TextStyle(color: MidnightPitchTheme.primaryText)),
                subtitle: Text(team.format.toUpperCase(), style: TextStyle(color: MidnightPitchTheme.mutedText)),
                onTap: () async {
                  // FIX: tournament_home_screen — use_build_context_synchronously: capture SnackBar messenger BEFORE async
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final success = await ref.read(tournamentProvider.notifier).registerTeam(
                    tournament.tournamentId,
                    team.teamId,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? '${team.name} registered for ${tournament.name}!'
                            : 'Failed to register team'),
                        backgroundColor: success
                            ? MidnightPitchTheme.electricMint
                            : MidnightPitchTheme.liveRed,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'knockout':
        return 'Knockout';
      case 'league':
        return 'League';
      case 'group_knockout':
        return 'Groups + Knockout';
      default:
        return type;
    }
  }

  void _showTournamentSearch(BuildContext context) {
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
            Text(
              'Search Tournaments',
              style: MidnightPitchTheme.titleMD.copyWith(
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: MidnightPitchTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                hintStyle: TextStyle(color: MidnightPitchTheme.mutedText),
                filled: true,
                fillColor: MidnightPitchTheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: MidnightPitchTheme.mutedText),
              ),
              onSubmitted: (value) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: $value')),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}