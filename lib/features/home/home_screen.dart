import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../features/home/player_home_widget.dart';
import '../features/home/coach_home_widget.dart';
import '../core/providers/user_mode_provider.dart';
import '../widgets/motion_app_bar.dart';

/// Global notification provider for the app
final notificationProvider = NotificationProvider();

/// Home screen - redesigned with motion-driven layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    // Add demo notifications for testing
    _addDemoNotifications();
  }

  void _addDemoNotifications() {
    // Add some demo notifications to show the bell works
    Future.microtask(() {
      notificationProvider.addNotification(NotificationItem(
        id: '1',
        title: 'Match Starting!',
        body: 'Real Madrid vs Barcelona kicks off in 15 minutes',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        type: NotificationType.matchLive,
      ));
      notificationProvider.addNotification(NotificationItem(
        id: '2',
        title: 'Goal! ⚽',
        body: ' Benzema scores! Real Madrid 1-0 Barcelona',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        type: NotificationType.matchGoal,
      ));
      notificationProvider.addNotification(NotificationItem(
        id: '3',
        title: 'Team Invitation',
        body: 'Coach Smith invited you to join FC United',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.teamInvite,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: Column(
        children: [
          // Custom AppBar with animated greeting + notification bell
          PlayerHomeAppBar(
            playerName: _getPlayerName(),
            scrollOffset: 0,
            isConnected: ref.watch(authProvider).status == AuthStatus.authenticated,
            notificationProvider: notificationProvider,
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
    );
  }

  String _getPlayerName() {
    final authState = ref.watch(authProvider);
    return authState.name?.split(' ').first ??
           authState.email?.split('@').first ??
           'Player';
  }
}

