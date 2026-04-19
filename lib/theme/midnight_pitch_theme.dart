import 'package:flutter/material.dart';

/// The FootHeroes Design System
/// A light, professional design with mahogany red accents on white backgrounds
class MidnightPitchTheme {
  MidnightPitchTheme._();

  // ============================================================
  // COLOR PALETTE - The FootHeroes Identity
  // ============================================================

  // Primary Actions - Mahogany Red (Active Zone)
  static const Color electricMint = Color(0xFFBA181B);       // primary accent (was mint, now mahogany red)
  static const Color electricMintDark = Color(0xFFA4161A);  // dark variant (mahogany red dark)
  static const Color electricMintLight = Color(0xFFE5383B); // bright variant (strawberry red)

  // Secondary - Dark Garnet (Technical Data)
  static const Color skyBlue = Color(0xFFBA181B);           // secondary accent (mahogany red)

  // Achievement - Dark Garnet (Elite Performance)
  static const Color championGold = Color(0xFF660708);       // deep accent (dark garnet)

  // Danger - Mahogany Red (Alerts & Warnings)
  static const Color liveRed = Color(0xFFBA181B);            // error/danger (mahogany red)

  // Text Colors
  static const Color primaryText = Color(0xFF0B090A);        // black — primary text on light
  static const Color secondaryText = Color(0xFF161A1D);      // carbon black — secondary text
  static const Color mutedText = Color(0xFF555555);           // dark grey — muted/hint text (WCAG 7:1 on white)

  // Surface Colors - The Light Pitch
  static const Color surfaceDim = Color(0xFFF5F3F4);         // scaffold background (white smoke)
  static const Color surfaceContainer = Color(0xFFFFFFFF);    // card surfaces (white)
  static const Color surfaceContainerLow = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFD3D3D3);   // subtle surfaces (dust grey)
  static const Color surfaceContainerHighest = Color(0xFFB1A7A6); // borders/disabled (silver)
  static const Color surfaceContainerLowest = Color(0xFFD3D3D3);  // deepest surface variant (dust grey)

  // Ghost Border (40% opacity of silver)
  static const Color ghostBorder = Color(0x66B1A7A6);

  // ============================================================
  // GRADIENTS - The Floodlight Effect
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricMintLight, electricMintDark],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [electricMint, electricMintDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceContainer.withValues(alpha: 0.85),
      surfaceContainer.withValues(alpha: 0.7),
    ],
  );

  // ============================================================
  // AMBIENT SHADOWS - Natural Light Dissipation
  // ============================================================

  static List<BoxShadow> get ambientShadow => [
    BoxShadow(
      color: const Color(0x1A000000),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -2,
    ),
  ];

  // ============================================================
  // NEUMORPHIC SHADOW TOKENS - Light Soft UI
  // ============================================================
  // Cool clay base with dual white/dark shadows.
  // Light source: top-left. Raised = extruded, Pressed = concave.

  static const Color neuBase = Color(0xFFE0E5EC);       // cool clay gray base
  static const Color neuLight = Color(0xFFFFFFFF);       // highlight (top-left, white)
  static const Color neuDark = Color(0xFFA3B1C6);        // shadow (bottom-right, blue-gray)

  /// Raised state: extruded outward (default resting state)
  static List<BoxShadow> get neuRaised => [
    BoxShadow(color: neuLight, offset: const Offset(-6, -6), blurRadius: 12),
    BoxShadow(color: neuDark.withValues(alpha: 0.7), offset: const Offset(6, 6), blurRadius: 12),
  ];

  /// Pressed state: concave inward (active/pressed state)
  static List<BoxShadow> get neuPressed => [
    BoxShadow(color: neuDark.withValues(alpha: 0.5), offset: const Offset(-2, -2), blurRadius: 4),
    BoxShadow(color: neuLight.withValues(alpha: 0.7), offset: const Offset(2, 2), blurRadius: 4),
  ];

  // ============================================================
  // GLASSMORPHISM TOKENS
  // ============================================================

  /// Frosted glass surface for BackdropFilter containers
  static BoxDecoration get glassSurface => BoxDecoration(
    color: surfaceContainer.withValues(alpha: 0.20),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Color(0xFFFFFFFF).withValues(alpha: 0.35)),
  );

  /// Neumorphic card: raised base with soft dual shadow
  static BoxDecoration get neuCard => BoxDecoration(
    color: neuBase,
    borderRadius: BorderRadius.circular(20),
    boxShadow: neuRaised,
  );

  /// Neumorphic button: raised with tighter radius
  static BoxDecoration get neuButton => BoxDecoration(
    color: neuBase,
    borderRadius: BorderRadius.circular(14),
    boxShadow: neuRaised,
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
  // BUTTON STYLES - The Call to Action
  // ============================================================

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: electricMint,
    foregroundColor: surfaceContainer,
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
          foregroundColor: surfaceContainer,
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

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: surfaceContainerHigh,
    foregroundColor: electricMint,
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

  static ButtonStyle get tertiaryButton => TextButton.styleFrom(
    foregroundColor: electricMint,
    minimumSize: const Size(double.infinity, 44),
    textStyle: labelMD.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.04,
    ),
  );

  // ============================================================
  // CARD STYLES - Performance Cards
  // ============================================================

  static BoxDecoration get performanceCard => BoxDecoration(
    color: surfaceContainer,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: ghostBorder, width: 1),
  );

  static BoxDecoration get performanceCardInner => BoxDecoration(
    color: surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration get glassCard => BoxDecoration(
    color: surfaceContainer.withValues(alpha: 0.75),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Color(0x40FFFFFF)),
    boxShadow: ambientShadow,
  );

  // ============================================================
  // PROGRESS BAR - The Journey from Skill to Flow
  // ============================================================

  static BoxDecoration get progressTrack => BoxDecoration(
    color: surfaceContainerHigh,
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
    backgroundColor: surfaceContainer,
    indicatorColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 72,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return labelMD.copyWith(color: electricMint, fontWeight: FontWeight.w600);
      }
      return labelMD.copyWith(color: mutedText);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: electricMint, size: 24);
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
        color: electricMint,
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
      primary: electricMint,
      onPrimary: surfaceContainer,
      primaryContainer: electricMintDark,
      onPrimaryContainer: electricMintLight,
      secondary: championGold,
      onSecondary: surfaceContainer,
      secondaryContainer: Color(0xFFD3D3D3),
      onSecondaryContainer: Color(0xFF161A1D),
      tertiary: championGold,
      onTertiary: surfaceContainer,
      tertiaryContainer: Color(0xFF660708),
      onTertiaryContainer: Color(0xFFE5383B),
      error: liveRed,
      onError: surfaceContainer,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: surfaceContainer,
      onSurface: primaryText,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: ghostBorder,
      outlineVariant: Color(0xFFD3D3D3),
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