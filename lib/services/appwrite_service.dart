import 'package:appwrite/appwrite.dart';
import '../environment.dart';

// ===========================================================================
// NOTIFICATION TYPES (defined outside class)
// ===========================================================================

/// Notification types for categorizing notifications
enum NotificationType {
  serverAnnouncement, // Server-wide announcements to all users
  matchChallenge, // Challenge requests between teams
  matchInvite, // Invitation to join a match
  tournamentUpdate, // Tournament status changes
  teamInvite, // Team membership invitations
  drillShared, // When a drill is shared with you
  leaderboardUpdate, // Leaderboard rank changes
  general, // Generic notifications
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  
  urgent,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.serverAnnouncement:
        return 'server_announcement';
      case NotificationType.matchChallenge:
        return 'match_challenge';
      case NotificationType.matchInvite:
        return 'match_invite';
      case NotificationType.tournamentUpdate:
        return 'tournament_update';
      case NotificationType.teamInvite:
        return 'team_invite';
      case NotificationType.drillShared:
        return 'drill_shared';
      case NotificationType.leaderboardUpdate:
        return 'leaderboard_update';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'server_announcement':
        return NotificationType.serverAnnouncement;
      case 'match_challenge':
        return NotificationType.matchChallenge;
      case 'match_invite':
        return NotificationType.matchInvite;
      case 'tournament_update':
        return NotificationType.tournamentUpdate;
      case 'team_invite':
        return NotificationType.teamInvite;
      case 'drill_shared':
        return NotificationType.drillShared;
      case 'leaderboard_update':
        return NotificationType.leaderboardUpdate;
      default:
        return NotificationType.general;
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get value {
    switch (this) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

  static NotificationPriority fromString(String value) {
    switch (value) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}

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

  // ===========================================================================
  // NOTIFICATION METHODS
  // ===========================================================================

  /// Create a notification (sent by server or triggered by events)
  Future<String> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? targetUserId, // null = broadcast to all
    String? relatedId, // ID of related entity (match, challenge, etc.)
    String? relatedType, // Type of related entity ('match', 'challenge', etc.)
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledAt, // For scheduled notifications
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'body': body,
        'type': type.value,
        'priority': priority.value,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (targetUserId != null) {
        data['targetUserId'] = targetUserId;
      }

      if (relatedId != null) {
        data['relatedId'] = relatedId;
      }

      if (relatedType != null) {
        data['relatedType'] = relatedType;
      }

      if (scheduledAt != null) {
        data['scheduledAt'] = scheduledAt.toIso8601String();
      }

      final result = await _tablesDB.createRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        rowId: ID.unique(),
        data: data,
        permissions: targetUserId != null
            ? ownerPermissions(targetUserId)
            : [
                Permission.read(Role.any()),
                Permission.update(Role.label('server')),
              ],
      );

      return result.$id;
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Create broadcast notification (sent to all users)
  Future<String> createBroadcastNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.serverAnnouncement,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: type,
      priority: priority,
    );
  }

  /// Create match-related notification
  Future<String> createMatchNotification({
    required String title,
    required String body,
    required NotificationType type, // matchChallenge or matchInvite
    required String matchId,
    required String targetUserId,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: type,
      targetUserId: targetUserId,
      relatedId: matchId,
      relatedType: 'match',
      priority: priority,
    );
  }

  /// Get notifications for a user
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final queries = <dynamic>[
        Query.equal('targetUserId', userId),
        Query.orderDesc('createdAt'),
        Query.limit(limit),
        Query.offset(offset),
      ];

      final result = await _tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        queries: queries.cast<String>(),
      );

      var notifications = result.rows.map((row) {
        final data = Map<String, dynamic>.from(row.data);
        data['id'] = row.$id;
        return data;
      }).toList();

      if (unreadOnly) {
        notifications = notifications.where((n) => n['isRead'] != true).toList();
      }

      return notifications;
    } on AppwriteException {
      return [];
    }
  }

  /// Get broadcast notifications (no targetUserId)
  Future<List<Map<String, dynamic>>> getBroadcastNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        queries: [
          Query.isNull('targetUserId'),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      return result.rows.map((row) {
        final data = Map<String, dynamic>.from(row.data);
        data['id'] = row.$id;
        return data;
      }).toList();
    } on AppwriteException {
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _tablesDB.updateRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        rowId: notificationId,
        data: {'isRead': true},
      );
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead({required String userId}) async {
    try {
      final notifications = await getUserNotifications(
        userId: userId,
        unreadOnly: true,
      );

      for (final notification in notifications) {
        await _tablesDB.updateRow(
          databaseId: Environment.appwriteDatabaseId,
          tableId: Environment.notificationsCollectionId,
          rowId: notification['id'],
          data: {'isRead': true},
        );
      }
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _tablesDB.deleteRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        rowId: notificationId,
      );
    } on AppwriteException catch (e) {
      throw handleAppwriteException(e);
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadNotificationCount({required String userId}) async {
    try {
      final result = await _tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.notificationsCollectionId,
        queries: [
          Query.equal('targetUserId', userId),
          Query.equal('isRead', false),
        ],
      );
      return result.total;
    } on AppwriteException {
      return 0;
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