import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/midnight_pitch_theme.dart';
import '../core/providers/user_mode_provider.dart';

/// Glassmorphic sidebar with player/coach toggle and animated nav items
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
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
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
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void close() {
    _controller.reverse();
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
        if (_controller.isDismissed) return const SizedBox.shrink();

        final screenW = MediaQuery.of(context).size.width;
        final drawerW = screenW * 0.78;

        return Stack(
          children: [
            // Blur overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: Colors.black.withValues(alpha: 0.5 * _fadeAnim.value)),
              ),
            ),
            // Drawer panel
            Positioned(
              left: _slideAnim.value * -drawerW,
              top: 0,
              bottom: 0,
              width: drawerW,
              child: _DrawerPanel(width: drawerW),
            ),
          ],
        );
      },
    );
  }
}

/// Drawer panel with BackdropFilter
class _DrawerPanel extends ConsumerWidget {
  final double width;
  const _DrawerPanel({required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.95),
                MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.80),
              ],
            ),
            border: const Border(
              right: BorderSide(color: Colors.white, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.deepNavy.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: _DrawerContent(width: width),
        ),
      ),
    );
  }
}

/// Drawer content with scroll
class _DrawerContent extends ConsumerWidget {
  final double width;
  const _DrawerContent({required this.width});

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
              color: MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close_rounded, color: MidnightPitchTheme.mutedText, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: MidnightPitchTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text('FOOTHEROES', style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
          child: Text(title, style: const TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 2,
          )),
        ),
        ...items,
      ],
    );
  }
}

/// Player / Coach toggle
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
          color: MidnightPitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MidnightPitchTheme.ghostBorder, width: 1.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? MidnightPitchTheme.primaryGradient : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          color: isActive ? Colors.white : MidnightPitchTheme.mutedText,
          letterSpacing: 1,
        )),
      ),
    );
  }
}

/// Nav item widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.25), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                    : MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isSelected ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.mutedText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? MidnightPitchTheme.electricBlue : MidnightPitchTheme.primaryText,
              )),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.electricBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.6), blurRadius: 6)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
