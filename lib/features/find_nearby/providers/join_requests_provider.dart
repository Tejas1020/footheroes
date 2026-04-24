import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/join_request.dart';
import 'repositories_provider.dart';

part 'join_requests_provider.g.dart';

@riverpod
class MatchJoinRequestsNotifier extends _$MatchJoinRequestsNotifier {
  @override
  Future<List<JoinRequest>> build(String matchId) async {
    final usecase = ref.read(getMatchJoinRequestsProvider);
    return usecase(matchId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(getMatchJoinRequestsProvider);
      return usecase(matchId);
    });
  }
}

@riverpod
class MyJoinRequestsNotifier extends _$MyJoinRequestsNotifier {
  @override
  Future<List<JoinRequest>> build(String requesterUid) async {
    final repo = ref.read(joinRequestRepositoryProvider);
    return repo.getByRequester(requesterUid);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(joinRequestRepositoryProvider);
      return repo.getByRequester(requesterUid);
    });
  }
}
