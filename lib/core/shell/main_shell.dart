import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../core/providers/user_mode_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/custom_bottom_nav.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: widget.child,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: mode == UserMode.player ? _playerTabIndex : _coachTabIndex,
        onTap: (index) => _handleTabTap(mode, index),
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
          case 3: context.go('/home/profile');
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
        }
    }
  }
}
