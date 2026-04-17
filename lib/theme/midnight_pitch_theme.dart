import 'package:flutter/material.dart';

/// The Midnight Pitch Design System
/// A cinematic, stadium-inspired design for high-stakes performance apps
class MidnightPitchTheme {
  MidnightPitchTheme._();

  // ============================================================
  // COLOR PALETTE - The Stadium Atmosphere
  // ============================================================

  // Primary Actions - Electric Mint (Active Zone)
  static const Color electricMint = Color(0xFF00E5A0);
  static const Color electricMintDark = Color(0xFF006141);
  static const Color electricMintLight = Color(0xFF47FFB8);

  // Secondary - Sky Blue (Technical Data)
  static const Color skyBlue = Color(0xFF00BFFF);

  // Achievement - Champion Gold (Elite Performance)
  static const Color championGold = Color(0xFFFFD166);

  // Danger - Live Red (Alerts & Warnings)
  static const Color liveRed = Color(0xFFFF4D6D);

  // Text Colors
  static const Color primaryText = Color(0xFFF0F4F8);
  static const Color secondaryText = Color(0xFFB0BEC5);
  static const Color mutedText = Color(0xFF4A6080);

  // Surface Colors - The Layered Pitch
  static const Color surfaceDim = Color(0xFF071325);        // Base Layer - The Pitch at night
  static const Color surfaceContainer = Color(0xFF142032);   // Section Layer
  static const Color surfaceContainerLow = Color(0xFF101C2E);
  static const Color surfaceContainerHigh = Color(0xFF1F2A3D);
  static const Color surfaceContainerHighest = Color(0xFF2A3548);
  static const Color surfaceContainerLowest = Color(0xFF030E20);

  // Ghost Border (15% opacity of outline-variant)
  static const Color ghostBorder = Color(0x263B4A41);

  // ============================================================
  // GRADIENTS - The Floodlight Effect
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricMint, electricMintDark],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [electricMint, skyBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceContainer.withValues(alpha: 0.7),
      surfaceContainer.withValues(alpha: 0.5),
    ],
  );

  // ============================================================
  // AMBIENT SHADOWS - Natural Light Dissipation
  // ============================================================

  static List<BoxShadow> get ambientShadow => [
    BoxShadow(
      color: const Color(0x66030E20),
      offset: const Offset(0, 24),
      blurRadius: 48,
      spreadRadius: -4,
    ),
  ];

  // ============================================================
  // TYPOGRAPHY SCALE - Editorial Authority
  // ============================================================

  static const String fontFamily = 'Inter';

  // Hero Stats - Display-LG (48-56px, Weight 800, Tracking -2px)
  static TextStyle get displayLG => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    color: primaryText,
    height: 1.1,
  );

  // Hero Stats Secondary
  static TextStyle get displayMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: primaryText,
    height: 1.1,
  );

  // Titles - Title-LG (22px, Weight 700, Tracking -0.02em)
  static TextStyle get titleLG => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44,
    color: primaryText,
    height: 1.3,
  );

  // Titles - Title-MD
  static TextStyle get titleMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: primaryText,
    height: 1.3,
  );

  // Section Labels - Label-SM (11px, Weight 500, Uppercase, Tracking 0.08em)
  static TextStyle get labelSM => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.08,
    color: mutedText,
    height: 1.4,
  );

  // Labels - Label-MD
  static TextStyle get labelMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.04,
    color: secondaryText,
    height: 1.4,
  );

  // Body - Body-MD (14px, Weight 400, Leading 1.5)
  static TextStyle get bodyMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: secondaryText,
    height: 1.5,
  );

  // Body Small
  static TextStyle get bodySM => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: mutedText,
    height: 1.5,
  );

  // ============================================================
  // BUTTON STYLES - The Call to Action
  // ============================================================

  // Primary Button (52px height, 14px radius, Gradient fill)
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: electricMint,
    foregroundColor: surfaceDim,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    elevation: 0,
  );

  // Primary Button with Gradient
  static Widget primaryButtonGradient({required Widget child, VoidCallback? onPressed}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: surfaceDim,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }

  // Secondary Button (52px height, 14px radius, Surface-container-high background)
  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: surfaceContainerHigh,
    foregroundColor: electricMintLight,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    elevation: 0,
  );

  // Tertiary Button (Ghost style, uppercase label-md)
  static ButtonStyle get tertiaryButton => TextButton.styleFrom(
    foregroundColor: electricMintLight,
    minimumSize: const Size(double.infinity, 44),
    textStyle: labelMD.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.04,
    ),
  );

  // ============================================================
  // CARD STYLES - Performance Cards
  // ============================================================

  // Base Performance Card
  static BoxDecoration get performanceCard => BoxDecoration(
    color: surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
  );

  // Elevated Performance Card (for nested elements)
  static BoxDecoration get performanceCardInner => BoxDecoration(
    color: surfaceContainerLowest,
    borderRadius: BorderRadius.circular(12),
  );

  // Glass Card (for floating elements)
  static BoxDecoration get glassCard => BoxDecoration(
    color: surfaceContainer.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(20),
    boxShadow: ambientShadow,
  );

  // ============================================================
  // PROGRESS BAR - The Journey from Skill to Flow
  // ============================================================

  static BoxDecoration get progressTrack => BoxDecoration(
    color: surfaceContainerHighest,
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration progressFill(double progress) => BoxDecoration(
    gradient: progressGradient,
    borderRadius: BorderRadius.circular(8),
  );

  // ============================================================
  // BOTTOM NAVIGATION - The Navigation Bar
  // ============================================================

  static NavigationBarThemeData get bottomNavigation => NavigationBarThemeData(
    backgroundColor: surfaceContainerLowest,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 72,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return labelMD.copyWith(color: primaryText, fontWeight: FontWeight.w600);
      }
      return labelMD.copyWith(color: mutedText);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: primaryText, size: 24);
      }
      return const IconThemeData(color: mutedText, size: 24);
    }),
  );

  // ============================================================
  // COMPONENT BUILDERS
  // ============================================================

  /// Create a section label (uppercase, wide tracking)
  static Widget sectionLabel(String text, {Color? color}) {
    return Text(
      text.toUpperCase(),
      style: labelSM.copyWith(color: color),
    );
  }

  /// Create a hero stat display
  static Widget heroStat(String value, String label, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: displayLG.copyWith(color: valueColor ?? primaryText),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: labelSM,
        ),
      ],
    );
  }

  /// Create a progress bar with gradient fill
  static Widget progressBar(double progress, {double height = 8}) {
    return Container(
      height: height,
      decoration: progressTrack,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: progressFill(progress),
        ),
      ),
    );
  }

  /// Create a glass card container
  static Widget glassCardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: glassCard,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  /// Create a performance card container
  static Widget performanceCardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: performanceCard,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }

  /// Create a stat row with label and value
  static Widget statRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bodyMD),
        Text(
          value,
          style: titleMD.copyWith(color: valueColor ?? primaryText),
        ),
      ],
    );
  }

  /// Create a bottom nav indicator bar
  static Widget navIndicator({bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 0,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: electricMint,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================================
  // THEME DATA - Material 3 Theme
  // ============================================================

  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: surfaceDim,
    colorScheme: const ColorScheme.dark(
      primary: electricMint,
      onPrimary: surfaceDim,
      primaryContainer: electricMintDark,
      onPrimaryContainer: electricMintLight,
      secondary: skyBlue,
      onSecondary: surfaceDim,
      secondaryContainer: Color(0xFF003D5C),
      onSecondaryContainer: Color(0xFF87CEEB),
      tertiary: championGold,
      onTertiary: surfaceDim,
      tertiaryContainer: Color(0xFF5C4400),
      onTertiaryContainer: championGold,
      error: liveRed,
      onError: surfaceDim,
      errorContainer: Color(0xFF5C1A2A),
      onErrorContainer: liveRed,
      surface: surfaceContainer,
      onSurface: primaryText,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: ghostBorder,
      outlineVariant: Color(0xFF3B4A41),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDim,
      foregroundColor: primaryText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: titleLG,
    ),
    cardTheme: CardThemeData(
      color: surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButton,
    ),
    textButtonTheme: TextButtonThemeData(
      style: tertiaryButton,
    ),
    navigationBarTheme: bottomNavigation,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceContainerHigh,
      contentTextStyle: bodyMD.copyWith(color: primaryText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ghostBorder,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: displayLG,
      displayMedium: displayMD,
      titleLarge: titleLG,
      titleMedium: titleMD,
      labelSmall: labelSM,
      labelMedium: labelMD,
      bodyMedium: bodyMD,
      bodySmall: bodySM,
    ),
  );
}