import '../entities/join_request.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/nearby_match_repository.dart';

/// Approve a join request and assign the player to a side.
class ApproveJoinRequest {
  final JoinRequestRepository _joinRequestRepo;
  final NearbyMatchRepository _matchRepo;

  const ApproveJoinRequest(this._joinRequestRepo, this._matchRepo);

  Future<JoinRequest> call(String requestId, String side) async {
    final request = await _joinRequestRepo.getById(requestId);
    if (request == null) throw Exception('Request not found');
    if (request.status != JoinRequestStatus.pending) {
      throw Exception('Request is not pending');
    }

    final match = await _matchRepo.getById(request.matchId);
    if (match == null) throw Exception('Match not found');

    // Approve the request
    final updated = await _joinRequestRepo.approve(requestId, side);

    // Decrement slots
    final newSlots = match.slotsRemaining - 1;
    await _matchRepo.update(request.matchId, {
      'slotsRemaining': newSlots,
      if (newSlots <= 0) 'openToNearby': false,
    });

    return updated;
  }
}
