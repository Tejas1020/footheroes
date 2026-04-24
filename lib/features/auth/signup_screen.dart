import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../../widgets/wavy_divider.dart';

/// Country data with name and flag emoji
class Country {
  final String name;
  final String flag;
  final String code;

  const Country({required this.name, required this.flag, required this.code});
}

/// List of countries with flags
const List<Country> countries = [
  Country(name: 'Afghanistan', flag: '🇦🇫', code: 'AF'),
  Country(name: 'Albania', flag: '🇦🇱', code: 'AL'),
  Country(name: 'Algeria', flag: '🇩🇿', code: 'DZ'),
  Country(name: 'Argentina', flag: '🇦🇷', code: 'AR'),
  Country(name: 'Australia', flag: '🇦🇺', code: 'AU'),
  Country(name: 'Austria', flag: '🇦🇹', code: 'AT'),
  Country(name: 'Belgium', flag: '🇧🇪', code: 'BE'),
  Country(name: 'Brazil', flag: '🇧🇷', code: 'BR'),
  Country(name: 'Canada', flag: '🇨🇦', code: 'CA'),
  Country(name: 'Chile', flag: '🇨🇱', code: 'CL'),
  Country(name: 'China', flag: '🇨🇳', code: 'CN'),
  Country(name: 'Colombia', flag: '🇨🇴', code: 'CO'),
  Country(name: 'Croatia', flag: '🇭🇷', code: 'HR'),
  Country(name: 'Czech Republic', flag: '🇨🇿', code: 'CZ'),
  Country(name: 'Denmark', flag: '🇩🇰', code: 'DK'),
  Country(name: 'Egypt', flag: '🇪🇬', code: 'EG'),
  Country(name: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', code: 'GB'),
  Country(name: 'Finland', flag: '🇫🇮', code: 'FI'),
  Country(name: 'France', flag: '🇫🇷', code: 'FR'),
  Country(name: 'Germany', flag: '🇩🇪', code: 'DE'),
  Country(name: 'Ghana', flag: '🇬🇭', code: 'GH'),
  Country(name: 'Greece', flag: '🇬🇷', code: 'GR'),
  Country(name: 'Hungary', flag: '🇭🇺', code: 'HU'),
  Country(name: 'India', flag: '🇮🇳', code: 'IN'),
  Country(name: 'Indonesia', flag: '🇮🇩', code: 'ID'),
  Country(name: 'Ireland', flag: '🇮🇪', code: 'IE'),
  Country(name: 'Italy', flag: '🇮🇹', code: 'IT'),
  Country(name: 'Japan', flag: '🇯🇵', code: 'JP'),
  Country(name: 'Kenya', flag: '🇰🇪', code: 'KE'),
  Country(name: 'Malaysia', flag: '🇲🇾', code: 'MY'),
  Country(name: 'Mexico', flag: '🇲🇽', code: 'MX'),
  Country(name: 'Morocco', flag: '🇲🇦', code: 'MA'),
  Country(name: 'Netherlands', flag: '🇳🇱', code: 'NL'),
  Country(name: 'New Zealand', flag: '🇳🇿', code: 'NZ'),
  Country(name: 'Nigeria', flag: '🇳🇬', code: 'NG'),
  Country(name: 'Norway', flag: '🇳🇴', code: 'NO'),
  Country(name: 'Pakistan', flag: '🇵🇰', code: 'PK'),
  Country(name: 'Poland', flag: '🇵🇱', code: 'PL'),
  Country(name: 'Portugal', flag: '🇵🇹', code: 'PT'),
  Country(name: 'Romania', flag: '🇷🇴', code: 'RO'),
  Country(name: 'Russia', flag: '🇷🇺', code: 'RU'),
  Country(name: 'Saudi Arabia', flag: '🇸🇦', code: 'SA'),
  Country(name: 'Scotland', flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿', code: 'GB'),
  Country(name: 'Senegal', flag: '🇸🇳', code: 'SN'),
  Country(name: 'Serbia', flag: '🇷🇸', code: 'RS'),
  Country(name: 'Singapore', flag: '🇸🇬', code: 'SG'),
  Country(name: 'South Africa', flag: '🇿🇦', code: 'ZA'),
  Country(name: 'South Korea', flag: '🇰🇷', code: 'KR'),
  Country(name: 'Spain', flag: '🇪🇸', code: 'ES'),
  Country(name: 'Sweden', flag: '🇸🇪', code: 'SE'),
  Country(name: 'Switzerland', flag: '🇨🇭', code: 'CH'),
  Country(name: 'Thailand', flag: '🇹🇭', code: 'TH'),
  Country(name: 'Turkey', flag: '🇹🇷', code: 'TR'),
  Country(name: 'Ukraine', flag: '🇺🇦', code: 'UA'),
  Country(name: 'United Arab Emirates', flag: '🇦🇪', code: 'AE'),
  Country(name: 'United Kingdom', flag: '🇬🇧', code: 'GB'),
  Country(name: 'United States', flag: '🇺🇸', code: 'US'),
  Country(name: 'Uruguay', flag: '🇺🇾', code: 'UY'),
  Country(name: 'Venezuela', flag: '🇻🇪', code: 'VE'),
  Country(name: 'Vietnam', flag: '🇻🇳', code: 'VN'),
  Country(name: 'Wales', flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿', code: 'GB'),
];

/// Footheroes Signup Screen
/// Matches the HTML design with email/password form and country dropdown
class SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSigninTap;
  final VoidCallback? onBackTap;

  const SignupScreen({
    super.key,
    this.onSigninTap,
    this.onBackTap,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Country? _selectedCountry;
  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_selectedCountry == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Oops!',
              message: 'Please select your country',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
      return;
    }

    // Validate date of birth
    if (_dateOfBirth == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Oops!',
              message: 'Please enter your date of birth',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
      return;
    }

    // Check age (must be 16+ for GDPR compliance)
    final age = DateTime.now().year - _dateOfBirth!.year;
    if (age < 16) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Age Restriction',
              message: 'You must be 16 or older to use FootHeroes.',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
      return;
    }

    // Check terms agreement
    if (!_agreedToTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Oops!',
              message: 'Please agree to the Terms of Service and Privacy Policy',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      country: _selectedCountry!.name,
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
              title: 'Welcome!',
              message: 'Your account has been created successfully',
              contentType: ContentType.success,
            ),
          ),
        );
      }
      // GoRouter redirect handles navigation after auth state change
    } else {
      final error = ref.read(authProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error',
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
            // TopAppBar
            _buildTopAppBar(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Header Section
                    _buildHeader(),

                    const SizedBox(height: 32),

                    // Signup Form
                    _buildSignupForm(),

                    const SizedBox(height: 40),

                    // Bottom Text
                    _buildBottomText(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Back Button
              IconButton(
                onPressed: widget.onBackTap,
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.gold,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              // Logo
              const Text(
                'FOOTHEROES',
                style: TextStyle(
                  fontFamily: AppTheme.displayFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 4,
                  color: AppTheme.navy,
                ),
              ),
              const Spacer(),
              // Spacer for symmetry
              const SizedBox(width: 40),
            ],
          ),
        ),
        const WavyDivider(height: 10),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your account',
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
            color: AppTheme.parchment,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Join 10,000+ grassroots players',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.gold,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        // Full Name Field
        _buildInputField(
          label: 'Full name',
          controller: _nameController,
          hint: 'Enter your name',
          keyboardType: TextInputType.name,
        ),

        const SizedBox(height: 16),

        // Email Field
        _buildInputField(
          label: 'Email address',
          controller: _emailController,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Password Field
        _buildPasswordField(),

        const SizedBox(height: 16),

        // Country Dropdown
        _buildCountryDropdown(),

        const SizedBox(height: 16),

        // Date of Birth
        _buildDateOfBirthField(),

        const SizedBox(height: 16),

        // Terms Agreement
        _buildTermsCheckbox(),

        const SizedBox(height: 24),

        // Primary CTA
        _buildSignupButton(),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.08,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: AppTheme.parchment,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppTheme.gold,
              ),
              filled: true,
              fillColor: AppTheme.abyss,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.cardBorderColor,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.cardBorderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.navy,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'PASSWORD',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.08,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: AppTheme.parchment,
            ),
            decoration: InputDecoration(
              hintText: 'Create a password',
              hintStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppTheme.gold,
              ),
              filled: true,
              fillColor: AppTheme.abyss,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.gold,
                  size: 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.cardBorderColor,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.cardBorderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.navy,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'COUNTRY',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.08,
            ),
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.abyss,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.cardBorderColor,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: _showCountryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedCountry != null) ...[
                    Text(
                      _selectedCountry!.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCountry!.name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          color: AppTheme.parchment,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Text(
                        'Select your country',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ],
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.gold,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Country',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.parchment,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        country.name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          color: AppTheme.parchment,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignupButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.parchment,
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
            : const Text(
                'Create account',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: widget.onSigninTap,
          child: const Text(
            'Sign in',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'DATE OF BIRTH',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.08,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.abyss,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.cardBorderColor,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.gold, size: 18),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day} ${_getMonthName(_dateOfBirth!.month)} ${_dateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    color: _dateOfBirth != null
                        ? AppTheme.parchment
                        : AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.navy,
              surface: AppTheme.voidBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _agreedToTerms ? AppTheme.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreedToTerms ? AppTheme.navy : AppTheme.gold,
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check, size: 14, color: AppTheme.voidBg)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I agree to the Terms of Service and Privacy Policy',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: AppTheme.mutedParchment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
