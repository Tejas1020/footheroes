import '../entities/join_request.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/nearby_match_repository.dart';

/// Input for requesting to join a match.
class RequestToJoinMatchParams {
  final String matchId;
  final String requesterUid;
  final String requesterPosition;
  final String? requesterMessage;

  const RequestToJoinMatchParams({
    required this.matchId,
    required this.requesterUid,
    required this.requesterPosition,
    this.requesterMessage,
  });
}

/// Request to join an open match.
class RequestToJoinMatch {
  final JoinRequestRepository _joinRequestRepo;
  final NearbyMatchRepository _matchRepo;

  const RequestToJoinMatch(this._joinRequestRepo, this._matchRepo);

  Future<JoinRequest> call(RequestToJoinMatchParams params) async {
    // Verify match exists and is open
    final match = await _matchRepo.getById(params.matchId);
    if (match == null) throw Exception('Match not found');
    if (!match.openToNearby) throw Exception('Match is not open to nearby players');
    if (match.slotsRemaining <= 0) {
      // Waitlist path
      return _joinRequestRepo.create(
        matchId: params.matchId,
        requesterUid: params.requesterUid,
        requesterPosition: params.requesterPosition,
        requesterMessage: params.requesterMessage,
      );
    }

    // Enforce max 3 open pending requests
    final existing = await _joinRequestRepo.getByRequester(params.requesterUid);
    final openCount = existing.where((r) => r.status == JoinRequestStatus.pending).length;
    if (openCount >= 3) {
      throw Exception('You already have 3 open pending requests');
    }

    return _joinRequestRepo.create(
      matchId: params.matchId,
      requesterUid: params.requesterUid,
      requesterPosition: params.requesterPosition,
      requesterMessage: params.requesterMessage,
    );
  }
}
