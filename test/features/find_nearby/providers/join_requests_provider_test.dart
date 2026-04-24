import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:footheroes/features/find_nearby/domain/entities/join_request.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/join_request_repository.dart';
import 'package:footheroes/features/find_nearby/providers/join_requests_provider.dart';
import 'package:footheroes/features/find_nearby/providers/repositories_provider.dart';

class MockJoinRequestRepository extends Mock implements JoinRequestRepository {}

void main() {
  late MockJoinRequestRepository repo;

  final testRequest = JoinRequest(
    id: 'r1',
    matchId: 'm1',
    requesterUid: 'u1',
    requesterPosition: 'GK',
    status: JoinRequestStatus.pending,
    createdAt: DateTime.now(),
  );

  ProviderContainer createContainer() {
    repo = MockJoinRequestRepository();
    return ProviderContainer(
      overrides: [
        joinRequestRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  group('MatchJoinRequestsNotifier', () {
    test('loads pending requests on build', () async {
      final container = createContainer();
      when(() => repo.getPendingForMatch('m1')).thenAnswer(
        (_) async => [testRequest],
      );

      final future = container.read(matchJoinRequestsNotifierProvider('m1').future);
      final result = await future;

      expect(result.length, 1);
      expect(result.first.id, 'r1');
    });

    test('refresh reloads requests', () async {
      final container = createContainer();
      when(() => repo.getPendingForMatch('m1')).thenAnswer(
        (_) async => [testRequest],
      );

      await container.read(matchJoinRequestsNotifierProvider('m1').future);
      final notifier = container.read(
        matchJoinRequestsNotifierProvider('m1').notifier,
      );
      await notifier.refresh();

      verify(() => repo.getPendingForMatch('m1')).called(2);
    });
  });

  group('MyJoinRequestsNotifier', () {
    test('loads user requests on build', () async {
      final container = createContainer();
      when(() => repo.getByRequester('u1')).thenAnswer(
        (_) async => [testRequest],
      );

      final future = container.read(myJoinRequestsNotifierProvider('u1').future);
      final result = await future;

      expect(result.length, 1);
    });
  });
}
