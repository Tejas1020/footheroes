import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../core/providers/user_mode_provider.dart';

/// Redesigned glassmorphic sidebar using Dark Colour System.
class GlassmorphicSidebar extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(int) onNavItemTap;
  final int selectedIndex;
  final bool isPlayerMode;

  const GlassmorphicSidebar({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onNavItemTap,
    required this.selectedIndex,
    required this.isPlayerMode,
  });

  @override
  ConsumerState<GlassmorphicSidebar> createState() => _GlassmorphicSidebarState();
}

class _GlassmorphicSidebarState extends ConsumerState<GlassmorphicSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isOpen) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(GlassmorphicSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.animateTo(1.0, duration: _controller.duration, curve: Curves.easeOutExpo);
      } else {
        _controller.animateTo(0.0, duration: _controller.duration, curve: Curves.easeOutExpo);
      }
    }
  }

  void close() {
    _controller.animateTo(0.0, duration: _controller.duration, curve: Curves.easeOutExpo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }

        final screenH = MediaQuery.of(context).size.height;
        final drawerH = screenH * 0.75;
        final bottomOffset = (1 - _controller.value) * drawerH;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: AppTheme.voidBg.withValues(alpha: 0.6 * _fadeAnim.value)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomOffset,
              height: drawerH,
              child: _DrawerPanel(height: drawerH),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerPanel extends ConsumerWidget {
  final double height;
  const _DrawerPanel({required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.abyss.withValues(alpha: 0.9),
            border: const Border(
              top: BorderSide(color: AppTheme.cardBorderColor, width: 1.5),
            ),
          ),
          child: const _DrawerContent(),
        ),
      ),
    );
  }
}

class _DrawerContent extends ConsumerWidget {
  const _DrawerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMode = ref.watch(userModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _PlayerCoachToggle(
                isPlayerMode: userMode == UserMode.player,
                onToggle: () => ref.read(userModeProvider.notifier).toggleMode(),
              ),
              const SizedBox(height: 36),
              _buildNavSection('PLAYER MODE', [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', isSelected: true, onTap: () {}),
                _NavItem(icon: Icons.sports_soccer_rounded, label: 'Find Match', isSelected: false, onTap: () {}),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', isSelected: false, onTap: () {}),
                _NavItem(icon: Icons.leaderboard_rounded, label: 'Leaderboard', isSelected: false, onTap: () {}),
              ]),
              const SizedBox(height: 24),
              _buildNavSection('COACH MODE', [
                _NavItem(icon: Icons.home_rounded, label: 'Home', isSelected: false, onTap: () {}),
                _NavItem(icon: Icons.groups_rounded, label: 'Squad', isSelected: false, onTap: () {}),
                _NavItem(icon: Icons.analytics_rounded, label: 'Analysis', isSelected: false, onTap: () {}),
              ]),
              const SizedBox(height: 32),
              _NavItem(icon: Icons.settings_rounded, label: 'Settings', isSelected: false, onTap: () {}),
              const SizedBox(height: 12),
              _NavItem(icon: Icons.help_outline_rounded, label: 'Help & Support', isSelected: false, onTap: () {}),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildLogo(),
        const Spacer(),
        GestureDetector(
          onTap: () => context.findAncestorStateOfType<_GlassmorphicSidebarState>()?.close(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close_rounded, color: AppTheme.parchment, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardinal.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_soccer, color: AppTheme.parchment, size: 20),
          const SizedBox(width: 8),
          Text('FOOTHEROES', style: AppTheme.bebasDisplay.copyWith(
            fontSize: 16,
            color: AppTheme.parchment,
            letterSpacing: 1.5,
          )),
        ],
      ),
    );
  }

  Widget _buildNavSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: AppTheme.labelSmall.copyWith(letterSpacing: 2)),
        ),
        ...items,
      ],
    );
  }
}

class _PlayerCoachToggle extends StatelessWidget {
  final bool isPlayerMode;
  final VoidCallback onToggle;
  const _PlayerCoachToggle({required this.isPlayerMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(16),
          border: AppTheme.cardBorder,
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _toggleLabel('PLAYER', isPlayerMode)),
            Expanded(child: _toggleLabel('COACH', !isPlayerMode)),
          ],
        ),
      ),
    );
  }

  Widget _toggleLabel(String text, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.verticalPillGradient : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: AppTheme.dmSans.copyWith(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          color: isActive ? AppTheme.parchment : AppTheme.gold,
          letterSpacing: 1,
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.cardinal : AppTheme.gold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardinal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.cardinal.withValues(alpha: 0.2), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.cardinal.withValues(alpha: 0.15)
                    : AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.parchment : AppTheme.gold,
              )),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.cardinal,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
