import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

// ============================================================
// TYPE 1 — HERO CARD
// Dominant element. Full-width. Gradient. 26px radius. 1 per screen.
// ============================================================
class HeroCard extends StatelessWidget {
  final String sectionLabel;
  final String playerName;
  final String position;
  final String league;
  final List<HeroStatData> stats;
  final int matchesPlayed;
  final double? avgRating;

  const HeroCard({
    super.key,
    required this.sectionLabel,
    required this.playerName,
    required this.position,
    required this.league,
    required this.stats,
    this.matchesPlayed = 0,
    this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.heroPadding),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.heroRadius),
        boxShadow: [
          // Raised lift shadow
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
          // Cardinal glow beneath
          BoxShadow(
            color: const Color(0x60C1121F),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative concentric rings
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: AppTheme.heroRingDecoration(220, 0.06),
            ),
          ),
          Positioned(
            right: -30,
            top: -10,
            child: Container(
              width: 160,
              height: 160,
              decoration: AppTheme.heroRingDecoration(160, 0.1),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: AppTheme.heroRingDecoration(180, 0.05),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + optional rating badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$sectionLabel${matchesPlayed > 0 ? ' · $matchesPlayed MATCHES' : ''}',
                          style: AppTheme.heroLabel,
                        ),
                        const SizedBox(height: AppTheme.elementGap),
                        Text(playerName, style: AppTheme.heroName),
                        const SizedBox(height: 4),
                        Text('$position · $league', style: AppTheme.heroMeta),
                      ],
                    ),
                  ),
                  if (avgRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                          const SizedBox(height: 2),
                          Text(
                            avgRating!.toStringAsFixed(1),
                            style: AppTheme.heroStat.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AVG\nRATING',
                            textAlign: TextAlign.center,
                            style: AppTheme.heroStatLabel.copyWith(fontSize: 7, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Divider line
              Container(
                height: 1,
                color: Colors.white.withAlpha(30),
              ),
              const SizedBox(height: 16),
              // Stat row
              Row(
                children: stats.map((s) => Expanded(child: _HeroStat(data: s))).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final HeroStatData data;
  const _HeroStat({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(data.value, style: AppTheme.heroStat),
        const SizedBox(height: 4),
        Text(data.label, style: AppTheme.heroStatLabel),
      ],
    );
  }
}

class HeroStatData {
  final String label;
  final String value;
  const HeroStatData({required this.label, required this.value});
}

// ============================================================
// TYPE 2 — GLASS CARD
// Supporting stat. White glass. 20px radius. One stat per card.
// Used in 2-column grid.
// ============================================================
class GlassCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final bool trendUp;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendUp = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.cardBorderColorLight, width: 0.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level 1: Label
            Text(label.toUpperCase(), style: AppTheme.cardLabel),
            const SizedBox(height: AppTheme.elementGap),
            // Level 2: Number
            Text(value, style: AppTheme.cardNumber),
            if (trend != null) ...[
              const SizedBox(height: 4),
              // Level 3: Trend
              Text(
                '${trendUp ? "↑" : "↓"} $trend',
                style: AppTheme.cardTrend,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TYPE 3 — ACCENT CARD
// Highlight metric. Orange gradient. 20px radius. Always paired
// with a Glass Card. White text only. Has progress bar.
// ============================================================
class AccentCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final String? subLabel;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    this.subLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          gradient: AppTheme.accentCardGradient,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.shieldShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTheme.cardLabel.copyWith(color: Colors.white)),
            const SizedBox(height: AppTheme.elementGap),
            Text(value, style: AppTheme.cardNumber.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withAlpha(46),
                color: Colors.white.withAlpha(179),
                minHeight: 3,
              ),
            ),
            if (subLabel != null) ...[
              const SizedBox(height: 5),
              Text(subLabel!, style: AppTheme.cardTrend.copyWith(color: Colors.white, fontSize: 8)),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TYPE 4 — DARK CARD
// Contrast break. Warm dark #1C0A00. 20px radius. One per scroll.
// Contains form/history data. Win badges orange, draw muted, loss red.
// ============================================================
class DarkCard extends StatelessWidget {
  final String label;
  final List<FormResult> form;
  final String? streak;
  final Widget? extraContent;

  const DarkCard({
    super.key,
    required this.label,
    required this.form,
    this.streak,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: const Color(0xFFFFCC80), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandOrange.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.dmSans.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warmDark,
                  letterSpacing: 1.5,
                ),
              ),
              if (streak != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroCtaGradient,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandOrange.withAlpha(40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    streak!,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: form.map((r) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FormBadgeWithDay(result: r),
              );
            }).toList(),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 12),
            extraContent!,
          ],
        ],
      ),
    );
  }
}

class _FormBadgeWithDay extends StatelessWidget {
  final FormResult result;
  const _FormBadgeWithDay({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: result.color,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            result.labelOrAuto,
            style: AppTheme.dmSans.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          result.dayLabel ?? '',
          style: AppTheme.dmSans.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.warmDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

enum FormResultType { win, draw, loss }

class FormResult {
  final FormResultType type;
  final String label;
  final String? dayLabel;

  const FormResult({required this.type, this.label = '', this.dayLabel});

  String get labelOrAuto => label.isNotEmpty ? label : switch (type) { FormResultType.win => 'W', FormResultType.draw => 'D', FormResultType.loss => 'L' };

  Color get color => switch (type) {
    FormResultType.win => AppTheme.winBadge,
    FormResultType.draw => const Color(0xFF3D1A0A),
    FormResultType.loss => const Color(0xFF1A0505),
  };

  Color get textColor => switch (type) {
    FormResultType.win => Colors.white,
    FormResultType.draw => const Color(0xFF8D6E63),
    FormResultType.loss => AppTheme.deepRed,
  };
}

// ============================================================
// TYPE 5 — EMPTY STATE CARD
// Call to action. Glass white. Centered layout. Icon in warm
// orange tint box. CTA button with gradient + glow.
// ============================================================
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorderColorLight, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in warm orange tint box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.emptyIconGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.emptyIconBorder, width: 0.5),
            ),
            child: Icon(icon, size: 22, color: AppTheme.brandOrange),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.parchment)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.dmSans.copyWith(fontSize: 11, color: AppTheme.warmGrey)),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.brandOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonRadius)),
                  textStyle: AppTheme.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: Text(ctaLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// BREAKDOWN CARD (Glass variant with horizontal stat row)
// Used for match breakdown, position stats, etc.
// ============================================================
class BreakdownCard extends StatelessWidget {
  final String label;
  final List<BreakdownStat> stats;
  final String? subtitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  const BreakdownCard({
    super.key,
    required this.label,
    required this.stats,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorderColorLight, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.dmSans.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.parchment,
                  letterSpacing: -0.5,
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seeAllLabel ?? 'See all',
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandOrange,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 14, color: AppTheme.brandOrange),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.dmSans.copyWith(fontSize: 10, color: AppTheme.warmGrey)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.map((s) => Expanded(child: _BreakdownStat(data: s))).toList(),
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final BreakdownStat data;
  const _BreakdownStat({required this.data});

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTheme.dmSans.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: -1.0,
      height: 1.0,
    );

    final valueWidget = data.valueGradient != null
        ? AppTheme.gradientText(data.value, valueStyle, gradient: data.valueGradient)
        : Text(
            data.value,
            style: AppTheme.dmSans.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: data.valueColor ?? AppTheme.parchment,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          );

    return Column(
      children: [
        valueWidget,
        const SizedBox(height: 6),
        Text(
          data.label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.parchment,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class BreakdownStat {
  final String label;
  final String value;
  final Color? valueColor;
  final LinearGradient? valueGradient;
  const BreakdownStat({required this.label, required this.value, this.valueColor, this.valueGradient});
}
