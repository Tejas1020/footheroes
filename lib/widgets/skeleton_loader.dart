import 'package:flutter/material.dart';
import '../theme/midnight_pitch_theme.dart';

/// Reusable skeleton loader widget for consistent loading states.
/// Shows an animated grey placeholder that matches the shape of content.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Duration duration;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                MidnightPitchTheme.surfaceContainer,
                MidnightPitchTheme.surfaceContainerHigh,
                MidnightPitchTheme.surfaceContainer,
              ],
              stops: [
                0.0,
                (_animation.value + 2) / 4,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card-style skeleton loader for stat cards and content blocks.
class SkeletonCard extends StatelessWidget {
  final double height;
  final int childCount;
  final double spacing;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.childCount = 1,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          childCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < childCount - 1 ? spacing : 0),
            child: const SkeletonLoader(height: 16),
          ),
        ),
      ),
    );
  }
}

/// Row of skeleton stat items for stats displays.
class SkeletonStatsRow extends StatelessWidget {
  final int statCount;

  const SkeletonStatsRow({
    super.key,
    this.statCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        statCount,
        (index) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 24, width: 40),
                const SizedBox(height: 8),
                const SkeletonLoader(height: 12, width: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
