import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../../../../providers/live_match_provider.dart';
import '../../../../../../../../../../providers/match_timer_provider.dart';
import '../../../../../../../../../../../services/offline_sync_service.dart';

/// Match timer widget using Dark Colour System.
class MatchTimerWidget extends ConsumerWidget {
  const MatchTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(matchTimerProvider);
    final isRunning = timerState.status == TimerStatus.running;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRunning)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.cardinal,
              shape: BoxShape.circle,
            ),
          ),
        Text(
          timerState.displayTime,
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 20,
            color: AppTheme.parchment,
            letterSpacing: 0.5,
          ),
        ),
        if (timerState.displayExtraTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              timerState.displayExtraTime!,
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 14,
                color: AppTheme.gold,
              ),
            ),
          ),
        if (timerState.currentHalf == 2)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.navy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '2ND',
              style: AppTheme.dmSans.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
          ),
      ],
    );
  }
}

/// Sync status indicator widget.
class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(liveMatchProvider);
    final status = matchState.syncStatus;

    final (color, icon, label) = switch (status) {
      SyncStatus.synced => (AppTheme.gold, Icons.cloud_done, 'Synced'),
      SyncStatus.syncing => (AppTheme.gold, Icons.cloud_upload, 'Syncing'),
      SyncStatus.pending => (AppTheme.gold, Icons.cloud_queue, 'Pending'),
      SyncStatus.failed => (AppTheme.cardinal, Icons.cloud_off, 'Failed'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Extra minutes dialog using Dark Colour System.
class StoppageTimeDialog extends StatefulWidget {
  final void Function(int minutes) onConfirm;

  const StoppageTimeDialog({super.key, required this.onConfirm});

  @override
  State<StoppageTimeDialog> createState() => _StoppageTimeDialogState();
}

class _StoppageTimeDialogState extends State<StoppageTimeDialog> {
  int _minutes = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.abyss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      title: Text(
        'Add Extra Minutes',
        style: AppTheme.bebasDisplay.copyWith(fontSize: 20),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(1, 10)),
            icon: const Icon(Icons.remove_circle_outline),
            color: AppTheme.gold,
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text(
              '+$_minutes',
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 48,
                color: AppTheme.cardinal,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(1, 10)),
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.gold,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: AppTheme.dmSans.copyWith(color: AppTheme.gold, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_minutes);
            Navigator.pop(context);
          },
          style: AppTheme.primaryButton.copyWith(
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          ),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

/// Reduce time dialog using Dark Colour System.
class ReduceTimeDialog extends StatefulWidget {
  final void Function(int minutes) onConfirm;
  final int totalMatchMinutes;

  const ReduceTimeDialog({super.key, required this.onConfirm, this.totalMatchMinutes = 90});

  @override
  State<ReduceTimeDialog> createState() => _ReduceTimeDialogState();
}

class _ReduceTimeDialogState extends State<ReduceTimeDialog> {
  int _minutes = 1;

  @override
  Widget build(BuildContext context) {
    final resultingMinutes = widget.totalMatchMinutes - _minutes;

    return AlertDialog(
      backgroundColor: AppTheme.abyss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      title: Text(
        'Reduce Match Time',
        style: AppTheme.bebasDisplay.copyWith(fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(1, widget.totalMatchMinutes - 10)),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.gold,
              ),
              Container(
                width: 100,
                alignment: Alignment.center,
                child: Text(
                  '-$_minutes',
                  style: AppTheme.bebasDisplay.copyWith(
                    fontSize: 48,
                    color: AppTheme.rose,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(1, widget.totalMatchMinutes - 10)),
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.gold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppTheme.standardCard.copyWith(
              color: AppTheme.elevatedSurface,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                '${widget.totalMatchMinutes}',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.parchment),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.remove, size: 16, color: AppTheme.rose),
              const SizedBox(width: 8),
              Text(
                '$_minutes',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.rose),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, size: 16, color: AppTheme.gold),
              ),
              Text(
                '$resultingMinutes min',
                style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.navy),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: AppTheme.dmSans.copyWith(color: AppTheme.gold, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_minutes);
            Navigator.pop(context);
          },
          style: AppTheme.primaryButton.copyWith(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.rose),
          ),
          child: const Text('REDUCE'),
        ),
      ],
    );
  }
}