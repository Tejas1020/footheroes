import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../core/router/app_router.dart';

/// Football positions
class FootballPosition {
  final String code;
  final String name;
  final IconData icon;

  const FootballPosition({
    required this.code,
    required this.name,
    required this.icon,
  });
}

/// Available positions
const List<FootballPosition> primaryPositions = [
  FootballPosition(code: 'GK', name: 'Goalkeeper', icon: Icons.radio_button_checked),
  FootballPosition(code: 'CB', name: 'Centre-Back', icon: Icons.shield),
  FootballPosition(code: 'LB', name: 'Left-Back', icon: Icons.shield),
  FootballPosition(code: 'RB', name: 'Right-Back', icon: Icons.shield),
  FootballPosition(code: 'CDM', name: 'Def. Midfielder', icon: Icons.sync_alt),
  FootballPosition(code: 'CM', name: 'Central Mid', icon: Icons.sync_alt),
  FootballPosition(code: 'CAM', name: 'Att. Midfielder', icon: Icons.bolt),
  FootballPosition(code: 'LM', name: 'Left Mid', icon: Icons.bolt),
  FootballPosition(code: 'RM', name: 'Right Mid', icon: Icons.bolt),
  FootballPosition(code: 'LW', name: 'Left Winger', icon: Icons.bolt),
  FootballPosition(code: 'ST', name: 'Striker', icon: Icons.bolt),
];

const List<FootballPosition> secondaryPositions = [
  FootballPosition(code: 'GK', name: 'Goalkeeper', icon: Icons.radio_button_checked),
  FootballPosition(code: 'CB', name: 'Centre-Back', icon: Icons.shield),
  FootballPosition(code: 'CDM', name: 'Def. Midfielder', icon: Icons.sync_alt),
  FootballPosition(code: 'CM', name: 'Central Mid', icon: Icons.sync_alt),
  FootballPosition(code: 'LW', name: 'Left Winger', icon: Icons.bolt),
  FootballPosition(code: 'RW', name: 'Right Winger', icon: Icons.bolt),
  FootballPosition(code: 'ST', name: 'Striker', icon: Icons.bolt),
  FootballPosition(code: 'CAM', name: 'Att. Midfielder', icon: Icons.bolt),
  FootballPosition(code: 'LM', name: 'Left Mid', icon: Icons.bolt),
  FootballPosition(code: 'RM', name: 'Right Mid', icon: Icons.bolt),
  FootballPosition(code: 'LB', name: 'Left-Back', icon: Icons.shield),
  FootballPosition(code: 'RB', name: 'Right-Back', icon: Icons.shield),
];

/// Position Selection Screen
class PositionSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;

  const PositionSelectionScreen({
    super.key,
    this.onSkip,
  });

  @override
  ConsumerState<PositionSelectionScreen> createState() => _PositionSelectionScreenState();
}

class _PositionSelectionScreenState extends ConsumerState<PositionSelectionScreen> {
  FootballPosition? _selectedPrimary;
  FootballPosition? _selectedSecondary;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_selectedPrimary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oops!',
            message: 'Please select your primary position',
            contentType: ContentType.failure,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appwriteService = ref.read(appwriteServiceProvider);

      // Update user position in database
      // We use the email as document ID since it's stored in the document
      // Actually we need to get the current user from Appwrite to get their ID
      final user = await appwriteService.getCurrentUser();

      if (user != null) {
        await appwriteService.updateUserPosition(
          rowId: user.$id,
          primaryPosition: _selectedPrimary!.code,
          secondaryPosition: _selectedSecondary?.code,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Perfect!',
              message: 'Your position has been saved',
              contentType: ContentType.success,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error',
              message: e.toString(),
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            // Header
            _buildHeader(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Editorial Header
                    _buildEditorialHeader(),

                    const SizedBox(height: 32),

                    // Primary Position Grid
                    _buildPrimaryPositionGrid(),

                    const SizedBox(height: 32),

                    // Secondary Position
                    _buildSecondaryPosition(),

                    const SizedBox(height: 32),

                    // Field Map
                    _buildFieldMap(),

                    const SizedBox(height: 150), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: widget.onSkip,
            icon: const Icon(
              Icons.arrow_back,
              color: MidnightPitchTheme.electricBlue,
            ),
          ),
          // Logo
          const Text(
            'FOOTHEROES',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              letterSpacing: 4,
              color: MidnightPitchTheme.primaryText,
            ),
          ),
          // Progress indicators
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.ghostBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.electricBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.ghostBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What position do you play?',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
            color: MidnightPitchTheme.primaryText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This shapes everything — your stats, your training, your comparisons.',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: MidnightPitchTheme.mutedText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryPositionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: primaryPositions.length,
      itemBuilder: (context, index) {
        final position = primaryPositions[index];
        final isSelected = _selectedPrimary?.code == position.code;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPrimary = position;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.1)
                  : MidnightPitchTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? MidnightPitchTheme.electricBlue
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        position.icon,
                        size: 28,
                        color: isSelected
                            ? MidnightPitchTheme.electricBlue
                            : MidnightPitchTheme.mutedText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        position.code,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: isSelected
                              ? MidnightPitchTheme.electricBlue
                              : MidnightPitchTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        position.name,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: MidnightPitchTheme.mutedText,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      size: 20,
                      color: MidnightPitchTheme.electricBlue,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryPosition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SECONDARY POSITION (OPTIONAL)',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: secondaryPositions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final position = secondaryPositions[index];
              final isSelected = _selectedSecondary?.code == position.code;
              final isPrimarySelected = _selectedPrimary?.code == position.code;

              return GestureDetector(
                onTap: () {
                  if (isPrimarySelected) return;
                  setState(() {
                    if (isSelected) {
                      _selectedSecondary = null;
                    } else {
                      _selectedSecondary = position;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        position.code,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isPrimarySelected
                              ? MidnightPitchTheme.mutedText
                              : MidnightPitchTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        position.name,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: MidnightPitchTheme.mutedText,
                          letterSpacing: 0.05,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: MidnightPitchTheme.surfaceContainerLow,
      ),
      child: Stack(
        children: [
          // Field image placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: MidnightPitchTheme.surfaceContainerLow,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedPrimary != null
                              ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.2)
                              : MidnightPitchTheme.mutedText.withValues(alpha: 0.2),
                          border: Border.all(
                            color: MidnightPitchTheme.electricBlue,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MidnightPitchTheme.electricBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPrimary != null
                            ? '${_selectedPrimary!.code} ZONE'
                            : 'SELECT POSITION',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: MidnightPitchTheme.electricBlue,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Top zone indicator
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 1,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ATTACKING THIRD',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 1,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          // Bottom zone indicator
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 1,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MIDFIELD ZONE',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 1,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceDim.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.surfaceContainerLowest.withValues(alpha: 0.4),
            offset: const Offset(0, -24),
            blurRadius: 48,
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: MidnightPitchTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.04,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
