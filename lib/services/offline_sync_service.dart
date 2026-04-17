import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_match_storage.dart';
import '../repositories/match_repository.dart';
import '../providers/auth_provider.dart';

/// Sync status for offline-first architecture.
enum SyncStatus {
  synced,
  syncing,
  pending,
  failed,
}

/// State for offline sync.
class OfflineSyncState {
  final SyncStatus status;
  final int pendingCount;
  final int syncedCount;
  final String? lastError;
  final bool isOnline;

  const OfflineSyncState({
    this.status = SyncStatus.synced,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.lastError,
    this.isOnline = true,
  });

  OfflineSyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? syncedCount,
    String? lastError,
    bool? isOnline,
  }) {
    return OfflineSyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      lastError: lastError,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Service that handles offline-first synchronization of match events.
///
/// Architecture:
/// 1. All events saved to Hive FIRST (synchronous)
/// 2. Connectivity listener watches for internet
/// 3. When online, syncs pending events to Appwrite
/// 4. On sync success, marks events as synced
/// 5. Retry with exponential backoff on failures
class OfflineSyncService extends StateNotifier<OfflineSyncState> {
  final LocalMatchStorage _localStorage;
  final MatchRepository _matchRepository;
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;

  OfflineSyncService(
    this._localStorage,
    this._matchRepository,
    this._connectivity,
  ) : super(const OfflineSyncState()) {
    _init();
  }

  void _init() {
    _checkPendingCount();
    _startConnectivityListener();
  }

  /// Check how many events are pending sync.
  void _checkPendingCount() {
    final pending = _localStorage.getPendingEvents();
    state = state.copyWith(
      pendingCount: pending.length,
      status: pending.isEmpty ? SyncStatus.synced : SyncStatus.pending,
    );
  }

  /// Start listening for connectivity changes.
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final isOnline = results.any(
          (result) => result != ConnectivityResult.none,
        );
        state = state.copyWith(isOnline: isOnline);
        if (isOnline) {
          syncPendingEvents();
        }
      },
    );
  }

  /// Sync all pending events to Appwrite.
  /// Called automatically when connectivity is restored.
  Future<void> syncPendingEvents() async {
    if (state.status == SyncStatus.syncing) return;

    final pendingEvents = _localStorage.getPendingEvents();
    if (pendingEvents.isEmpty) {
      state = state.copyWith(status: SyncStatus.synced, pendingCount: 0);
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing);
    int syncedCount = 0;

    for (final event in pendingEvents) {
      final success = await _syncEventWithRetry(event, attempt: 1);
      if (success) {
        await _localStorage.markEventSynced(event['eventId'] as String);
        syncedCount++;
      }
    }

    _checkPendingCount();
    state = state.copyWith(
      status: SyncStatus.synced,
      syncedCount: syncedCount,
    );
  }

  /// Sync a single event with exponential backoff retry.
  Future<bool> _syncEventWithRetry(Map<String, dynamic> event, {required int attempt}) async {
    const maxRetries = 3;

    try {
      await _matchRepository.create(event['eventId'] as String, event);
      return true;
    } catch (e) {
      if (attempt < maxRetries) {
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
        return _syncEventWithRetry(event, attempt: attempt + 1);
      }
      state = state.copyWith(lastError: e.toString());
      return false;
    }
  }

  /// Force a sync attempt (manual trigger).
  Future<bool> forceSync() async {
    if (!state.isOnline) {
      state = state.copyWith(lastError: 'No internet connection');
      return false;
    }
    await syncPendingEvents();
    return state.pendingCount == 0;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Provider for offline sync service
final offlineSyncServiceProvider = StateNotifierProvider<OfflineSyncService, OfflineSyncState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return OfflineSyncService(
    LocalMatchStorage(),
    MatchRepository(appwriteService),
    Connectivity(),
  );
});