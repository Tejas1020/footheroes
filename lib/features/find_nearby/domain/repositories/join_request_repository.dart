import '../entities/join_request.dart';

/// Repository for match join requests.
abstract class JoinRequestRepository {
  /// Create a new join request.
  Future<JoinRequest> create({
    required String matchId,
    required String requesterUid,
    required String requesterPosition,
    String? requesterMessage,
  });

  /// Get a single request by ID.
  Future<JoinRequest?> getById(String id);

  /// Get all pending requests for a match.
  Future<List<JoinRequest>> getPendingForMatch(String matchId);

  /// Get all requests made by a player.
  Future<List<JoinRequest>> getByRequester(String requesterUid);

  /// Approve a request and assign a side.
  Future<JoinRequest> approve(String id, String side);

  /// Decline a request.
  Future<JoinRequest> decline(String id);

  /// Cancel a request (by the requester).
  Future<JoinRequest> cancel(String id);

  /// Expire stale pending requests.
  Future<int> expireStaleRequests(DateTime cutoff);

  /// Promote the oldest waitlisted request to pending.
  Future<JoinRequest?> promoteWaitlisted(String matchId);
}
