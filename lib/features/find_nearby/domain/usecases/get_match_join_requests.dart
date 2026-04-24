import '../entities/join_request.dart';
import '../repositories/join_request_repository.dart';

/// Get pending join requests for a match.
class GetMatchJoinRequests {
  final JoinRequestRepository _repo;

  const GetMatchJoinRequests(this._repo);

  Future<List<JoinRequest>> call(String matchId) async {
    return _repo.getPendingForMatch(matchId);
  }
}
