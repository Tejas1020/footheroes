import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _ambientController;
  late AnimationController _shimmerController;

  // Background Animations
  late Animation<double> _bgScale;
  late Animation<double> _bgBlur;
  late Animation<double> _bgOpacity;
  late Animation<Offset> _bgParallax;

  // Branding Animations
  late Animation<double> _titleReveal;
  late Animation<double> _titleScale;
  late Animation<double> _taglineSlide;
  late Animation<double> _taglineOpacity;
  
  // UI Element Animations
  late Animation<double> _loaderReveal;
  late Animation<double> _loaderProgress;
  late Animation<double> _vignetteIntensity;

  final List<OrganicParticle> _particles = List.generate(
    25, 
    (index) => OrganicParticle(),
  );

  @override
  void initState() {
    super.initState();
    
    // Master timeline: 5 seconds of luxury motion
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // Infinite ambient motion for particles and slow drifts
    _ambientController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Shimmer effect for the title
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();

    _setupMotionDesign();
    
    _masterController.forward();
    _handleNavigation();
  }

  void _setupMotionDesign() {
    // --- STAGE 1: THE REVEAL (0-1.5s) ---
    _bgOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _bgScale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 1.0, curve: Curves.linearToEaseOut),
      ),
    );

    _bgBlur = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _vignetteIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    // --- STAGE 2: THE BRANDING (0.8-2.5s) ---
    _titleReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    _titleScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.8, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // --- STAGE 3: THE FINALE (2.0-5.0s) ---
    _loaderReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
      ),
    );

    _loaderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _bgParallax = Tween<Offset>(
      begin: const Offset(-0.02, -0.01),
      end: const Offset(0.02, 0.01),
    ).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!mounted) return;

    await ref.read(authProvider.notifier).checkSession();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _ambientController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cinematic Background Layer
          _buildCinematicBackground(),

          // 2. High-End Atmospheric Layer
          _buildLightingAndParticles(),

          // 3. Typography & Brand Layer
          _buildBrandingLayer(),

          // 4. Interaction Hint Layer (Loader)
          _buildLoaderLayer(),
        ],
      ),
    );
  }

  Widget _buildCinematicBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_masterController, _ambientController]),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return Transform.scale(
          scale: _bgScale.value,
          child: Transform.translate(
            offset: Offset(
              _bgParallax.value.dx * mediaQuery.size.width,
              _bgParallax.value.dy * mediaQuery.size.height,
            ),
            child: Opacity(
              opacity: _bgOpacity.value,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _bgBlur.value,
                  sigmaY: _bgBlur.value,
                ),
                child: Image.asset(
                  'assets/images/splash_image.jpeg',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLightingAndParticles() {
    return AnimatedBuilder(
      animation: Listenable.merge([_masterController, _ambientController]),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Dynamic Luxury Vignette
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4 * _vignetteIntensity.value),
                    Colors.black.withValues(alpha: 0.95 * _vignetteIntensity.value),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            
            // Bottom Cinematic Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.9 * _vignetteIntensity.value),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Floating Bokeh Particles
            CustomPaint(
              painter: LuxuryParticlePainter(
                particles: _particles,
                progress: _ambientController.value,
                opacity: _bgOpacity.value * 0.4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrandingLayer() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The "Pinterest-Perfect" Wordmark
          AnimatedBuilder(
            animation: Listenable.merge([_masterController, _shimmerController]),
            builder: (context, child) {
              return Opacity(
                opacity: _titleReveal.value,
                child: Transform.scale(
                  scale: _titleScale.value,
                  child: Column(
                    children: [
                      // Glow effect behind text to pop it from image
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft glow backdrop
                          Opacity(
                            opacity: 0.3 * _titleReveal.value,
                            child: Container(
                              width: 300,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.brandOrange.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // The Wordmark
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  AppTheme.brandGold.withValues(alpha: 0.8),
                                  Colors.white,
                                ],
                                stops: [
                                  _shimmerController.value - 0.3,
                                  _shimmerController.value,
                                  _shimmerController.value + 0.3,
                                ],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'KIXXON',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 8,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 30,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Refined Tagline with intentional design elements
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _masterController,
            builder: (context, child) {
              return Opacity(
                opacity: _taglineOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _taglineSlide.value),
                  child: Column(
                    children: [
                      // Designer geometric divider
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              AppTheme.brandOrange,
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'THE ULTIMATE ARENA',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoaderLayer() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          return Opacity(
            opacity: _loaderReveal.value,
            child: Column(
              children: [
                // Minimal Premium Loader
                Container(
                  width: 180,
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: _loaderProgress.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.brandOrange,
                                AppTheme.brandOrangeLight,
                                Colors.white,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandOrange.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SYNCING PROTOCOLS',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrganicParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 3 + 1;
  double speed = math.Random().nextDouble() * 0.02 + 0.005;
  double drift = (math.Random().nextDouble() - 0.5) * 0.1;
}

class LuxuryParticlePainter extends CustomPainter {
  final List<OrganicParticle> particles;
  final double progress;
  final double opacity;

  LuxuryParticlePainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (var particle in particles) {
      final currentY = (particle.y - progress * particle.speed) % 1.0;
      final currentX = (particle.x + math.sin(progress * math.pi * 2) * particle.drift) % 1.0;
      
      final x = currentX * size.width;
      final y = currentY * size.height;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
