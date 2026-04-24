import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../models/tournament_model.dart';
import '../../../../widgets/tournament_card_widget.dart';
import '../../../../core/router/app_router.dart';
import '../../../../widgets/premium_app_bar.dart';

/// Redesigned Tournament Home Screen for Dark Colour System.
class TournamentHomeScreen extends ConsumerStatefulWidget {
  const TournamentHomeScreen({super.key});

  @override
  ConsumerState<TournamentHomeScreen> createState() => _TournamentHomeScreenState();
}

class _TournamentHomeScreenState extends ConsumerState<TournamentHomeScreen> {
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournaments();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      backgroundColor: AppTheme.voidBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              
              // Tab Bar
              SliverToBoxAdapter(child: _buildTabBar()),
              
              // Content
              _buildContentSliver(),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          Positioned(
            top: 0, left: 0, right: 0,
            child: PremiumAppBar(
              title: 'TOURNAMENTS',
              scrollOffset: _scrollOffset,
              showBackButton: true,
              onBack: () => context.go(AppRoutes.home),
              actions: [
                _topAction(Icons.search_rounded, () => _showTournamentSearch(context)),
                const SizedBox(width: 8),
                _topAction(Icons.add_rounded, () => context.push(AppRoutes.tournamentCreate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topAction(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: AppTheme.cardBorder,
      ),
      child: Icon(icon, color: AppTheme.parchment, size: 20),
    ),
  );

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildTab('MY SQUAD', 0),
          const SizedBox(width: 16),
          _buildTab('JOIN OPEN', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 18,
              color: isSelected ? AppTheme.parchment : AppTheme.gold,
              letterSpacing: 1,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2, width: 12,
              decoration: BoxDecoration(color: AppTheme.cardinal, borderRadius: BorderRadius.circular(1)),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSliver() {
    final tournamentState = ref.watch(tournamentProvider);

    if (tournamentState.isLoading && tournamentState.myTournaments.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppTheme.cardinal)),
      );
    }

    if (tournamentState.hasError) {
      return SliverFillRemaining(
        child: Center(child: Text(tournamentState.error ?? 'Error', style: AppTheme.bodyReg)),
      );
    }

    final tournaments = _selectedTab == 0 ? tournamentState.myTournaments : tournamentState.publicTournaments;

    if (tournaments.isEmpty) {
      return SliverFillRemaining(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: AppTheme.gold.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('NO TOURNAMENTS FOUND', style: AppTheme.bebasDisplay.copyWith(fontSize: 20)),
              Text(_selectedTab == 0 ? 'Start your first tournament today' : 'Check back later for open cups', 
                style: AppTheme.labelSmall),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tournament = tournaments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TournamentCard(
                tournament: tournament,
                onTap: () => context.push('${AppRoutes.tournamentDetail}/${tournament.tournamentId}'),
                onRegisterTap: _selectedTab == 1 ? () => _showRegistrationDialog(tournament) : null,
              ),
            );
          },
          childCount: tournaments.length,
        ),
      ),
    );
  }

  void _showRegistrationDialog(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.abyss,
        title: Text('Join ${tournament.name}', style: AppTheme.bebasDisplay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format: ${tournament.format}', style: AppTheme.bodyReg),
            Text('Teams: ${tournament.teamsRegistered}/${tournament.maxTeams}', style: AppTheme.bodyReg),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.gold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _registerForTournament(tournament);
            },
            style: AppTheme.primaryButton,
            child: const Text('REGISTER TEAM'),
          ),
        ],
      ),
    );
  }

  void _registerForTournament(TournamentModel tournament) {
    final userTeams = ref.read(teamProvider).teams;

    if (userTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to create a team first'), backgroundColor: AppTheme.cardinal),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.abyss,
        title: Text('SELECT TEAM', style: AppTheme.bebasDisplay),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: userTeams.length,
            itemBuilder: (context, index) {
              final team = userTeams[index];
              return ListTile(
                leading: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: AppTheme.cardinal, shape: BoxShape.circle),
                  child: const Icon(Icons.shield, color: AppTheme.parchment, size: 16),
                ),
                title: Text(team.name, style: AppTheme.bodyBold),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final success = await ref.read(tournamentProvider.notifier).registerTeam(tournament.tournamentId, team.teamId);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? '${team.name} registered!' : 'Registration failed'),
                      backgroundColor: success ? AppTheme.navy : AppTheme.cardinal,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTournamentSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SEARCH TOURNAMENTS', style: AppTheme.bebasDisplay.copyWith(fontSize: 22)),
            const SizedBox(height: 20),
            Container(
              decoration: AppTheme.standardCard.copyWith(color: AppTheme.elevatedSurface),
              child: TextField(
                autofocus: true,
                style: AppTheme.bodyReg,
                decoration: InputDecoration(
                  hintText: 'Name or location...',
                  hintStyle: TextStyle(color: AppTheme.gold.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
