import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../core/providers/user_mode_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/luxury_background.dart';

/// Main shell — bottom nav docked at bottom, body fills remaining space.
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

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.scaffoldGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Abstract luxury lines background
            const LuxuryBackground(),
            // Main content with padding for floating nav bar
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: widget.child,
              ),
            ),
            // Floating Glassmorphism Nav Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNav(
                currentIndex: mode == UserMode.player ? _playerTabIndex : _coachTabIndex,
                onTap: (index) => _handleTabTap(mode, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabTap(UserMode mode, int index) {
    setState(() {
      if (mode == UserMode.player) {
        _playerTabIndex = index;
      } else {
        _coachTabIndex = index;
      }
    });
    switch (mode) {
      case UserMode.player:
        switch (index) {
          case 0: context.go('/home');
          case 1: context.go('/match');
          case 2: context.go('/learn/drills');
          case 3: context.go('/home/leaderboard');
          case 4: context.go('/home/profile');
        }
      case UserMode.coach:
        switch (index) {
          case 0: context.go('/home');
          case 1: context.go('/home/squad');
          case 2:
            final teamState = ref.read(teamProvider);
            final currentTeam = teamState.currentTeam;
            if (currentTeam != null) {
              context.go('/coach/${currentTeam.teamId}');
            }
          case 3: context.go('/learn');
          case 4: context.go('/learn/drills');
        }
    }
  }
}
