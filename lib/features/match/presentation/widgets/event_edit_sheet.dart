import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../models/match_event_model.dart';

/// Bottom sheet for editing or voiding a match event.
/// Allows: change team (home/away), void (cancel) the event.
class EventEditSheet extends ConsumerStatefulWidget {
  final MatchEventModel event;
  final VoidCallback? onClose;

  const EventEditSheet({super.key, required this.event, this.onClose});

  @override
  ConsumerState<EventEditSheet> createState() => _EventEditSheetState();
}

class _EventEditSheetState extends ConsumerState<EventEditSheet> {
  late String _selectedTeam;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.event.team;
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (widget.event.type) {
      'goal' => (Icons.sports_soccer, AppTheme.navy),
      'assist' => (Icons.handshake, AppTheme.navy),
      'yellowCard' => (Icons.square, AppTheme.rose),
      'redCard' => (Icons.square, AppTheme.cardinal),
      'subOn' => (Icons.keyboard_double_arrow_up, AppTheme.navy),
      'subOff' => (Icons.keyboard_double_arrow_down, AppTheme.cardinal),
      _ => (Icons.circle, AppTheme.gold),
    };

    final match = ref.read(liveMatchProvider).currentMatch;
    final homeName = match?.homeTeamName ?? 'Home';
    final awayName = match?.awayTeamName ?? 'Away';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
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
              const SizedBox(height: 16),
              _header(icon, color),
              const SizedBox(height: 24),
              _teamSection(homeName, awayName),
              const SizedBox(height: 24),
              _saveTeamButton(),
              const SizedBox(height: 16),
              _voidButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Container(
        width: 48,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(IconData icon, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.event.displayFull.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${widget.event.minute}' — ${widget.event.playerName}",
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppTheme.gold,
                ),
              ),
            ]),
          ]),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.close,
                  color: AppTheme.parchment, size: 20),
            ),
          ),
        ],
      );

  Widget _teamSection(String homeName, String awayName) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'CHANGE TEAM',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.gold,
          letterSpacing: 0.15,
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _teamChip(homeName, 'home', AppTheme.navy),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _teamChip(awayName, 'away', AppTheme.navy),
        ),
      ]),
    ]);
  }

  Widget _teamChip(String name, String team, Color color) {
    final isSelected = _selectedTeam == team;
    return GestureDetector(
      onTap: () => setState(() => _selectedTeam = team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppTheme.abyss,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppTheme.gold,
            )),
      ),
    );
  }

  Widget _saveTeamButton() {
    final changed = _selectedTeam != widget.event.team;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: changed
            ? () async {
                await ref
                    .read(liveMatchProvider.notifier)
                    .changeEventTeam(widget.event.id, _selectedTeam);
                if (mounted) Navigator.pop(context);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              changed ? AppTheme.navy : AppTheme.elevatedSurface,
          foregroundColor:
              changed ? AppTheme.voidBg : AppTheme.gold,
          disabledBackgroundColor: AppTheme.elevatedSurface,
          disabledForegroundColor: AppTheme.gold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text('SAVE TEAM CHANGE',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            )),
      ),
    );
  }

  Widget _voidButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardSurface,
              title: Text('Void Event?',
                  style: TextStyle(color: AppTheme.parchment)),
              content: Text(
                  'This will remove the ${widget.event.displayFull.toLowerCase()} for ${widget.event.playerName}. Score will be updated.',
                  style: TextStyle(color: AppTheme.gold)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('CANCEL',
                      style:
                          TextStyle(color: AppTheme.gold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('VOID',
                      style:
                          TextStyle(color: AppTheme.cardinal)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref
                .read(liveMatchProvider.notifier)
                .voidEvent(widget.event.id);
            if (mounted) Navigator.pop(context);
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.cardinal.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('VOID EVENT (e.g. offside)',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.cardinal,
            )),
      ),
    );
  }
}