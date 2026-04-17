import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' show OAuthProvider;
import 'package:hive_flutter/hive_flutter.dart';
import '../services/appwrite_service.dart';
import '../repositories/team_repository.dart';
import '../environment.dart';

/// Appwrite service provider
final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});

/// Authentication state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? name;
  final String? userId;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.email,
    this.name,
    this.userId,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? name,
    String? userId,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      error: error,
    );
  }
}

/// Auth state notifier - manages user authentication state with Appwrite
class AuthNotifier extends StateNotifier<AuthState> {
  final AppwriteService _appwriteService;

  AuthNotifier(this._appwriteService) : super(const AuthState(status: AuthStatus.loading)) {
    // Automatically check session on initialization
    _checkSessionOnInit();
  }

  Future<void> _checkSessionOnInit() async {
    try {
      final user = await _appwriteService.getCurrentUser();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: user.email,
          name: user.name,
          userId: user.$id,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Please fill in all fields',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final user = await _appwriteService.login(
        email: email,
        password: password,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        email: user.email,
        name: user.name,
        userId: user.$id,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String country,
    String primaryPosition = '',
    String? secondaryPosition,
    String? dateOfBirth,
    bool agreedToTerms = false,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty || country.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Please fill in all required fields',
      );
      return false;
    }

    if (password.length < 8) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Password must be at least 8 characters',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final user = await _appwriteService.signup(
        name: name,
        email: email,
        password: password,
        country: country,
        primaryPosition: primaryPosition.isNotEmpty ? primaryPosition : 'ST', // Default to ST
        secondaryPosition: secondaryPosition,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        email: user.email,
        name: user.name,
        userId: user.$id,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _appwriteService.logout();
    } catch (_) {
      // Ignore logout errors
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Delete the user's account (GDPR right to be forgotten).
  /// Removes user from teams, deletes user document, clears local data.
  /// Full Appwrite auth account deletion requires a server-side Appwrite Function.
  Future<void> deleteAccount(String userId) async {
    // Step 1: Remove user from all teams
    final teamRepo = TeamRepository(_appwriteService);
    try {
      final teams = await teamRepo.getTeamsForUser(userId);
      for (final team in teams) {
        await teamRepo.removeMember(team.teamId, userId);
      }
    } catch (_) {
      // Best-effort team removal
    }

    // Step 2: Delete user document from users collection
    try {
      await _appwriteService.tablesDB.deleteRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: userId,
      );
    } catch (_) {
      // Best-effort document deletion
    }

    // Step 3: Clear all local Hive data
    try {
      await Hive.deleteFromDisk();
    } catch (_) {}

    // Step 4: Sign out of Appwrite session
    // NOTE: Full account deletion requires an Appwrite Function triggered
    // on user document delete, because the client SDK cannot delete the
    // auth account itself. Create an Appwrite Function with:
    //   Trigger: users.*.delete
    //   Action: No additional action needed — Appwrite handles auth cleanup
    try {
      await _appwriteService.logout();
    } catch (_) {}

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send password recovery email.
  /// In Appwrite Console: Enable Google OAuth2 provider at Auth → OAuth2 Providers → Google
  Future<void> sendPasswordRecovery(String email) async {
    try {
      await _appwriteService.account.createRecovery(
        email: email,
        url: 'https://footheroes.com/reset-password',
      );
    } on AppwriteException catch (e) {
      throw _appwriteService.handleAppwriteException(e);
    }
  }

  /// Sign in with Google OAuth.
  /// Requires Google OAuth2 provider enabled in Appwrite Console → Auth → OAuth2 Providers → Google
  Future<bool> signInWithGoogle() async {
    try {
      await _appwriteService.account.createOAuth2Session(
        provider: OAuthProvider.google,
      );
      await checkSession();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign in with Apple OAuth.
  /// Requires Apple Sign-In configured in Appwrite Console → Auth → OAuth2 Providers → Apple
  /// Also requires proper entitlements for iOS/macOS (Sign in with Apple capability).
  Future<bool> signInWithApple() async {
    try {
      await _appwriteService.account.createOAuth2Session(
        provider: OAuthProvider.apple,
      );
      await checkSession();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Check for an existing Appwrite session on app startup.
  /// If a valid session is found, restores the authenticated state
  /// so the user doesn't have to log in again.
  Future<void> checkSession() async {
    try {
      final user = await _appwriteService.getCurrentUser();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: user.email,
          name: user.name,
          userId: user.$id,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthNotifier(appwriteService);
});

/// Derived provider - is user authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

/// Derived provider - is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.loading;
});