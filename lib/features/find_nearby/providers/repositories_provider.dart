import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../data/repositories/discovery_block_repository_impl.dart';
import '../data/repositories/join_request_repository_impl.dart';
import '../data/repositories/nearby_match_repository_impl.dart';
import '../data/repositories/venue_repository_impl.dart';
import '../domain/repositories/discovery_block_repository.dart';
import '../domain/repositories/join_request_repository.dart';
import '../domain/repositories/nearby_match_repository.dart';
import '../domain/repositories/venue_repository.dart';
import '../domain/usecases/approve_join_request.dart';
import '../domain/usecases/cancel_join_request.dart';
import '../domain/usecases/decline_join_request.dart';
import '../domain/usecases/discover_nearby_matches.dart';
import '../domain/usecases/get_match_join_requests.dart';
import '../domain/usecases/request_to_join_match.dart';

final nearbyMatchRepositoryProvider = Provider<NearbyMatchRepository>((ref) {
  return NearbyMatchRepositoryImpl(ref.watch(appwriteServiceProvider));
});

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return VenueRepositoryImpl(ref.watch(appwriteServiceProvider));
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return JoinRequestRepositoryImpl(ref.watch(appwriteServiceProvider));
});

final discoveryBlockRepositoryProvider = Provider<DiscoveryBlockRepository>((ref) {
  return DiscoveryBlockRepositoryImpl(ref.watch(appwriteServiceProvider));
});

final discoverNearbyMatchesProvider = Provider<DiscoverNearbyMatches>((ref) {
  return DiscoverNearbyMatches(
    ref.watch(nearbyMatchRepositoryProvider),
    ref.watch(discoveryBlockRepositoryProvider),
  );
});

final requestToJoinMatchProvider = Provider<RequestToJoinMatch>((ref) {
  return RequestToJoinMatch(
    ref.watch(joinRequestRepositoryProvider),
    ref.watch(nearbyMatchRepositoryProvider),
  );
});

final getMatchJoinRequestsProvider = Provider<GetMatchJoinRequests>((ref) {
  return GetMatchJoinRequests(ref.watch(joinRequestRepositoryProvider));
});

final approveJoinRequestProvider = Provider<ApproveJoinRequest>((ref) {
  return ApproveJoinRequest(
    ref.watch(joinRequestRepositoryProvider),
    ref.watch(nearbyMatchRepositoryProvider),
  );
});

final declineJoinRequestProvider = Provider<DeclineJoinRequest>((ref) {
  return DeclineJoinRequest(ref.watch(joinRequestRepositoryProvider));
});

final cancelJoinRequestProvider = Provider<CancelJoinRequest>((ref) {
  return CancelJoinRequest(ref.watch(joinRequestRepositoryProvider));
});
