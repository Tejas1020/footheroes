import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';

/// Footheroes Login Screen
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
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBrandIdentity(),
                    const SizedBox(height: 48),
                    _buildHeadline(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                    const SizedBox(height: 40),
                    _buildSecondaryNavigation(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBackTap ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: AppTheme.cardBorder,
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.parchment, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIdentity() {
    return Column(
      children: [
        Text(
          'FootHeroes',
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 24,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.cardinal,
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
        Text(
          'Welcome back.',
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 40,
            letterSpacing: 1.5,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your FootHeroes account',
          style: AppTheme.dmSans.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildEmailField(),
        const SizedBox(height: 24),
        _buildPasswordField(),
        const SizedBox(height: 24),
        _buildSignInButton(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMAIL ADDRESS',
          style: AppTheme.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.08,
            color: AppTheme.mutedParchment,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.voidBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.mail_outline, size: 20, color: AppTheme.gold),
              ),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.dmSans.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      color: AppTheme.gold,
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
        Text(
          'PASSWORD',
          style: AppTheme.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.08,
            color: AppTheme.mutedParchment,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.voidBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.lock_outline, size: 20, color: AppTheme.gold),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.dmSans.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      color: AppTheme.gold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 12, right: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20, color: AppTheme.gold,
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
            child: Text(
              'Forgot password?',
              style: AppTheme.dmSans.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.cardinal,
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
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardinal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.parchment,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: AppTheme.dmSans.copyWith(fontSize: 14),
        ),
        TextButton(
          onPressed: widget.onSignupTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Create one',
            style: AppTheme.dmSans.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.cardinal,
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
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gold,
                    ),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gold,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.redMid,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2024 FOOTHEROES PERFORMANCE LAB',
            style: AppTheme.dmSans.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.08,
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
