import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_match_storage.dart';
import '../services/whistle_service.dart';

/// Timer status for match timing.
enum TimerStatus {
  stopped,
  running,
  paused,
  halftime,
  finished,
}

/// State for the match timer.
class MatchTimerState {
  final int elapsedSeconds;
  final TimerStatus status;
  final int stoppageSeconds;
  final int currentHalf; // 1 or 2
  final int halfDuration; // typically 45 for 11v11, varies for other formats

  const MatchTimerState({
    this.elapsedSeconds = 0,
    this.status = TimerStatus.stopped,
    this.stoppageSeconds = 0,
    this.currentHalf = 1,
    this.halfDuration = 45 * 60, // 45 minutes in seconds
  });

  MatchTimerState copyWith({
    int? elapsedSeconds,
    TimerStatus? status,
    int? stoppageSeconds,
    int? currentHalf,
    int? halfDuration,
  }) {
    return MatchTimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      stoppageSeconds: stoppageSeconds ?? this.stoppageSeconds,
      currentHalf: currentHalf ?? this.currentHalf,
      halfDuration: halfDuration ?? this.halfDuration,
    );
  }

  /// Display time as MM:SS (e.g. "32:15").
  String get displayTime {
    final totalWithStoppage = elapsedSeconds + stoppageSeconds;
    final minutes = totalWithStoppage ~/ 60;
    final seconds = totalWithStoppage % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Extra time indicator (e.g. "+3") shown alongside displayTime during stoppage.
  /// Returns null when not in stoppage.
  String? get displayExtraTime {
    if (stoppageSeconds > 0 && elapsedSeconds >= halfDuration) {
      final addedMinutes = stoppageSeconds ~/ 60;
      return '+$addedMinutes';
    }
    return null;
  }

  /// Get the current match minute (for event logging).
  int get currentMinute {
    if (currentHalf == 1) {
      return (elapsedSeconds ~/ 60).clamp(0, 45);
    } else {
      return ((elapsedSeconds - halfDuration) ~/ 60).clamp(45, 90);
    }
  }
}

/// Notifier that manages match timer state with crash protection.
class MatchTimerNotifier extends StateNotifier<MatchTimerState> {
  Timer? _timer;
  final LocalMatchStorage _localStorage;
  String? _matchId;
  int _saveCounter = 0;

  MatchTimerNotifier(this._localStorage) : super(const MatchTimerState());

  /// Initialize timer with match format.
  void initMatch(String matchId, {int halfDurationMinutes = 45}) {
    _matchId = matchId;
    state = MatchTimerState(
      halfDuration: halfDurationMinutes * 60,
      currentHalf: 1,
      status: TimerStatus.stopped,
    );
    _loadTimerState();
  }

  /// Load timer state from Hive (crash recovery).
  Future<void> _loadTimerState() async {
    if (_matchId == null) return;
    final savedState = _localStorage.getTimerState(_matchId!);
    if (savedState != null) {
      final savedStatus = TimerStatus.values.firstWhere(
        (s) => s.name == savedState['status'],
        orElse: () => TimerStatus.stopped,
      );
      state = MatchTimerState(
        elapsedSeconds: savedState['elapsedSeconds'] as int? ?? 0,
        currentHalf: savedState['currentHalf'] as int? ?? 1,
        stoppageSeconds: savedState['stoppageSeconds'] as int? ?? 0,
        status: savedStatus,
        halfDuration: state.halfDuration,
      );
      // Restart the Timer if saved state was running (crash recovery)
      if (savedStatus == TimerStatus.running) {
        startTimer();
      }
    }
  }

  /// Start the match (kickoff). Plays whistle and starts timer.
  void startMatch() {
    WhistleService.playWhistle();
    startTimer();
  }

  /// Start the timer.
  void startTimer() {
    if (_timer != null) return;
    state = state.copyWith(status: TimerStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      _saveCounter++;
      if (_saveCounter >= 30) {
        _saveToHive();
        _saveCounter = 0;
      }
    });
  }

  /// Pause the timer.
  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: TimerStatus.paused);
    _saveToHive();
  }

  /// Resume the timer.
  void resumeTimer() {
    if (state.status == TimerStatus.paused) {
      startTimer();
    }
  }

  /// Add stoppage time.
  void addStoppageTime(int seconds) {
    state = state.copyWith(stoppageSeconds: state.stoppageSeconds + seconds);
    _saveToHive();
  }

  /// Reduce elapsed time (for shorter format matches).
  void reduceTime(int seconds) {
    final newElapsed = (state.elapsedSeconds - seconds).clamp(0, state.elapsedSeconds);
    state = state.copyWith(elapsedSeconds: newElapsed);
    _saveToHive();
  }

  /// End first half.
  void endFirstHalf() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: TimerStatus.halftime);
    WhistleService.playWhistle();
    _saveToHive();
  }

  /// Start second half.
  void startSecondHalf() {
    state = state.copyWith(
      currentHalf: 2,
      status: TimerStatus.running,
    );
    startTimer();
  }

  /// End the match.
  void endMatch() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: TimerStatus.finished);
    WhistleService.playWhistle();
    _saveToHive();
  }

  /// Save timer state to Hive (crash protection).
  Future<void> _saveToHive() async {
    if (_matchId == null) return;
    await _localStorage.saveTimerState(
      matchId: _matchId!,
      elapsedSeconds: state.elapsedSeconds,
      currentHalf: state.currentHalf,
      stoppageSeconds: state.stoppageSeconds,
      status: state.status.name,
    );
  }

  /// Clear timer state.
  Future<void> clearTimerState() async {
    if (_matchId == null) return;
    await _localStorage.clearTimerState(_matchId!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveToHive();
    super.dispose();
  }
}

/// Provider for match timer.
final matchTimerProvider = StateNotifierProvider<MatchTimerNotifier, MatchTimerState>((ref) {
  return MatchTimerNotifier(LocalMatchStorage());
});