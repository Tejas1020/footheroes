import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:footheroes/features/find_nearby/domain/entities/join_request.dart';
import 'package:footheroes/features/find_nearby/domain/entities/nearby_match.dart';
import 'package:footheroes/features/find_nearby/domain/entities/playing_position.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/join_request_repository.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/nearby_match_repository.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/approve_join_request.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/cancel_join_request.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/decline_join_request.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/get_match_join_requests.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/request_to_join_match.dart';

class MockJoinRequestRepository extends Mock implements JoinRequestRepository {}

class MockNearbyMatchRepository extends Mock implements NearbyMatchRepository {}

void main() {
  late MockJoinRequestRepository joinRequestRepo;
  late MockNearbyMatchRepository matchRepo;

  final testMatch = NearbyMatch(
    id: 'match1',
    format: '5-a-side',
    startTime: DateTime.now().add(const Duration(hours: 2)),
    openToNearby: true,
    slotsNeeded: 10,
    slotsRemaining: 3,
    requiredPositions: const [PlayingPosition.any],
    createdBy: 'creator1',
  );

  final testRequest = JoinRequest(
    id: 'req1',
    matchId: 'match1',
    requesterUid: 'player1',
    requesterPosition: 'GK',
    status: JoinRequestStatus.pending,
    createdAt: DateTime.now(),
  );

  setUp(() {
    joinRequestRepo = MockJoinRequestRepository();
    matchRepo = MockNearbyMatchRepository();
  });

  group('RequestToJoinMatch', () {
    late RequestToJoinMatch usecase;

    setUp(() {
      usecase = RequestToJoinMatch(joinRequestRepo, matchRepo);
    });

    test('throws when match not found', () async {
      when(() => matchRepo.getById('match1')).thenAnswer((_) async => null);

      expect(
        () => usecase(
          const RequestToJoinMatchParams(
            matchId: 'match1',
            requesterUid: 'player1',
            requesterPosition: 'GK',
          ),
        ),
        throwsException,
      );
    });

    test('throws when match not open', () async {
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch.copyWith(openToNearby: false),
      );

      expect(
        () => usecase(
          const RequestToJoinMatchParams(
            matchId: 'match1',
            requesterUid: 'player1',
            requesterPosition: 'GK',
          ),
        ),
        throwsException,
      );
    });

    test('throws when player has 3 open requests', () async {
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch,
      );
      when(() => joinRequestRepo.getByRequester('player1')).thenAnswer(
        (_) async => [
          testRequest.copyWith(id: 'r1'),
          testRequest.copyWith(id: 'r2'),
          testRequest.copyWith(id: 'r3'),
        ],
      );

      expect(
        () => usecase(
          const RequestToJoinMatchParams(
            matchId: 'match1',
            requesterUid: 'player1',
            requesterPosition: 'GK',
          ),
        ),
        throwsException,
      );
    });

    test('creates request successfully', () async {
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch,
      );
      when(() => joinRequestRepo.getByRequester('player1')).thenAnswer(
        (_) async => [testRequest],
      );
      when(
        () => joinRequestRepo.create(
          matchId: any(named: 'matchId'),
          requesterUid: any(named: 'requesterUid'),
          requesterPosition: any(named: 'requesterPosition'),
          requesterMessage: any(named: 'requesterMessage'),
        ),
      ).thenAnswer((_) async => testRequest);

      final result = await usecase(
        const RequestToJoinMatchParams(
          matchId: 'match1',
          requesterUid: 'player1',
          requesterPosition: 'GK',
        ),
      );

      expect(result.status, JoinRequestStatus.pending);
      verify(
        () => joinRequestRepo.create(
          matchId: 'match1',
          requesterUid: 'player1',
          requesterPosition: 'GK',
          requesterMessage: null,
        ),
      ).called(1);
    });

    test('waitlists when match is full', () async {
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch.copyWith(slotsRemaining: 0),
      );
      when(
        () => joinRequestRepo.create(
          matchId: any(named: 'matchId'),
          requesterUid: any(named: 'requesterUid'),
          requesterPosition: any(named: 'requesterPosition'),
          requesterMessage: any(named: 'requesterMessage'),
        ),
      ).thenAnswer((_) async => testRequest);

      final result = await usecase(
        const RequestToJoinMatchParams(
          matchId: 'match1',
          requesterUid: 'player1',
          requesterPosition: 'GK',
        ),
      );

      expect(result, isNotNull);
    });
  });

  group('ApproveJoinRequest', () {
    late ApproveJoinRequest usecase;

    setUp(() {
      usecase = ApproveJoinRequest(joinRequestRepo, matchRepo);
    });

    test('approves and decrements slots', () async {
      when(() => joinRequestRepo.getById('req1')).thenAnswer(
        (_) async => testRequest,
      );
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch,
      );
      when(() => joinRequestRepo.approve('req1', 'home')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.approved,
          assignedSide: AssignedSide.home,
        ),
      );
      when(
        () => matchRepo.update('match1', any()),
      ).thenAnswer((_) async => testMatch);

      final result = await usecase('req1', 'home');

      expect(result.status, JoinRequestStatus.approved);
      verify(
        () => matchRepo.update('match1', {
          'slotsRemaining': 2,
        }),
      ).called(1);
    });

    test('closes match when last slot filled', () async {
      when(() => joinRequestRepo.getById('req1')).thenAnswer(
        (_) async => testRequest,
      );
      when(() => matchRepo.getById('match1')).thenAnswer(
        (_) async => testMatch.copyWith(slotsRemaining: 1),
      );
      when(() => joinRequestRepo.approve('req1', 'away')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.approved,
          assignedSide: AssignedSide.away,
        ),
      );
      when(
        () => matchRepo.update('match1', any()),
      ).thenAnswer((_) async => testMatch);

      await usecase('req1', 'away');

      verify(
        () => matchRepo.update('match1', {
          'slotsRemaining': 0,
          'openToNearby': false,
        }),
      ).called(1);
    });

    test('throws when request not pending', () async {
      when(() => joinRequestRepo.getById('req1')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.approved,
        ),
      );

      expect(
        () => usecase('req1', 'home'),
        throwsException,
      );
    });
  });

  group('DeclineJoinRequest', () {
    late DeclineJoinRequest usecase;

    setUp(() {
      usecase = DeclineJoinRequest(joinRequestRepo);
    });

    test('declines pending request', () async {
      when(() => joinRequestRepo.getById('req1')).thenAnswer(
        (_) async => testRequest,
      );
      when(() => joinRequestRepo.decline('req1')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.declined,
        ),
      );

      final result = await usecase('req1');

      expect(result.status, JoinRequestStatus.declined);
    });

    test('throws when already declined', () async {
      when(() => joinRequestRepo.getById('req1')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.declined,
        ),
      );

      expect(
        () => usecase('req1'),
        throwsException,
      );
    });
  });

  group('GetMatchJoinRequests', () {
    late GetMatchJoinRequests usecase;

    setUp(() {
      usecase = GetMatchJoinRequests(joinRequestRepo);
    });

    test('returns pending requests for match', () async {
      when(
        () => joinRequestRepo.getPendingForMatch('match1'),
      ).thenAnswer((_) async => [testRequest]);

      final result = await usecase('match1');

      expect(result.length, 1);
      expect(result.first.matchId, 'match1');
    });
  });

  group('CancelJoinRequest', () {
    late CancelJoinRequest usecase;

    setUp(() {
      usecase = CancelJoinRequest(joinRequestRepo);
    });

    test('cancels request', () async {
      when(() => joinRequestRepo.cancel('req1')).thenAnswer(
        (_) async => testRequest.copyWith(
          status: JoinRequestStatus.cancelled,
        ),
      );

      final result = await usecase('req1');

      expect(result.status, JoinRequestStatus.cancelled);
    });
  });
}

extension JoinRequestCopy on JoinRequest {
  JoinRequest copyWith({
    String? id,
    String? matchId,
    String? requesterUid,
    String? requesterPosition,
    String? requesterMessage,
    JoinRequestStatus? status,
    AssignedSide? assignedSide,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      requesterUid: requesterUid ?? this.requesterUid,
      requesterPosition: requesterPosition ?? this.requesterPosition,
      requesterMessage: requesterMessage ?? this.requesterMessage,
      status: status ?? this.status,
      assignedSide: assignedSide ?? this.assignedSide,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

extension NearbyMatchCopy on NearbyMatch {
  NearbyMatch copyWith({
    String? id,
    bool? openToNearby,
    int? slotsRemaining,
  }) {
    return NearbyMatch(
      id: id ?? this.id,
      format: format,
      startTime: startTime,
      openToNearby: openToNearby ?? this.openToNearby,
      slotsNeeded: slotsNeeded,
      slotsRemaining: slotsRemaining ?? this.slotsRemaining,
      requiredPositions: requiredPositions,
      createdBy: createdBy,
    );
  }
}
