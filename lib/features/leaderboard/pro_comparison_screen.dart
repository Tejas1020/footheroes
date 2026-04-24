import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Pro Comparison screen — shareable card comparing the player's
/// stats against a professional benchmark (e.g. Haaland).
class ProComparisonScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onShareInstagram;
  final VoidCallback? onShareWhatsApp;

  const ProComparisonScreen({
    super.key,
    this.onBack,
    this.onShareInstagram,
    this.onShareWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 180),
                child: Column(
                  children: [
                    _buildComparisonCard(),
                    const SizedBox(height: 40),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.voidBg,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'STAT COMPARISON',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.parchment,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _shareComparison(context),
            child: Icon(Icons.share, color: AppTheme.gold, size: 22),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // COMPARISON CARD
  // =============================================================================

  Widget _buildComparisonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.voidBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.elevatedSurface),
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FootHeroes',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.parchment,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'PRO COMPARISON',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.rose,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          // YOU section
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            child: Column(
              children: [
                Text(
                  'YOU TODAY',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '40%',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                    letterSpacing: -0.04,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Shot conversion rate · 5 shots · 2 goals',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
          // VS divider
          _buildVsDivider(),
          // PRO section
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              children: [
                Text(
                  'Erling Haaland',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.parchment,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Man City · Premier League',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '23%',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.parchment,
                    letterSpacing: -0.04,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SEASON SHOT CONVERSION AVG',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gold,
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 24),
                // Result banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.navy.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: AppTheme.rose, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'You outperformed Haaland today',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Horizontal line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(height: 1, color: AppTheme.elevatedSurface),
          ),
          // VS pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.rose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.rose.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.rose,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // ACTION BUTTONS
  // =============================================================================

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Share to Instagram
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onShareInstagram,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: AppTheme.voidBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SHARE TO INSTAGRAM',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Share to WhatsApp
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onShareWhatsApp,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.cardinal.withValues(alpha: 0.25)),
              backgroundColor: AppTheme.elevatedSurface.withValues(alpha: 0.5),
              foregroundColor: AppTheme.blueMid,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SHARE TO WHATSAPP',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tap to regenerate
        GestureDetector(
          onTap: () => _regenerateComparison(context),
          child: Text(
            'TAP TO REGENERATE',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.gold,
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }

  void _shareComparison(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Comparison card saved to gallery'),
        backgroundColor: AppTheme.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _regenerateComparison(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New comparison generated'),
        backgroundColor: AppTheme.rose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}