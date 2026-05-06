import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../core/providers/user_mode_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  final VoidCallback? onBack;

  const RoleSelectionScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text('I AM A', style: AppTheme.bebasDisplay.copyWith(fontSize: 36, color: AppTheme.parchment)),
            const SizedBox(height: 6),
            Text(
              'Choose your path',
              style: AppTheme.dmSans.copyWith(fontSize: 14, color: AppTheme.mutedParchment),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildRoleCard(
                      context,
                      ref,
                      icon: Icons.sports_soccer,
                      title: 'PLAYER',
                      subtitle: 'Track your stats, find matches, and compare with pros',
                      mode: UserMode.player,
                    ),
                    const SizedBox(height: 20),
                    _buildRoleCard(
                      context,
                      ref,
                      icon: Icons.groups,
                      title: 'COACH',
                      subtitle: 'Manage your squad, run sessions, and analyse performance',
                      mode: UserMode.coach,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required UserMode mode,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(userModeProvider.notifier).setMode(mode);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.heroCtaGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.badgeShadow,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTheme.bebasDisplay.copyWith(fontSize: 28, color: AppTheme.parchment)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.dmSans.copyWith(
                fontSize: 13,
                color: AppTheme.mutedParchment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
