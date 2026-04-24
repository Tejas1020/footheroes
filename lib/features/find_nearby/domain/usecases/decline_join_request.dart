import '../entities/join_request.dart';
import '../repositories/join_request_repository.dart';

/// Decline a join request.
class DeclineJoinRequest {
  final JoinRequestRepository _joinRequestRepo;

  const DeclineJoinRequest(this._joinRequestRepo);

  Future<JoinRequest> call(String requestId) async {
    final request = await _joinRequestRepo.getById(requestId);
    if (request == null) throw Exception('Request not found');
    if (request.status != JoinRequestStatus.pending) {
      throw Exception('Request is not pending');
    }

    return _joinRequestRepo.decline(requestId);
  }
}
