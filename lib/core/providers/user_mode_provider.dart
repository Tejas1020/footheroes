import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// User mode enum representing the two app experiences
enum UserMode { player, coach }

/// Hive box name for app preferences
const String _preferencesBoxName = 'app_preferences';
const String _userModeKey = 'user_mode';

/// Provider that manages user mode selection with Hive persistence
final userModeProvider = StateNotifierProvider<UserModeNotifier, UserMode>((ref) {
  return UserModeNotifier();
});

/// StateNotifier that manages user mode with persistence
class UserModeNotifier extends StateNotifier<UserMode> {
  UserModeNotifier() : super(UserMode.player) {
    _loadSavedMode();
  }

  /// Load saved mode from Hive on initialization
  Future<void> _loadSavedMode() async {
    try {
      final box = await Hive.openBox(_preferencesBoxName);
      final savedMode = box.get(_userModeKey);
      if (savedMode != null) {
        state = UserMode.values[savedMode];
      }
    } catch (e) {
      // If loading fails, default to player mode
      debugPrint('Failed to load user mode: $e');
    }
  }

  /// Set user mode and persist to Hive
  Future<void> setMode(UserMode mode) async {
    try {
      final box = await Hive.openBox(_preferencesBoxName);
      await box.put(_userModeKey, mode.index);
      state = mode;
    } catch (e) {
      debugPrint('Failed to save user mode: $e');
    }
  }

  /// Toggle between player and coach mode
  Future<void> toggleMode() async {
    final newMode = state == UserMode.player ? UserMode.coach : UserMode.player;
    await setMode(newMode);
  }
}
