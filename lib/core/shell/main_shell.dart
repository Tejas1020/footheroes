import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/midnight_pitch_theme.dart';
import '../../core/providers/user_mode_provider.dart';
import '../../providers/team_provider.dart';

/// Main shell that wraps all tab-level screens with a floating top nav bar.
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
      body: Stack(
        children: [
          widget.child,
          _FloatingTopNavBar(
            mode: mode,
            playerTabIndex: _playerTabIndex,
            coachTabIndex: _coachTabIndex,
            onPlayerTabChange: (index) => setState(() => _playerTabIndex = index),
            onCoachTabChange: (index) => setState(() => _coachTabIndex = index),
            onTap: (index) => _handleTabTap(mode, index),
          ),
        ],
      ),
    );
  }

  void _handleTabTap(UserMode mode, int index) {
    switch (mode) {
      case UserMode.player:
        switch (index) {
          case 0: context.go('/home');
          case 1: context.go('/match');
          case 2: context.go('/home/profile');
          case 3: context.go('/home/leaderboard');
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

/// Floating top navigation bar with glassmorphic pill design
class _FloatingTopNavBar extends StatefulWidget {
  final UserMode mode;
  final int playerTabIndex;
  final int coachTabIndex;
  final ValueChanged<int> onPlayerTabChange;
  final ValueChanged<int> onCoachTabChange;
  final ValueChanged<int> onTap;

  const _FloatingTopNavBar({
    required this.mode,
    required this.playerTabIndex,
    required this.coachTabIndex,
    required this.onPlayerTabChange,
    required this.onCoachTabChange,
    required this.onTap,
  });

  @override
  State<_FloatingTopNavBar> createState() => _FloatingTopNavBarState();
}

class _FloatingTopNavBarState extends State<_FloatingTopNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.mode == UserMode.player ? widget.playerTabIndex : widget.coachTabIndex;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenW = MediaQuery.of(context).size.width;
    final navW = screenW * 0.88;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, _) {
        return Positioned(
          bottom: bottomPadding + 16,
          left: (screenW - navW) / 2,
          right: (screenW - navW) / 2,
          child: Transform.scale(
            scale: _scaleAnim.value,
            alignment: Alignment.bottomCenter,
            child: _buildNavBar(currentIndex, navW),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(int currentIndex, double width) {
    final items = widget.mode == UserMode.player ? _playerItems : _coachItems;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: 80,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.deepNavy.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavTile(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () {
                    if (widget.mode == UserMode.player) {
                      widget.onPlayerTabChange(i);
                    } else {
                      widget.onCoachTabChange(i);
                    }
                    widget.onTap(i);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isActive, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_NavTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _bounceAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnim.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: widget.isActive ? 38 : 32,
              height: widget.isActive ? 38 : 32,
              decoration: BoxDecoration(
                gradient: widget.isActive ? MidnightPitchTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.item.icon,
                size: widget.isActive ? 20 : 18,
                color: widget.isActive ? Colors.white : MidnightPitchTheme.mutedText,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isActive ? 28 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                gradient: widget.isActive ? MidnightPitchTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(2),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 8,
                fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                color: widget.isActive
                    ? MidnightPitchTheme.electricBlue
                    : MidnightPitchTheme.mutedText,
                letterSpacing: widget.isActive ? 0.08 : 0,
              ),
            ),
            const SizedBox(height: 4),
          ],
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

const _playerItems = [
  _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
  _NavItem(icon: Icons.search_rounded, label: 'Find'),
  _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  _NavItem(icon: Icons.leaderboard_rounded, label: 'Ranks'),
];

const _coachItems = [
  _NavItem(icon: Icons.home_rounded, label: 'Home'),
  _NavItem(icon: Icons.groups_3_rounded, label: 'Squad'),
  _NavItem(icon: Icons.event_note_rounded, label: 'Lineup'),
  _NavItem(icon: Icons.insights_rounded, label: 'Insights'),
];