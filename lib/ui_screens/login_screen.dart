import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../core/router/app_router.dart';

/// Footheroes Login Screen
/// Matches the HTML design with email/password form
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSignupTap;
  final VoidCallback? onForgotPasswordTap;
  final VoidCallback? onBackTap;

  const LoginScreen({
    super.key,
    this.onSignupTap,
    this.onForgotPasswordTap,
    this.onBackTap,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Welcome back!',
              message: 'You have successfully signed in',
              contentType: ContentType.success,
            ),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } else {
      final error = ref.read(authProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Oops!',
              message: error,
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        child: Column(
          children: [
            // iOS Status Bar Simulation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '9:41',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.signal_cellular_4_bar,
                        size: 18,
                        color: MidnightPitchTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.wifi,
                        size: 18,
                        color: MidnightPitchTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.battery_full,
                        size: 20,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Navigation
            _buildTopNavigation(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Brand Identity Section
                    _buildBrandIdentity(),

                    const SizedBox(height: 48),

                    // Headline Group
                    _buildHeadline(),

                    const SizedBox(height: 40),

                    // Login Form
                    _buildLoginForm(),

                    const SizedBox(height: 40),

                    // Secondary Navigation
                    _buildSecondaryNavigation(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBackTap,
            icon: const Icon(
              Icons.arrow_back,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIdentity() {
    return Column(
      children: [
        const Text(
          'FootHeroes',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.electricBlue,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back.',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 40,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
            color: MidnightPitchTheme.primaryText,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to your FootHeroes account',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        _buildEmailField(),

        const SizedBox(height: 24),

        // Password Field
        _buildPasswordField(),

        const SizedBox(height: 24),

        // Sign In Button
        _buildSignInButton(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EMAIL ADDRESS',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.08,
            color: MidnightPitchTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MidnightPitchTheme.ghostBorder),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.mail_outline,
                  size: 20,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      color: MidnightPitchTheme.mutedText,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 12, right: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASSWORD',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.08,
            color: MidnightPitchTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MidnightPitchTheme.ghostBorder),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    color: MidnightPitchTheme.primaryText,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      color: MidnightPitchTheme.mutedText,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 12, right: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onForgotPasswordTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MidnightPitchTheme.electricBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: MidnightPitchTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Sign in',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
        TextButton(
          onPressed: widget.onSignupTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Create one',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.electricBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _launchUrl('https://footheroes.com/privacy'),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 0.02,
                    ),
                  ),
                  const TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.mutedText,
                      decoration: TextDecoration.underline,
                      letterSpacing: 0.02,
                    ),
                  ),
                  const TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 0.02,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MidnightPitchTheme.electricBlue,
                      decoration: TextDecoration.underline,
                      letterSpacing: 0.02,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2024 FOOTHEROES PERFORMANCE LAB',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 24),
          // iOS Home Indicator
          Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.mutedText,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
