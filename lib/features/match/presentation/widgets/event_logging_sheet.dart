import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../providers/match_timer_provider.dart';

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

/// Event logging bottom sheet using Dark Colour System.
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
      decoration: const BoxDecoration(
        color: AppTheme.abyss,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
      color: AppTheme.elevatedSurface,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _header(int currentMinute) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOG EVENT FOR', style: AppTheme.labelSmall),
        const SizedBox(height: 4),
        Text(widget.player.name, style: AppTheme.bebasDisplay.copyWith(
          fontSize: 22,
          color: AppTheme.parchment,
          letterSpacing: 0.5,
        )),
      ]),
      GestureDetector(
        onTap: widget.onClose ?? () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            color: AppTheme.cardSurface, shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.close, color: AppTheme.parchment, size: 20),
        ),
      ),
    ],
  );

  Widget _teamSelector() {
    final match = ref.read(liveMatchProvider).currentMatch;
    final homeName = match?.homeTeamName ?? 'Home';
    final awayName = match?.awayTeamName ?? 'Away';
    return Row(children: [
      Text('TEAM:', style: AppTheme.labelSmall),
      const SizedBox(width: 12),
      _teamChip(homeName, 'home', AppTheme.cardinal),
      const SizedBox(width: 8),
      _teamChip(awayName, 'away', AppTheme.navy),
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
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            border: isSelected ? Border.all(color: color.withValues(alpha: 0.5)) : null,
          ),
          child: Text(name, textAlign: TextAlign.center,
            style: AppTheme.dmSans.copyWith(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppTheme.gold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventGrid() {
    final events = [
      _EventButton('goal', Icons.sports_soccer, AppTheme.cardinal, 'Goal'),
      _EventButton('assist', Icons.handshake, AppTheme.gold, 'Assist'),
      _EventButton('yellowCard', Icons.square, AppTheme.parchment, 'Yellow Card'),
      _EventButton('redCard', Icons.square, AppTheme.cardinal, 'Red Card'),
      _EventButton('subOn', Icons.keyboard_double_arrow_up, AppTheme.gold, 'Sub On'),
      _EventButton('subOff', Icons.keyboard_double_arrow_down, AppTheme.cardinal, 'Sub Off'),
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
                  ? AppTheme.elevatedSurface
                  : AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: btn.color.withValues(alpha: 0.4))
                  : AppTheme.cardBorder,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(btn.icon, size: 28, color: btn.color),
                const SizedBox(height: 4),
                Text(
                  btn.label.toUpperCase(),
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: AppTheme.parchment,
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: AppTheme.cardBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EVENT MINUTE',
            style: AppTheme.labelSmall,
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _minuteController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 20,
                color: AppTheme.cardinal,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: currentMinute.toString(),
                hintStyle: AppTheme.bebasDisplay.copyWith(
                  fontSize: 20,
                  color: AppTheme.cardinal.withValues(alpha: 0.4),
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
          backgroundColor: canConfirm ? AppTheme.cardinal : AppTheme.elevatedSurface,
          foregroundColor: AppTheme.parchment,
          disabledBackgroundColor: AppTheme.elevatedSurface,
          disabledForegroundColor: AppTheme.gold.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text('CONFIRM EVENT', style: AppTheme.dmSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
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