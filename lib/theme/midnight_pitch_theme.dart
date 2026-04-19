import 'package:flutter/material.dart';

/// The FootHeroes Design System - Premium European Football
/// Light theme: Deep navy + electric blue + champagne gold on clean whites
class MidnightPitchTheme {
  MidnightPitchTheme._();

  // ============================================================
  // COLOR PALETTE - Premium European Football Identity
  // ============================================================

  // Primary - Deep Navy (Authority & Trust)
  static const Color deepNavy = Color(0xFF0D1B2A);        // primary text, dark elements
  static const Color premiumNavy = Color(0xFF1B263B);      // card headers, emphasis
  static const Color midnightBlue = Color(0xFF2D3E50);     // secondary dark

  // Accent - Electric Blue (Action & Energy)
  static const Color electricBlue = Color(0xFF0066FF);     // primary CTA, links
  static const Color electricBlueDark = Color(0xFF0052CC); // hover/pressed state
  static const Color electricBlueLight = Color(0xFF3385FF); // highlights

  // Achievement - Champagne Gold (Prestige & Champions)
  static const Color championGold = Color(0xFFC9A227);     // gold accents, elite badges
  static const Color championGoldLight = Color(0xFFE8C547); // gold highlights
  static const Color championGoldDark = Color(0xFFA88420); // gold pressed

  // Live Action - Crimson (Match Day Energy)
  static const Color liveRed = Color(0xFFDC2626);          // live indicators, errors
  static const Color liveRedDark = Color(0xFFB91C1C);      // error pressed
  static const Color liveRedLight = Color(0xFFEF4444);     // error light

  // Success - Emerald (Performance & Growth)
  static const Color successGreen = Color(0xFF059669);     // success states
  static const Color successGreenLight = Color(0xFF10B981); // success light

  // Text Colors - Clean Hierarchy
  static const Color primaryText = Color(0xFF0D1B2A);      // deep navy — primary text
  static const Color secondaryText = Color(0xFF374151);    // slate — secondary text
  static const Color mutedText = Color(0xFF6B7280);         // grey — muted/hint text

  // Surface Colors - Premium Whites
  static const Color surfaceDim = Color(0xFFF8F9FC);       // scaffold background (cool white)
  static const Color surfaceContainer = Color(0xFFFFFFFF);  // card surfaces (pure white)
  static const Color surfaceContainerLow = Color(0xFFF8F9FC);
  static const Color surfaceContainerHigh = Color(0xFFE5E7EB); // subtle dividers
  static const Color surfaceContainerHighest = Color(0xFF9CA3AF); // disabled, placeholders
  static const Color surfaceContainerLowest = Color(0xFFF1F3F8); // input backgrounds

  // Glass & Frosted
  static const Color glassWhite = Color(0x99FFFFFF);        // frosted glass overlay
  static const Color glassBorder = Color(0x33FFFFFF);       // glass border

  // Ghost Border
  static const Color ghostBorder = Color(0x1A0D1B2A);      // subtle navy border (10%)
  static const Color ghostBorderLight = Color(0x1A0066FF);  // subtle blue border (10%)

  // Aliases for backward compat
  static const Color electricMint = electricBlue;
  static const Color electricMintDark = electricBlueDark;
  static const Color electricMintLight = electricBlueLight;
  static const Color skyBlue = electricBlue;
  static const Color liveRedMuted = Color(0xFFDC2626);

  // ============================================================
  // GRADIENTS - Premium European Match Day
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlueLight, electricBlue, electricBlueDark],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [championGoldLight, championGold, championGoldDark],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [electricBlue, electricBlueDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, premiumNavy],
  );

  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceContainer.withValues(alpha: 0.85),
      surfaceContainer.withValues(alpha: 0.65),
    ],
  );

  // ============================================================
  // AMBIENT SHADOWS - Clean Premium Elevation
  // ============================================================

  static List<BoxShadow> get ambientShadow => [
    BoxShadow(
      color: const Color(0x0D0D1B2A),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x05000000),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0x0D0D1B2A),
      offset: const Offset(0, 2),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0x140D1B2A),
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: electricBlue.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // ============================================================
  // NEUMORPHIC TOKENS - Disabled (kept for legacy)
  // ============================================================

  static const Color neuBase = Color(0xFFE0E5EC);
  static const Color neuLight = Color(0xFFFFFFFF);
  static const Color neuDark = Color(0xFFA3B1C6);

  static List<BoxShadow> get neuRaised => [
    BoxShadow(color: neuLight, offset: const Offset(-6, -6), blurRadius: 12),
    BoxShadow(color: neuDark.withValues(alpha: 0.7), offset: const Offset(6, 6), blurRadius: 12),
  ];

  static List<BoxShadow> get neuPressed => [
    BoxShadow(color: neuDark.withValues(alpha: 0.5), offset: const Offset(-2, -2), blurRadius: 4),
    BoxShadow(color: neuLight.withValues(alpha: 0.7), offset: const Offset(2, 2), blurRadius: 4),
  ];

  // ============================================================
  // GLASS & CARD TOKENS - Premium Polish
  // ============================================================

  /// Frosted glass surface with subtle navy tint
  static BoxDecoration get glassSurface => BoxDecoration(
    color: surfaceContainer.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: glassBorder),
    boxShadow: [
      BoxShadow(
        color: deepNavy.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Premium card: clean white with subtle shadow
  static BoxDecoration get premiumCard => BoxDecoration(
    color: surfaceContainer,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: ghostBorder),
    boxShadow: cardShadow,
  );

  /// Performance card with accent border
  static BoxDecoration get performanceCard => BoxDecoration(
    color: surfaceContainer,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: ghostBorderLight.withValues(alpha: 0.5)),
  );

  static BoxDecoration get performanceCardInner => BoxDecoration(
    color: surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
  );

  /// Glass card with gradient overlay
  static BoxDecoration get glassCard => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaceContainer.withValues(alpha: 0.95),
        surfaceContainer.withValues(alpha: 0.85),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: glassBorder, width: 1.5),
    boxShadow: elevatedShadow,
  );

  /// Gold accent card for elite features
  static BoxDecoration get goldAccentCard => BoxDecoration(
    color: surfaceContainer,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: championGold.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(
        color: championGold.withValues(alpha: 0.1),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ============================================================
  // TYPOGRAPHY SCALE - Editorial Authority
  // ============================================================

  static const String fontFamily = 'Poppins';
  static const String headingFontFamily = 'BebasNeue';

  static TextStyle get displayLG => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w400,
    letterSpacing: 2,
    color: primaryText,
    height: 1.05,
  );

  static TextStyle get displayMD => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: primaryText,
    height: 1.05,
  );

  static TextStyle get titleLG => const TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    color: primaryText,
    height: 1.2,
  );

  static TextStyle get titleMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: primaryText,
    height: 1.3,
  );

  static TextStyle get labelSM => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.08,
    color: mutedText,
    height: 1.4,
  );

  static TextStyle get labelMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.04,
    color: secondaryText,
    height: 1.4,
  );

  static TextStyle get bodyMD => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: primaryText,
    height: 1.5,
  );

  static TextStyle get bodySM => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: mutedText,
    height: 1.5,
  );

  // ============================================================
  // BUTTON STYLES - Premium CTAs
  // ============================================================

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: electricBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.02,
    ),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24),
  );

  static Widget primaryButtonGradient({required Widget child, VoidCallback? onPressed, bool isFullWidth = true}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: child,
      ),
    );
  }

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: surfaceContainer,
    foregroundColor: electricBlue,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: electricBlue.withValues(alpha: 0.3), width: 1.5),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.02,
    ),
    elevation: 0,
  );

  static ButtonStyle get goldButton => ElevatedButton.styleFrom(
    backgroundColor: championGold,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.02,
    ),
    elevation: 0,
  );

  static ButtonStyle get tertiaryButton => TextButton.styleFrom(
    foregroundColor: electricBlue,
    minimumSize: const Size(double.infinity, 44),
    textStyle: labelMD.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.04,
    ),
  );

  static ButtonStyle get ghostButton => TextButton.styleFrom(
    foregroundColor: primaryText,
    minimumSize: const Size(double.infinity, 44),
    textStyle: labelMD.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );

  // ============================================================
  // CARD STYLES - Premium Cards (see GLASS & CARD TOKENS above)
  // Kept for backward compat
  // ============================================================

  // ============================================================
  // PROGRESS BAR - Performance Journey
  // ============================================================

  static BoxDecoration get progressTrack => BoxDecoration(
    color: surfaceContainerHigh,
    borderRadius: BorderRadius.circular(6),
  );

  static BoxDecoration progressFill(double progress) => BoxDecoration(
    gradient: progressGradient,
    borderRadius: BorderRadius.circular(6),
  );

  static BoxDecoration goldProgressFill(double progress) => BoxDecoration(
    gradient: goldGradient,
    borderRadius: BorderRadius.circular(6),
  );

  // ============================================================
  // BOTTOM NAVIGATION - The Navigation Bar
  // ============================================================

  static NavigationBarThemeData get bottomNavigation => NavigationBarThemeData(
    backgroundColor: surfaceContainer,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 72,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return labelMD.copyWith(color: electricBlue, fontWeight: FontWeight.w600);
      }
      return labelMD.copyWith(color: mutedText);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: electricBlue, size: 24);
      }
      return const IconThemeData(color: mutedText, size: 24);
    }),
  );

  // ============================================================
  // COMPONENT BUILDERS
  // ============================================================

  static Widget sectionLabel(String text, {Color? color}) {
    return Text(
      text.toUpperCase(),
      style: labelSM.copyWith(color: color),
    );
  }

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

  static Widget glassCardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: glassCard,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  static Widget performanceCardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: performanceCard,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }

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

  static Widget navIndicator({bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 0,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: electricBlue,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================================
  // THEME DATA - Material 3 Theme (Light)
  // ============================================================

  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: surfaceDim,
    colorScheme: const ColorScheme.light(
      primary: electricBlue,
      onPrimary: Colors.white,
      primaryContainer: electricBlueDark,
      onPrimaryContainer: electricBlueLight,
      secondary: championGold,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFF8E7),
      onSecondaryContainer: championGoldDark,
      tertiary: premiumNavy,
      onTertiary: Colors.white,
      tertiaryContainer: midnightBlue,
      onTertiaryContainer: Colors.white,
      error: liveRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: liveRedDark,
      surface: surfaceContainer,
      onSurface: primaryText,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: ghostBorder,
      outlineVariant: surfaceContainerHigh,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDim,
      foregroundColor: primaryText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: titleLG,
    ),
    cardTheme: CardThemeData(
      color: surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ghostBorder, width: 1),
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
      backgroundColor: surfaceContainer,
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