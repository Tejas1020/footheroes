import '../entities/join_request.dart';
import '../repositories/join_request_repository.dart';

/// Cancel a pending join request (by the requester).
class CancelJoinRequest {
  final JoinRequestRepository _repo;

  const CancelJoinRequest(this._repo);

  Future<JoinRequest> call(String requestId) async {
    return _repo.cancel(requestId);
  }
}
