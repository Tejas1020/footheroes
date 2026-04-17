import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_model.dart';
import '../widgets/bracket_widget.dart';
import '../features/tournament/presentation/widgets/tournament_header_widget.dart';
import '../features/tournament/presentation/widgets/tournament_bracket_widget.dart';
import '../features/tournament/presentation/widgets/tournament_teams_widget.dart';
import '../features/tournament/presentation/widgets/tournament_info_card.dart';
import '../features/tournament/presentation/widgets/tournament_dialogs.dart';

/// Tournament detail screen — bracket, standings, and match details.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final VoidCallback? onBack;

  const TournamentDetailScreen({super.key, required this.tournamentId, this.onBack});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tournamentProvider.notifier).loadTournamentDetails(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = ref.watch(tournamentProvider);
    final t = ts.selectedTournament;
    final auth = ref.watch(authProvider);
    final isOrganizer = t?.createdBy == auth.userId;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: ts.isLoading
          ? const Center(child: CircularProgressIndicator(color: MidnightPitchTheme.electricMint, strokeWidth: 2))
          : t == null
              ? _buildErrorState()
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    TournamentHeaderWidget(tournament: t, onBack: widget.onBack ?? () => context.go('/tournaments')),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(TabBar(
                        controller: _tabController,
                        indicatorColor: MidnightPitchTheme.electricMint,
                        indicatorWeight: 3,
                        labelColor: MidnightPitchTheme.electricMint,
                        unselectedLabelColor: MidnightPitchTheme.mutedText,
                        labelStyle: TextStyle(fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
                        tabs: const [Tab(text: 'Bracket'), Tab(text: 'Standings'), Tab(text: 'Info')],
                      )),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBracketTab(ts.bracket, t),
                      _buildStandingsTab(ts.standings, t),
                      _buildInfoTab(t, isOrganizer),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: MidnightPitchTheme.liveRed),
          const SizedBox(height: 16),
          Text('Tournament not found', style: MidnightPitchTheme.titleMD.copyWith(color: MidnightPitchTheme.primaryText)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/tournaments'),
            style: ElevatedButton.styleFrom(backgroundColor: MidnightPitchTheme.electricMint, foregroundColor: Colors.black),
            child: const Text('Back to Tournaments'),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketTab(BracketModel? bracket, TournamentModel t) {
    final dialogs = TournamentDialogs(ref: ref, context: context);
    return TournamentBracketSection(
      tournament: t,
      bracket: bracket,
      onMatchTap: (match) => dialogs.showMatchDialog(match, t),
    );
  }

  Widget _buildStandingsTab(List<TournamentTeamModel> standings, TournamentModel t) {
    if (standings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_chart, size: 48, color: MidnightPitchTheme.mutedText),
              const SizedBox(height: 16),
              Text('No standings available yet', style: MidnightPitchTheme.bodyMD, textAlign: TextAlign.center),
              Text('Standings will appear once matches start', style: MidnightPitchTheme.labelSM, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return StandingsTableWidget(standings: standings);
  }

  Widget _buildInfoTab(TournamentModel t, bool isOrganizer) {
    final dialogs = TournamentDialogs(ref: ref, context: context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TournamentInfoCard(tournament: t),
        const SizedBox(height: 16),
        TournamentTeamsWidget(
          tournament: t,
          isOrganizer: isOrganizer,
          onEditTournament: (t) => dialogs.showEditTournamentDialog(t),
          onOpenRegistration: (t) => dialogs.openRegistration(t),
          onStartTournament: (t) => dialogs.startTournament(t),
        ),
        const SizedBox(height: 16),
        _ShareButton(onTap: dialogs.shareBracket),
      ]),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.share),
        label: const Text('Share Results'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MidnightPitchTheme.electricMint,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: MidnightPitchTheme.surfaceContainer, child: tabBar);
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => true;
}
