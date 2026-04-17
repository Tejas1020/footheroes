import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/user_mode_provider.dart';
import '../theme/midnight_pitch_theme.dart';

/// Pill-style segmented toggle for switching between Player and Coach modes.
/// Stateless widget that reads/writes mode via Riverpod.
class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentMode = ref.watch(userModeProvider);

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegmentButton(
                icon: Icons.sports_soccer,
                label: 'Player',
                isActive: currentMode == UserMode.player,
                onTap: () => ref.read(userModeProvider.notifier).setMode(UserMode.player),
              ),
              const SizedBox(width: 4),
              _SegmentButton(
                icon: Icons.sports_outlined,
                label: 'Coach',
                isActive: currentMode == UserMode.coach,
                onTap: () => ref.read(userModeProvider.notifier).setMode(UserMode.coach),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? MidnightPitchTheme.electricMint : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? MidnightPitchTheme.surfaceDim
                  : MidnightPitchTheme.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? MidnightPitchTheme.surfaceDim
                    : MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
