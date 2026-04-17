import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../core/providers/user_mode_provider.dart';
import '../../providers/team_provider.dart';

/// Main shell that wraps all tab-level screens with a mode-aware bottom nav.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _playerTabIndex = 0;
  int _coachTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: widget.child,
      bottomNavigationBar: _FootHeroesNavBar(
        mode: mode,
        playerTabIndex: _playerTabIndex,
        coachTabIndex: _coachTabIndex,
        onPlayerTabChange: (index) => setState(() => _playerTabIndex = index),
        onCoachTabChange: (index) => setState(() => _coachTabIndex = index),
        onTap: (index) => _handleTabTap(mode, index),
      ),
    );
  }

  void _handleTabTap(UserMode mode, int index) {
    switch (mode) {
      case UserMode.player:
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/match');
          case 2:
            context.go('/home/profile');
          case 3:
            context.go('/home/leaderboard');
        }
      case UserMode.coach:
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/home/squad');
          case 2:
            final teamState = ref.read(teamProvider);
            final currentTeam = teamState.currentTeam;
            if (currentTeam != null) {
              context.go('/coach/${currentTeam.teamId}');
            }
          case 3:
            context.go('/learn');
        }
    }
  }
}

class _FootHeroesNavBar extends StatelessWidget {
  final UserMode mode;
  final int playerTabIndex;
  final int coachTabIndex;
  final ValueChanged<int> onPlayerTabChange;
  final ValueChanged<int> onCoachTabChange;
  final ValueChanged<int> onTap;

  const _FootHeroesNavBar({
    required this.mode,
    required this.playerTabIndex,
    required this.coachTabIndex,
    required this.onPlayerTabChange,
    required this.onCoachTabChange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = mode == UserMode.player ? playerTabIndex : coachTabIndex;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const playerItems = [
      _NavItem(icon: Icons.person_outline, label: 'Dashboard'),
      _NavItem(icon: Icons.sports_soccer_outlined, label: 'Find Match'),
      _NavItem(icon: Icons.person_outline, label: 'Profile'),
      _NavItem(icon: Icons.emoji_events_outlined, label: 'Leaderboard'),
    ];

    const coachItems = [
      _NavItem(icon: Icons.dashboard_outlined, label: 'Home'),
      _NavItem(icon: Icons.groups_outlined, label: 'Squad'),
      _NavItem(icon: Icons.sports_outlined, label: 'Lineup'),
      _NavItem(icon: Icons.analytics_outlined, label: 'Analysis'),
    ];

    final items = mode == UserMode.player ? playerItems : coachItems;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2A3A)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return GestureDetector(
                onTap: () {
                  if (mode == UserMode.player) {
                    onPlayerTabChange(i);
                  } else {
                    onCoachTabChange(i);
                  }
                  onTap(i);
                },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: active ? 20 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? MidnightPitchTheme.electricMint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(
                        items[i].icon,
                        size: 20,
                        color: active
                            ? MidnightPitchTheme.electricMint
                            : MidnightPitchTheme.mutedText,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? MidnightPitchTheme.electricMint
                              : MidnightPitchTheme.mutedText,
                          letterSpacing: active ? 0.02 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}