import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FootHeroes App Theme — Dark Specification 2026
///
/// LAYER 1 — BACKGROUNDS (Near-black with maroon undertone)
/// LAYER 2 — BRAND REDS (The Heart)
/// LAYER 3 — TEXT & LIGHT (Parchment readability on dark)
/// LAYER 4 — ACCENT / DATA BLUE (The Cool Contrast)
///
/// Rule: Void -> Abyss -> Card -> Elevated. Never skip a layer. Never reverse.
class AppTheme {
  AppTheme._();

  // ============================================================
  // LAYER 1 — BACKGROUNDS (Near-black maroon foundation)
  // ============================================================
  static const Color voidBg = Color(0xFF0D0000);         // App Background (Void)
  static const Color abyss = Color(0xFF140008);          // Default Surface (Abyss)
  static const Color cardSurface = Color(0xFF1F000D);    // Card Background
  static const Color elevatedSurface = Color(0xFF2E0012); // Elevated / Stat Boxes

  // ============================================================
  // LAYER 2 — BRAND REDS (The Heart)
  // ============================================================
  static const Color redDeep = Color(0xFF640D14);        // Pressed State / Pitch Background
  static const Color redMid = Color(0xFF800E13);         // Active / Secondary
  static const Color cardinal = Color(0xFFC1121F);       // Primary CTA / THE brand red
  static const Color rose = Color(0xFFAD2831);           // Hover / Gradient Partner

  // ============================================================
  // LAYER 3 — TEXT & LIGHT (Readability on dark bg)
  // ============================================================
  static const Color beige = Color(0xFFF2E8D5);            // Primary Text (warm beige)
  static const Color parchment = Color(0xFFF2E8D5);        // Alias — same beige
  static const Color mutedParchment = Color(0x80F2E8D5);   // Subtext (50% opacity)
  static const Color gold = Color(0xFFFFFFFF);                // White accent (was gold, unified to white)

  // ============================================================
  // LAYER 4 — ACCENT / DATA BLUE (The Cool Contrast)
  // ============================================================
  static const Color navy = Color(0xFFFFFFFF);           // Unified to white
  static const Color blueMid = Color(0xFFFFFFFF);        // Unified to white

  // ============================================================
  // THE 6 GRADIENT RECIPES (exactly 2 stops each)
  // ============================================================

  static const LinearGradient heroCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardinal, redDeep],
  );

  static const LinearGradient cardSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardSurface, elevatedSurface],
  );

  static const LinearGradient awayDataGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blueMid],
  );

  static const LinearGradient verticalPillGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardinal, redMid],
  );

  static const LinearGradient appBarAccentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cardinal, navy],
  );

  static const Color radialGlowColor = Color(0x18C1121F);

  // ============================================================
  // BORDER COLORS (white at low opacity per spec)
  // ============================================================
  static const Color cardBorderColor = Color(0x0AFFFFFF); // white at 4% opacity
  static const Color cardBorderColorLight = Color(0x08FFFFFF);
  static const Color cardBorderColorVeryLight = Color(0x06FFFFFF);
  static const Color dividerColor = Color(0x0AFFFFFF);
  static const Color cardBorderColorAlt = Color(0x0DFFFFFF);
  static const Color cardBorderColorMuted = Color(0x12FFFFFF);
  static const Color cardBorderColorFaint = Color(0x0BFFFFFF);

  // ============================================================
  // TYPOGRAPHY SYSTEM
  // ============================================================
  static const String fontFamily = 'DM Sans';
  static const String displayFontFamily = 'Bebas Neue';

  static TextStyle get bebasDisplay => GoogleFonts.bebasNeue(
    color: parchment,
    letterSpacing: 1.0,
  );

  static TextStyle get dmSans => GoogleFonts.dmSans(
    color: parchment,
  );

  // Pre-defined styles based on specification
  static TextStyle get statNumber => bebasDisplay.copyWith(fontSize: 48, height: 1.0);
  static TextStyle get scoreLarge => bebasDisplay.copyWith(fontSize: 52, height: 1.0);
  static TextStyle get ratingBadge => bebasDisplay.copyWith(fontSize: 16, color: gold);

  // Gold accent styles — for text/numbers on red backgrounds
  static TextStyle get goldDisplay => bebasDisplay.copyWith(color: gold);
  static TextStyle get goldBold => dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: gold);

  static TextStyle get bodyReg => dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodyBold => dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall => dmSans.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: gold);
  static TextStyle get sectionHeader => dmSans.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);

  // ============================================================
  // SPACING & SHAPE SYSTEM (per dark spec)
  // ============================================================
  static const double cardRadius = 16.0;
  static const double roleCardRadius = 14.0;
  static const double statBoxRadius = 10.0;
  static const double buttonRadius = 8.0;
  static const double positionBadgeRadius = 6.0;
  static const double smallElementRadius = 4.0;
  static const double pillRadius = 15.0;

  static const double screenPadding = 20.0;
  static const double cardGap = 14.0;
  static const double elementGap = 10.0;
  static const double chipGap = 8.0;

  static Widget accentBar() => Container(
    width: 3,
    height: 14,
    decoration: BoxDecoration(
      color: cardinal,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  static Border get cardBorder => Border.all(color: cardBorderColor, width: 1.0);
  static Border get cardBorderLight => Border.all(color: cardBorderColorLight, width: 1.0);
  static Border get cardBorderVeryLight => Border.all(color: cardBorderColorVeryLight, width: 1.0);
  static Border get cardBorderAlt => Border.all(color: cardBorderColorAlt, width: 1.0);
  static Border get cardBorderMuted => Border.all(color: cardBorderColorMuted, width: 1.0);

  // ============================================================
  // CARD DECORATIONS (per dark spec)
  // ============================================================
  static BoxDecoration get standardCard => BoxDecoration(
    gradient: cardSurfaceGradient,
    borderRadius: BorderRadius.circular(cardRadius),
    border: cardBorder,
    boxShadow: cardShadow,
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    gradient: cardSurfaceGradient,
    borderRadius: BorderRadius.circular(cardRadius),
    border: cardBorderAlt,
    boxShadow: premiumCardShadow,
  );

  static BoxDecoration get statBoxDecoration => BoxDecoration(
    color: elevatedSurface,
    borderRadius: BorderRadius.circular(statBoxRadius),
    border: cardBorderAlt,
  );

  static BoxDecoration get secondaryRowDecoration => BoxDecoration(
    color: cardSurface,
    borderRadius: BorderRadius.circular(12.0),
    border: cardBorderVeryLight,
  );

  // ============================================================
  // SHADOWS (dark-adapted)
  // ============================================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: const Color(0x40F2E8D5), blurRadius: 20, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> get premiumCardShadow => [
    BoxShadow(color: const Color(0x4CF2E8D5), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get heroCtaShadow => [
    BoxShadow(color: const Color(0x60F2E8D5), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get badgeShadow => [
    BoxShadow(color: const Color(0x50F2E8D5), blurRadius: 10),
  ];

  static List<BoxShadow> get formBadgeShadow => [
    BoxShadow(color: const Color(0x40F2E8D5), blurRadius: 8),
  ];

  static List<BoxShadow> get navPillShadow => [
    BoxShadow(color: const Color(0x55F2E8D5), blurRadius: 14, offset: const Offset(0, -3)),
  ];

  static List<BoxShadow> get shieldShadow => [
    BoxShadow(color: const Color(0x60F2E8D5), blurRadius: 16),
  ];

  static List<BoxShadow> get shieldShadowLarge => [
    BoxShadow(color: const Color(0x60F2E8D5), blurRadius: 20),
  ];

  static List<BoxShadow> get awayShieldShadow => [
    BoxShadow(color: const Color(0x60F2E8D5), blurRadius: 20),
  ];

  static List<BoxShadow> get motmBadgeShadow => [
    BoxShadow(color: const Color(0x50F2E8D5), blurRadius: 8),
  ];

  static List<BoxShadow> get bellIconShadow => [
    BoxShadow(color: const Color(0x60F2E8D5), blurRadius: 12),
  ];

  static List<BoxShadow> get playerCircleShadowHome => [
    BoxShadow(color: const Color(0x70F2E8D5), blurRadius: 12, offset: const Offset(0, 3)),
  ];

  static List<BoxShadow> get playerCircleShadowAway => [
    BoxShadow(color: const Color(0x70F2E8D5), blurRadius: 12, offset: const Offset(0, 3)),
  ];

  // ============================================================
  // RADIAL GLOW OVERLAY
  // ============================================================
  static BoxDecoration get radialGlowOverlay => BoxDecoration(
    borderRadius: BorderRadius.circular(cardRadius),
    gradient: const RadialGradient(
      center: Alignment(-0.2, 0.0), // 30% from left, 50% vertical
      radius: 0.7,
      colors: [Color(0x18C1121F), Colors.transparent],
      stops: [0.0, 1.0],
    ),
  );

  // ============================================================
  // THEME DATA (Dark mode)
  // ============================================================
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: voidBg,
      primaryColor: cardinal,
      fontFamily: fontFamily,
      textTheme: GoogleFonts.dmSansTextTheme().apply(
        bodyColor: parchment,
        displayColor: parchment,
      ),
      colorScheme: const ColorScheme.dark(
        primary: cardinal,
        secondary: redMid,
        surface: abyss,
        onSurface: parchment,
        onPrimary: gold,
        error: cardinal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: voidBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: parchment),
        titleTextStyle: TextStyle(color: parchment, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // COMPONENT HELPERS
  // ============================================================
  static Widget sectionLabel(String text) => Row(
    children: [
      accentBar(),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: labelSmall,
      ),
    ],
  );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: cardinal,
    foregroundColor: gold,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
    textStyle: dmSans.copyWith(fontWeight: FontWeight.w600, fontSize: 14, color: gold),
  );

  static InputDecoration inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: dmSans.copyWith(color: gold),
      filled: true,
      fillColor: elevatedSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(buttonRadius), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(buttonRadius), borderSide: BorderSide.none),
    );
  }

  // Gradient text helper using ShaderMask
  static Widget gradientText(String text, TextStyle style, {LinearGradient gradient = heroCtaGradient}) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: parchment),
      ),
    );
  }
}