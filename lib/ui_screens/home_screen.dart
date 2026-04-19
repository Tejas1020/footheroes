import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../features/home/player_home_widget.dart';
import '../features/home/coach_home_widget.dart';
import '../core/providers/user_mode_provider.dart';
import '../widgets/glassmorphic_sidebar.dart';
import '../widgets/motion_app_bar.dart';

/// Home screen - redesigned with glassmorphic sidebar and motion-driven layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _sidebarOpen = false;
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Custom AppBar with animated greeting
              PlayerHomeAppBar(
                playerName: _getPlayerName(),
                greeting: _getGreeting(),
                scrollOffset: 0,
                onMenuTap: () => setState(() => _sidebarOpen = true),
                isConnected: ref.watch(authProvider).status == AuthStatus.authenticated,
              ),

              // Page content with crossfade transition
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(mode),
                    child: mode == UserMode.player
                        ? const PlayerHomeWidget()
                        : const CoachHomeWidget(),
                  ),
                ),
              ),
            ],
          ),

          // Glassmorphic sidebar overlay
          GlassmorphicSidebar(
            isOpen: _sidebarOpen,
            onClose: () => setState(() => _sidebarOpen = false),
            onNavItemTap: (index) {
              setState(() {
                _sidebarOpen = false;
                _selectedNavIndex = index;
              });
            },
            selectedIndex: _selectedNavIndex,
            isPlayerMode: mode == UserMode.player,
          ),
        ],
      ),
    );
  }

  String _getPlayerName() {
    final authState = ref.watch(authProvider);
    return authState.name?.split(' ').first ??
           authState.email?.split('@').first ??
           'Player';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Ready to score today?';
    if (hour < 17) return 'Keep the momentum going!';
    return 'Night mode activated.';
  }
}

