import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../providers/live_match_provider.dart';
import '../../../../providers/match_timer_provider.dart';
import '../../../../services/offline_sync_service.dart';

/// Match timer widget — displays running clock + extra minutes button.
/// Reads from matchTimerProvider.
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
              color: MidnightPitchTheme.liveRed,
              shape: BoxShape.circle,
            ),
          ),
        Text(
          timerState.displayTime,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: -0.02,
          ),
        ),
        if (timerState.displayExtraTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              timerState.displayExtraTime!,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.championGold,
              ),
            ),
          ),
        if (timerState.currentHalf == 2)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.electricMint.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '2ND',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.electricMint,
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
      SyncStatus.synced => (MidnightPitchTheme.electricMint, Icons.cloud_done, 'Synced'),
      SyncStatus.syncing => (MidnightPitchTheme.championGold, Icons.cloud_upload, 'Syncing'),
      SyncStatus.pending => (MidnightPitchTheme.championGold, Icons.cloud_queue, 'Pending'),
      SyncStatus.failed => (MidnightPitchTheme.liveRed, Icons.cloud_off, 'Failed'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Extra minutes dialog — modal to add extra/stoppage minutes.
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
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      title: Text(
        'Add Extra Minutes',
        style: TextStyle(color: MidnightPitchTheme.primaryText),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(1, 10)),
            icon: const Icon(Icons.remove),
            color: MidnightPitchTheme.primaryText,
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '$_minutes',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: MidnightPitchTheme.electricMint,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(1, 10)),
            icon: const Icon(Icons.add),
            color: MidnightPitchTheme.primaryText,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(color: MidnightPitchTheme.mutedText),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(_minutes);
            Navigator.pop(context);
          },
          child: Text(
            'ADD',
            style: TextStyle(color: MidnightPitchTheme.electricMint),
          ),
        ),
      ],
    );
  }
}

/// Reduce time dialog — modal to subtract minutes from the clock.
/// Shows the resulting match length (e.g., 90 - 5 = 85 min).
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
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      title: Text(
        'Reduce Time',
        style: TextStyle(color: MidnightPitchTheme.primaryText),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(1, widget.totalMatchMinutes - 10)),
                icon: const Icon(Icons.remove),
                color: MidnightPitchTheme.primaryText,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '-$_minutes',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: MidnightPitchTheme.liveRed,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(1, widget.totalMatchMinutes - 10)),
                icon: const Icon(Icons.add),
                color: MidnightPitchTheme.primaryText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '${widget.totalMatchMinutes}',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.remove, size: 16, color: MidnightPitchTheme.liveRed),
              const SizedBox(width: 8),
              Text(
                '$_minutes',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.liveRed,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '=',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$resultingMinutes min',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: MidnightPitchTheme.electricMint,
                ),
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
            style: TextStyle(color: MidnightPitchTheme.mutedText),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(_minutes);
            Navigator.pop(context);
          },
          child: Text(
            'REDUCE',
            style: TextStyle(color: MidnightPitchTheme.liveRed),
          ),
        ),
      ],
    );
  }
}