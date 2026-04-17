import 'package:appwrite/appwrite.dart';
import '../environment.dart';

/// Appwrite service for authentication and database operations.
class AppwriteService {
  late final Client _client;
  late final Account _account;
  late final TablesDB _tablesDB;

  AppwriteService() {
    _client = Client()
        .setProject(Environment.appwriteProjectId)
        .setEndpoint(Environment.appwritePublicEndpoint);
    _account = Account(_client);
    _tablesDB = TablesDB(_client);
  }

  Client get client => _client;
  Account get account => _account;
  TablesDB get tablesDB => _tablesDB;

  // =============================================================================
  // PERMISSION HELPERS
  // =============================================================================

  /// Owner permissions - only the user can read, update, delete their own data
  List<String> ownerPermissions(String userId) => [
    Permission.read(Role.user(userId)),
    Permission.update(Role.user(userId)),
    Permission.delete(Role.user(userId)),
  ];

  /// Team permissions - team members can read, captain can update/delete
  List<String> teamPermissions(String teamId, String captainId) => [
    Permission.read(Role.team(teamId)),
    Permission.update(Role.user(captainId)),
    Permission.delete(Role.user(captainId)),
  ];

  /// Public read permissions - anyone can read (for drills, challenges, leaderboards)
  List<String> publicReadPermissions() => [
    Permission.read(Role.any()),
  ];

  // MIGRATION REQUIRED: Existing documents in Appwrite console have no permissions.
  // Go to Appwrite Console → Database → each Collection → Documents
  // → select all → Update permissions to match the rules above.

  /// Sign up with email and password
  Future<dynamic> signup({
    required String name,
    required String email,
    required String password,
    required String country,
    required String primaryPosition,
    String? secondaryPosition,
    String? dateOfBirth,
    bool agreedToTerms = false,
  }) async {
    try {
      // Create user account in Appwrite Auth
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create session immediately after account creation
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Store additional user data in database with permissions
      await _tablesDB.createRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: user.$id,
        data: {
          'name': name,
          'email': email,
          'country': country,
          'primaryPosition': primaryPosition,
          'secondaryPosition': secondaryPosition ?? '',
          'dateOfBirth': dateOfBirth ?? '',
          'agreedToTerms': agreedToTerms,
          'consentDate': agreedToTerms ? DateTime.now().toIso8601String() : '',
        },
        permissions: ownerPermissions(user.$id),
      );

      return user;
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Update user position data
  Future<void> updateUserPosition({
    required String rowId,
    required String primaryPosition,
    String? secondaryPosition,
  }) async {
    try {
      await _tablesDB.updateRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        rowId: rowId,
        data: {
          'primaryPosition': primaryPosition,
          'secondaryPosition': secondaryPosition ?? '',
        },
      );
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Sign in with email and password
  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Sign out current session
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Get current logged in user
  Future<dynamic> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  /// Search users by name prefix. Returns list of {id, name, email, primaryPosition}.
  Future<List<Map<String, String>>> searchUsersByName(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final result = await _tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.usersCollectionId,
        queries: [
          Query.startsWith('name', query.trim()),
          Query.limit(5),
        ],
      );
      return result.rows.map((row) {
        final data = row.data;
        return <String, String>{
          'id': (data['\$id'] ?? '') as String,
          'name': (data['name'] ?? '') as String,
          'email': (data['email'] ?? '') as String,
          'primaryPosition': (data['primaryPosition'] ?? '') as String,
        };
      }).where((u) => u['id']!.isNotEmpty).toList();
    } on AppwriteException {
      return [];
    }
  }

  /// Handle Appwrite exceptions and return user-friendly messages
  String handleAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Invalid email or password. Please check your credentials.';
      case 409:
        return 'An account with this email already exists.';
      case 400:
        if (e.message?.toLowerCase().contains('password') ?? false) {
          return 'Password must be at least 8 characters and contain both letters and numbers.';
        }
        if (e.message?.toLowerCase().contains('email') ?? false) {
          return 'Please enter a valid email address.';
        }
        return 'Invalid request. Please check your input.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 404:
        return 'Service not found. Please contact support.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}