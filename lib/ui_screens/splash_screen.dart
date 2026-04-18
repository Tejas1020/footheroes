import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../core/router/app_router.dart';

/// Footheroes Splash Screen
/// Matches the HTML design with football stadium backdrop, soccer icon, and loading bar.
/// On init, calls checkSession() — GoRouter's redirect handles navigation.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Main content fade and scale
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Logo fade in
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Tagline fade in
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Loading bar animation
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate after duration — explicit navigation after session check
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await ref.read(authProvider.notifier).checkSession();
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              MidnightPitchTheme.surfaceContainer, // Center - white
              MidnightPitchTheme.surfaceDim, // Mid - white smoke
              MidnightPitchTheme.surfaceContainerHigh, // Edge - dust grey
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background Ambient Glow
            _buildAmbientGlow(),

            // Stadium Image Backdrop (low opacity)
            _buildStadiumBackdrop(),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding Icon
                    _buildBrandingIcon(),

                    const SizedBox(height: 32),

                    // Wordmark
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: child,
                        );
                      },
                      child: const Text(
                        'FOOTHEROES',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.headingFontFamily,
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 4,
                          color: MidnightPitchTheme.primaryText,
                          height: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineFadeAnimation.value,
                          child: child,
                        );
                      },
                      child: const Text(
                        'Your amateur football life, professionalised',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MidnightPitchTheme.mutedText,
                          letterSpacing: 0,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Loading Indicator
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _loadingAnimation.value,
                          child: child,
                        );
                      },
                      child: _buildLoadingIndicator(),
                    ),
                  ],
                ),
              ),
            ),

            // Version Footer
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'v1.0',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MidnightPitchTheme.surfaceContainerHighest,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 48,
                    height: 1,
                    color: MidnightPitchTheme.ghostBorder,
                  ),
                ],
              ),
            ),

            // Cinematic Vignette
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      MidnightPitchTheme.surfaceContainerHigh.withValues(alpha: 0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top-left glow (primary)
          Positioned(
            top: -200,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MidnightPitchTheme.electricMint.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Material(
                color: Colors.transparent,
                child: SizedBox.expand(),
              ),
            ),
          ),
          // Bottom-right glow (secondary)
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MidnightPitchTheme.skyBlue.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Material(
                color: Colors.transparent,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumBackdrop() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: Image.network(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAAK0njrG_ZWfQTE4kKio5yZkWL5yY3BRCSgfsZLKB4iW04-PFyraxNEEt2Dw8lzKo8wF4j5o2cIhPw6k5xYhz_F8F40sx7yHOZL_t8-QORKS1ZIxGYfL-eonQLTkbAncagVMsf2Bjm9cc6lUm7Pc33h9henFbnDV_w7uxqNL6DHD4xKzDwo0mJDp61NnlBReFds1k_uBweJPNUz5-wweqXLV7FYXMdvGmlmF-Kn5crN9qM8iVI84dfaOPgu8q2SzQYmtXJiat4wuY',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBrandingIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MidnightPitchTheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricMint.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_soccer,
        size: 48,
        color: MidnightPitchTheme.electricMint,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 192,
      height: 2,
      child: Stack(
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Fill
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _loadingAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        MidnightPitchTheme.electricMint, // primary
                        MidnightPitchTheme.skyBlue, // secondary
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
