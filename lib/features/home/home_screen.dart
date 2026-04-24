import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/features/home/player_home_widget.dart';
import 'package:footheroes/features/home/coach_home_widget.dart';
import 'package:footheroes/core/providers/user_mode_provider.dart';
import 'package:footheroes/widgets/premium_app_bar.dart';
import 'package:footheroes/widgets/wavy_divider.dart';

/// Home screen - redesigned with motion-driven layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(userModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: Stack(
        children: [
          // Radial glow background
          Positioned.fill(
            child: Container(decoration: AppTheme.radialGlowOverlay),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            clipBehavior: Clip.none,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  SizedBox(height: 80 + MediaQuery.of(context).padding.top),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(mode),
                      child: mode == UserMode.player
                          ? const PlayerHomeWidget()
                          : const CoachHomeWidget(),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumAppBar(
                  title: mode == UserMode.player ? 'PLAYER CENTER' : 'COACH CENTER',
                  scrollOffset: _scrollOffset,
                ),
                const WavyDivider(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
