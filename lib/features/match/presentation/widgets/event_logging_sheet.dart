import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../providers/live_match_provider.dart';
import '../../../../providers/match_timer_provider.dart';

/// Player info used in event logging.
class EventLoggingPlayer {
  final String id;
  final String name;
  final String position;
  final String team; // 'home' or 'away'

  const EventLoggingPlayer({
    required this.id,
    required this.name,
    required this.position,
    this.team = 'home',
  });
}

/// Event logging bottom sheet — appears when tapping a player.
/// Logs goals, assists, cards, and substitutions.
class EventLoggingSheet extends ConsumerStatefulWidget {
  final EventLoggingPlayer player;
  final VoidCallback? onClose;
  final VoidCallback? onRedCard;

  const EventLoggingSheet({
    super.key,
    required this.player,
    this.onClose,
    this.onRedCard,
  });

  @override
  ConsumerState<EventLoggingSheet> createState() => _EventLoggingSheetState();
}

class _EventLoggingSheetState extends ConsumerState<EventLoggingSheet> {
  String? _selectedType;
  late String _selectedTeam;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.player.team;
    _minuteController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMinute = ref.read(matchTimerProvider).currentMinute;
      _minuteController.text = currentMinute.toString();
    });
  }

  @override
  void dispose() {
    _minuteController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedType == null) return;
    ref.read(liveMatchProvider.notifier).logEvent(
      type: _selectedType!,
      playerId: widget.player.id,
      playerName: widget.player.name,
      team: _selectedTeam,
    );

    if (_selectedType == 'redCard') {
      widget.onRedCard?.call();
    }

    Navigator.pop(context);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentMinute = ref.watch(matchTimerProvider).currentMinute;

    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 48,
            offset: const Offset(0, -24),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              const SizedBox(height: 24),
              _header(currentMinute),
              const SizedBox(height: 20),
              _teamSelector(),
              const SizedBox(height: 24),
              _eventGrid(),
              const SizedBox(height: 32),
              _minuteInput(currentMinute),
              const SizedBox(height: 16),
              _confirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Container(
    width: 48, height: 4,
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: MidnightPitchTheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _header(int currentMinute) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOG EVENT FOR', style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10,
          fontWeight: FontWeight.w700, color: MidnightPitchTheme.mutedText,
          letterSpacing: 0.15,
        )),
        const SizedBox(height: 4),
        Text(widget.player.name, style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily, fontSize: 22,
          fontWeight: FontWeight.w700, color: MidnightPitchTheme.primaryText,
          letterSpacing: -0.02,
        )),
      ]),
      GestureDetector(
        onTap: widget.onClose ?? () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: MidnightPitchTheme.surfaceContainerHigh, shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.close, color: MidnightPitchTheme.primaryText, size: 20),
        ),
      ),
    ],
  );

  Widget _teamSelector() {
    final match = ref.read(liveMatchProvider).currentMatch;
    final homeName = match?.homeTeamName ?? 'Home';
    final awayName = match?.awayTeamName ?? 'Away';
    return Row(children: [
      Text('SCORING FOR:', style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily, fontSize: 10,
        fontWeight: FontWeight.w700, color: MidnightPitchTheme.mutedText,
        letterSpacing: 0.15,
      )),
      const SizedBox(width: 12),
      _teamChip(homeName, 'home', MidnightPitchTheme.electricMint),
      const SizedBox(width: 8),
      _teamChip(awayName, 'away', MidnightPitchTheme.skyBlue),
    ]);
  }

  Widget _teamChip(String name, String team, Color color) {
    final isSelected = _selectedTeam == team;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeam = team),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : MidnightPitchTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: color.withValues(alpha: 0.5)) : null,
          ),
          child: Text(name, textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily, fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : MidnightPitchTheme.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventGrid() {
    final events = [
      _EventButton('goal', Icons.sports_soccer, MidnightPitchTheme.electricMint, 'Goal'),
      _EventButton('assist', Icons.handshake, MidnightPitchTheme.skyBlue, 'Assist'),
      _EventButton('yellowCard', Icons.square, MidnightPitchTheme.championGold, 'Yellow Card'),
      _EventButton('redCard', Icons.square, MidnightPitchTheme.liveRed, 'Red Card'),
      _EventButton('subOn', Icons.keyboard_double_arrow_up, MidnightPitchTheme.electricMint, 'Sub On'),
      _EventButton('subOff', Icons.keyboard_double_arrow_down, MidnightPitchTheme.liveRed, 'Sub Off'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      physics: const NeverScrollableScrollPhysics(),
      children: events.map((btn) {
        final isSelected = _selectedType == btn.type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = btn.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? MidnightPitchTheme.surfaceContainerHighest
                  : MidnightPitchTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: MidnightPitchTheme.electricMint.withValues(alpha: 0.4))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(btn.icon, size: 28, color: btn.color),
                const SizedBox(height: 4),
                Text(
                  btn.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _minuteInput(int currentMinute) {
    return Container(
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MidnightPitchTheme.surfaceContainerHighest.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EVENT MINUTE',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MidnightPitchTheme.mutedText,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _minuteController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.electricMint,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: currentMinute.toString(),
                hintStyle: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricMint.withValues(alpha: 0.4),
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    final canConfirm = _selectedType != null;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: canConfirm ? _confirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canConfirm ? null : MidnightPitchTheme.surfaceContainerHighest,
          foregroundColor: canConfirm ? null : MidnightPitchTheme.mutedText,
          disabledBackgroundColor: MidnightPitchTheme.surfaceContainerHighest,
          disabledForegroundColor: MidnightPitchTheme.mutedText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ).copyWith(
          backgroundColor: canConfirm ? WidgetStatePropertyAll(MidnightPitchTheme.electricMint) : null,
        ),
        child: Text('CONFIRM EVENT', style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily, fontSize: 14,
          fontWeight: FontWeight.w700, letterSpacing: 0.1,
          color: canConfirm ? MidnightPitchTheme.surfaceDim : MidnightPitchTheme.mutedText,
        )),
      ),
    );
  }
}

class _EventButton {
  final String type;
  final IconData icon;
  final Color color;
  final String label;

  const _EventButton(this.type, this.icon, this.color, this.label);
}