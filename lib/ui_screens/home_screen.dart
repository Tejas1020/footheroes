import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/mode_toggle.dart';
import '../features/home/player_home_widget.dart';
import '../features/home/coach_home_widget.dart';
import '../core/providers/user_mode_provider.dart';

/// Home screen - wraps Player/Coach mode content with mode toggle
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(userModeProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.name ?? 'Player';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopAppBar(firstName, context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good evening,',
                    style: MidnightPitchTheme.labelSM.copyWith(
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstName,
                    style: MidnightPitchTheme.titleLG.copyWith(
                      color: MidnightPitchTheme.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: ModeToggle(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: mode == UserMode.player
                  ? const PlayerHomeWidget()
                  : const CoachHomeWidget(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTopAppBar(String firstName, BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 8),
      color: MidnightPitchTheme.surfaceDim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _showNotificationsDialog(context),
            child: Icon(Icons.notifications_outlined, color: MidnightPitchTheme.mutedText, size: 24),
          ),
          const SizedBox(width: 4),
          _buildAvatar(firstName),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  static Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase()
        : '??';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MidnightPitchTheme.electricMint.withValues(alpha: 0.1),
        border: Border.all(
          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.13),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: MidnightPitchTheme.electricMint,
        ),
      ),
    );
  }

  static void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: MidnightPitchTheme.titleMD.copyWith(
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: MidnightPitchTheme.mutedText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: MidnightPitchTheme.bodySM,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}