import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FootHeroes App Theme — UCL-inspired Typography System
///
/// Display: Chakra Petch (geometric, athletic, UCL feel) for headlines, scores, stats.
/// Body: Outfit (clean, modern) for labels, body, UI text.
/// Accent: Bebas Neue (local file) for uppercase athletic labels.
///
/// Overflow-safe sizes: display scaled down ~15–20% to prevent RenderFlex.
/// 9 Type Scales: T1–T9
/// Letter Spacing Rule: Labels wide (+1.0–+1.5px), Numbers tight (-1.0–-1.2px), Body 0px
class AppTheme {
  AppTheme._();

  // ============================================================
  // FONT
  // ============================================================
  static const String fontFamily = 'Outfit';

  // Backward-compat aliases
  static const String displayFontFamily = 'BebasNeue';

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? parchment,
      letterSpacing: letterSpacing ?? 0,
      height: height,
    );
  }

  static TextStyle _bebas({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'BebasNeue',
      fontSize: fontSize,
      color: color ?? parchment,
      letterSpacing: letterSpacing ?? 0.5,
      height: height,
    );
  }

  /// UCL-style geometric display — Chakra Petch for headlines, scores, stats
  static TextStyle _display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.chakraPetch(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? parchment,
      letterSpacing: letterSpacing ?? 0,
      height: height,
    );
  }

  // ============================================================
  // LAYER 1 — BACKGROUND SURFACE (Warm Page Gradient)
  // ============================================================
  static const Color voidBg = Color(0xFFFFFCF8);
  static const Color pageGradientEnd = Color(0xFFFFF9F2);

  // ============================================================
  // LAYER 2 — BRAND ACCENTS
  // ============================================================
  static const Color brandOrange = Color(0xFFE65100);
  static const Color brandOrangeLight = Color(0xFFFF8F00);
  static const Color warmDark = Color(0xFF1C0A00);
  static const Color deepRed = Color(0xFFB71C1C);
  static const Color drawMuted = Color(0xFF2D1205);
  static const Color drawMutedText = Color(0xFF6D3A25);
  static const Color glassWhite = Color(0xD9FFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF9FBFC);

  // Legacy aliases
  static const Color cardinal = brandOrange;
  static const Color redMid = brandOrange;
  static const Color redDeep = warmDark;
  static const Color navy = warmDark;
  static const Color blueMid = warmDark;

  // ============================================================
  // LAYER 3 — TYPOGRAPHY COLORS
  // ============================================================
  static const Color parchment = Color(0xFF1C0A00);
  static const Color bodyText = Color(0xFF1C0A00);
  static const Color beige = Color(0xFF1C0A00);
  static const Color warmGrey = Color(0xFFC4A882);
  static const Color mutedParchment = warmGrey;
  static const Color gold = warmGrey;
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white45 = Color(0x73FFFFFF);

  // ============================================================
  // SYSTEM COLORS
  // ============================================================
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color sparkBlue = Color(0xFF3B82F6);
  static const Color sparkViolet = Color(0xFF6366F1);
  static const Color sparkLight = Color(0xFFF9FAFB);
  static const Color sparkIce = Color(0xFFF3F4F6);
  static const Color sparkCyber = Color(0xFF374151);
  static const Color feedbackError = Color(0xFFDC2626);
  static const Color accentIndigo = Color(0xFF4F46E5);
  static const Color accentCyan = Color(0xFF0891B2);
  static const Color rose = Color(0xFFFFF3E0);
  static const Color roseLight = Color(0xFFFFE0B2);
  static const Color emptyIconBorder = Color(0xFFFFCC80);

  // ============================================================
  // BORDER SYSTEM
  // ============================================================
  static const Color cardBorderColor = Color(0x1A000000);
  static const Color cardBorderColorLight = Color(0x0F000000);
  static const Color cardBorderColorVeryLight = Color(0x0A000000);
  static const Color dividerColor = Color(0xFFF3F4F6);
  static const Color cardBorderColorAlt = brandOrange;
  static const Color cardBorderColorMuted = Color(0xFFE5E7EB);
  static const Color cardBorderColorFaint = Color(0xFFF9FAFB);

  // ============================================================
  // TYPE SCALE T1–T9 (FootHeroes Spec)
  // ============================================================

  /// T1 — GREETING DISPLAY
  /// 24px · 700 Bold · -1px tracking · Chakra Petch
  static TextStyle get t1Greeting => _display(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: parchment,
    letterSpacing: -1.0,
  );

  /// T2 — HERO STAT NUMBER
  /// 24px · 700 Bold · -1px tracking · Chakra Petch
  static TextStyle get t2HeroStat => _display(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -1.0,
    height: 1.0,
  );

  /// T3 — PLAYER NAME
  /// 22px · 700 Bold · -0.8px tracking · Chakra Petch
  static TextStyle get t3PlayerName => _display(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.8,
  );

  /// T4 — CARD STAT NUMBER
  /// 28px · 700 Bold · -1.2px tracking · Chakra Petch
  static TextStyle get t4CardNumber => _display(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: brandOrange,
    letterSpacing: -1.2,
    height: 1.0,
  );

  /// T5 — ACCENT CARD NUMBER
  /// 28px · 700 Bold · -1.2px tracking · Chakra Petch (white on orange)
  static TextStyle get t5AccentNumber => _display(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -1.2,
    height: 1.0,
  );

  /// T6 — BREAKDOWN STAT
  /// 16px · 700 Bold · -0.2px tracking · Chakra Petch
  static TextStyle get t6Breakdown => _display(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: parchment,
    letterSpacing: -0.2,
    height: 1.0,
  );

  /// T7 — CARD TITLE
  /// 13px · 800 ExtraBold · -0.3px tracking
  static TextStyle get t7CardTitle => _inter(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: parchment,
    letterSpacing: -0.3,
  );

  /// T8 — TREND / SUB TEXT
  /// 10px · 600 SemiBold · 0px tracking
  static TextStyle get t8Trend => _inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: brandOrangeLight,
  );

  /// T9 — CARD LABEL (MOST USED)
  /// 9px · 700 Bold · +1.2px tracking · UPPERCASE
  static TextStyle get t9Label => _inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: warmGrey,
    letterSpacing: 1.2,
  );

  // ============================================================
  // LEGACY / CONVENIENCE GETTERS
  // ============================================================

  /// Base Inter style (Medium · 500)
  static TextStyle get dmSans => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: parchment,
    letterSpacing: 0,
  );

  /// Display Bebas Neue style
  static TextStyle get bebasDisplay => _bebas(
    fontSize: 18,
    color: parchment,
    letterSpacing: 0.5,
  );

  /// Card label — maps to T9
  static TextStyle get cardLabel => t9Label;

  /// Card number — maps to T4
  static TextStyle get cardNumber => t4CardNumber;

  /// Card trend — maps to T8
  static TextStyle get cardTrend => t8Trend;

  /// Hero name — maps to T3
  static TextStyle get heroName => t3PlayerName;

  /// Hero meta — 11px · 500 · white 60%
  static TextStyle get heroMeta => _inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: white60,
    letterSpacing: 0,
  );

  /// Hero stat — maps to T2
  static TextStyle get heroStat => t2HeroStat;

  /// Hero stat label — 8px · 700 · white 45% · +1px
  static TextStyle get heroStatLabel => _inter(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: white45,
    letterSpacing: 1.0,
  );

  /// Hero label (section header on dark) — 9px · 700 · white 45% · +1.5px
  static TextStyle get heroLabel => _inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: white45,
    letterSpacing: 1.5,
  );

  /// Stat number — large display number
  static TextStyle get statNumber => _display(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: parchment,
    letterSpacing: -1.2,
    height: 1.0,
  );

  /// Score large — large match score
  static TextStyle get scoreLarge => _display(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: parchment,
    letterSpacing: -1.2,
    height: 1.0,
  );

  /// Rating badge
  static TextStyle get ratingBadge => _inter(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: parchment,
    letterSpacing: -0.5,
  );

  /// Body regular — 15px · 500
  static TextStyle get bodyReg => _inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: bodyText,
  );

  /// Body bold — 15px · 600
  static TextStyle get bodyBold => _inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: parchment,
  );

  /// Label small — 12px · 700
  static TextStyle get labelSmall => _inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: warmGrey,
    letterSpacing: 0.8,
  );

  /// Section header — maps to T7
  static TextStyle get sectionHeader => t7CardTitle;

  /// Gold display
  static TextStyle get goldDisplay => _inter(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: parchment,
    letterSpacing: -0.5,
  );

  /// Gold bold
  static TextStyle get goldBold => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: parchment,
  );

  // — On-gradient variants (always white) —
  static TextStyle get bebasDisplayOnGradient => bebasDisplay.copyWith(color: Colors.white);
  static TextStyle get dmSansOnGradient => dmSans.copyWith(color: Colors.white);
  static TextStyle get bodyBoldOnGradient => bodyBold.copyWith(color: Colors.white);
  static TextStyle get labelSmallOnGradient => labelSmall.copyWith(color: Colors.white);
  static TextStyle get statNumberOnGradient => statNumber.copyWith(color: Colors.white);

  // ============================================================
  // SPACING SYSTEM
  // ============================================================
  static const double screenPadding = 14.0;
  static const double cardGap = 11.0;
  static const double cardPadding = 16.0;
  static const double heroPadding = 20.0;
  static const double colGap = 10.0;
  static const double elementGap = 8.0;
  static const double chipGap = 8.0;

  static const double cardRadius = 20.0;
  static const double heroRadius = 26.0;
  static const double buttonRadius = 14.0;
  static const double smallElementRadius = 10.0;
  static const double pillRadius = 999.0;
  static const double statBoxRadius = 20.0;
  static const double positionBadgeRadius = 10.0;

  // ============================================================
  // GRADIENTS
  // ============================================================
  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [voidBg, pageGradientEnd],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandOrange, brandOrangeLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFBF360C),
      Color(0xFFE65100),
      Color(0xFFF57C00),
      Color(0xFFFF8F00),
    ],
  );

  static const LinearGradient accentCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrange, brandOrangeLight],
  );

  static const LinearGradient emptyIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rose, roseLight],
  );

  static const LinearGradient cardSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFC)],
  );

  static const LinearGradient awayDataGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmDark, Color(0xFF2D1205)],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepRed, Color(0xFFE53935)],
  );

  static const LinearGradient heroCtaGradient = brandGradient;
  static const LinearGradient verticalPillGradient = brandGradient;
  static const LinearGradient appBarAccentGradient = brandGradient;

  // ============================================================
  // SHADOWS
  // ============================================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFFE65100).withAlpha(10),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFFE65100).withAlpha(15),
      blurRadius: 30,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get ctaGlow => [
    BoxShadow(
      color: brandOrange.withAlpha(77),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(10),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ============================================================
  // CARD RECIPES
  // ============================================================
  static BoxDecoration heroRingDecoration(double size, double opacity) {
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withAlpha((opacity * 255).round()),
        width: 1.5,
      ),
    );
  }

  static const Color winBadge = brandOrange;
  static const Color drawBadge = drawMuted;
  static const Color drawBadgeText = drawMutedText;
  static const Color lossBadge = deepRed;

  // ============================================================
  // LIGHT THEME
  // ============================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: voidBg,

      colorScheme: const ColorScheme.light(
        primary: brandOrange,
        onPrimary: Colors.white,
        secondary: brandOrangeLight,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: warmDark,
        error: deepRed,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withAlpha(230),
        foregroundColor: warmDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: warmDark,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: cardBorderColor, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      textTheme: TextTheme(
        displayLarge: _display(fontSize: 48, fontWeight: FontWeight.w700, color: warmDark),
        displayMedium: _display(fontSize: 40, fontWeight: FontWeight.w700, color: warmDark),
        displaySmall: _display(fontSize: 32, fontWeight: FontWeight.w700, color: warmDark),
        headlineLarge: _display(fontSize: 28, fontWeight: FontWeight.w700, color: warmDark),
        headlineMedium: _display(fontSize: 24, fontWeight: FontWeight.w700, color: warmDark),
        headlineSmall: _display(fontSize: 22, fontWeight: FontWeight.w700, color: warmDark),
        titleLarge: _inter(fontSize: 20, fontWeight: FontWeight.w700, color: warmDark),
        titleMedium: _inter(fontSize: 16, fontWeight: FontWeight.w600, color: warmDark),
        titleSmall: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: warmDark),
        bodyLarge: _inter(fontSize: 16, fontWeight: FontWeight.w500, color: warmDark),
        bodyMedium: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: bodyText),
        bodySmall: _inter(fontSize: 12, fontWeight: FontWeight.w500, color: bodyText),
        labelLarge: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: warmDark),
        labelMedium: _inter(fontSize: 12, fontWeight: FontWeight.w500, color: warmGrey),
        labelSmall: _inter(fontSize: 11, fontWeight: FontWeight.w500, color: warmGrey),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: cardBorderColorMuted, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: cardBorderColorMuted, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: brandOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: deepRed, width: 1),
        ),
        labelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: warmGrey),
        hintStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: warmGrey),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: warmDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          side: const BorderSide(color: cardBorderColorMuted, width: 0.5),
          textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandOrange,
          textStyle: _inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: sparkIce,
        labelStyle: _inter(fontSize: 12, fontWeight: FontWeight.w500, color: warmDark),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        side: BorderSide.none,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brandOrange,
        unselectedItemColor: warmGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 0,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: brandOrange,
        unselectedLabelColor: warmGrey,
        indicatorColor: brandOrange,
        dividerColor: Colors.transparent,
        labelStyle: _inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: _inter(fontSize: 13, fontWeight: FontWeight.w500),
        tabAlignment: TabAlignment.fill,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: cardBorderColor, width: 0.5),
        ),
        titleTextStyle: _inter(fontSize: 18, fontWeight: FontWeight.w700, color: warmDark),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: warmDark,
        contentTextStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: warmDark,

      colorScheme: const ColorScheme.dark(
        primary: brandOrange,
        onPrimary: Colors.white,
        secondary: brandOrangeLight,
        onSecondary: Colors.white,
        surface: Color(0xFF2D1205),
        onSurface: Colors.white,
        error: deepRed,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: warmDark.withAlpha(230),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF2D1205),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.white.withAlpha(15), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      textTheme: TextTheme(
        displayLarge: _display(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white),
        displayMedium: _display(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white),
        displaySmall: _display(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        headlineLarge: _display(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: _display(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        headlineSmall: _display(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: _inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: _inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleSmall: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: _inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xCCFFFFFF)),
        bodySmall: _inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0x99FFFFFF)),
        labelLarge: _inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: _inter(fontSize: 12, fontWeight: FontWeight.w500, color: warmGrey),
        labelSmall: _inter(fontSize: 11, fontWeight: FontWeight.w500, color: warmGrey),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D1205),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: brandOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: deepRed, width: 1),
        ),
        labelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: warmGrey),
        hintStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: warmGrey),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2D1205),
        selectedItemColor: brandOrange,
        unselectedItemColor: warmGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(15),
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  // ============================================================
  // BACKWARD-COMPAT ALIASES & UTILITIES
  // ============================================================

  static const Color abyss = Color(0xFFEBF4F5);
  static const Color navyEnd = Color(0xFFF1F5F9);
  static const Color brandGold = brandOrangeLight;
  static const double roleCardRadius = 14.0;

  static Border get cardBorder => Border.all(color: cardBorderColor, width: 1.0);
  static Border get cardBorderLight => Border.all(color: cardBorderColorLight, width: 1.0);
  static Border get cardBorderVeryLight => Border.all(color: cardBorderColorVeryLight, width: 1.0);
  static Border get cardBorderAlt => Border.all(color: cardBorderColorAlt, width: 1.0);
  static Border get cardBorderMuted => Border.all(color: cardBorderColorMuted, width: 1.0);

  static BoxDecoration get standardCard => BoxDecoration(
    color: glassWhite,
    borderRadius: BorderRadius.circular(cardRadius),
    border: cardBorder,
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    gradient: cardSurfaceGradient,
    borderRadius: BorderRadius.circular(cardRadius),
    border: cardBorder,
    boxShadow: subtleShadow,
  );

  static BoxDecoration get statBoxDecoration => BoxDecoration(
    color: glassWhite,
    borderRadius: BorderRadius.circular(statBoxRadius),
    border: cardBorderLight,
  );

  static BoxDecoration get secondaryRowDecoration => BoxDecoration(
    color: sparkIce,
    borderRadius: BorderRadius.circular(smallElementRadius),
  );

  static BoxDecoration get radialGlowOverlay => BoxDecoration(
    gradient: const RadialGradient(
      center: Alignment.topRight,
      radius: 0.8,
      colors: [
        Color(0x0DE65100),
        Colors.transparent,
      ],
    ),
  );

  static List<BoxShadow> get heroCtaShadow => [
    BoxShadow(color: brandOrange.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get badgeShadow => [
    BoxShadow(color: brandOrange.withAlpha(30), blurRadius: 10),
  ];
  static List<BoxShadow> get formBadgeShadow => [
    BoxShadow(color: brandOrange.withAlpha(25), blurRadius: 8),
  ];
  static List<BoxShadow> get navPillShadow => [
    BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 14, offset: const Offset(0, -3)),
  ];
  static List<BoxShadow> get shieldShadow => [
    BoxShadow(color: brandOrange.withAlpha(20), blurRadius: 16),
  ];
  static List<BoxShadow> get shieldShadowLarge => [
    BoxShadow(color: brandOrange.withAlpha(20), blurRadius: 20),
  ];
  static List<BoxShadow> get awayShieldShadow => [
    BoxShadow(color: warmDark.withAlpha(20), blurRadius: 20),
  ];
  static List<BoxShadow> get motmBadgeShadow => [
    BoxShadow(color: brandOrange.withAlpha(30), blurRadius: 8),
  ];
  static List<BoxShadow> get bellIconShadow => [
    BoxShadow(color: brandOrange.withAlpha(25), blurRadius: 12),
  ];
  static List<BoxShadow> get playerCircleShadowHome => [
    BoxShadow(color: brandOrange.withAlpha(30), blurRadius: 12, offset: const Offset(0, 3)),
  ];
  static List<BoxShadow> get playerCircleShadowAway => [
    BoxShadow(color: warmDark.withAlpha(20), blurRadius: 12, offset: const Offset(0, 3)),
  ];
  static List<BoxShadow> get premiumCardShadow => [
    BoxShadow(color: brandOrange.withAlpha(20), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static Widget accentBar() => Container(
    height: 3,
    decoration: BoxDecoration(
      gradient: brandGradient,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  static Widget sectionLabel(String text) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          gradient: brandGradient,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(text, style: sectionHeader),
    ],
  );

  static Widget gradientText(String text, TextStyle style, {LinearGradient? gradient}) {
    return ShaderMask(
      shaderCallback: (bounds) => (gradient ?? brandGradient).createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: brandOrange,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
    textStyle: _inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
  );

  static InputDecoration inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: _inter(fontSize: 14, fontWeight: FontWeight.w500, color: warmGrey),
    );
  }

  static ThemeData get themeData => lightTheme;
}
