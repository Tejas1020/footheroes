import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:footheroes/features/find_nearby/domain/entities/nearby_match.dart';
import 'package:footheroes/features/find_nearby/domain/entities/playing_position.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/discovery_block_repository.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/nearby_match_repository.dart';
import 'package:footheroes/features/find_nearby/domain/usecases/discover_nearby_matches.dart';

class MockNearbyMatchRepository extends Mock implements NearbyMatchRepository {}

class MockDiscoveryBlockRepository extends Mock
    implements DiscoveryBlockRepository {}

void main() {
  late DiscoverNearbyMatches usecase;
  late MockNearbyMatchRepository matchRepo;
  late MockDiscoveryBlockRepository blockRepo;

  final baseMatch = NearbyMatch(
    id: 'm1',
    latitude: 51.5074,
    longitude: -0.1278,
    format: '5-a-side',
    startTime: DateTime.now().add(const Duration(hours: 2)),
    openToNearby: true,
    slotsNeeded: 10,
    slotsRemaining: 5,
    requiredPositions: const [PlayingPosition.any],
    createdBy: 'creator1',
  );

  setUp(() {
    matchRepo = MockNearbyMatchRepository();
    blockRepo = MockDiscoveryBlockRepository();
    usecase = DiscoverNearbyMatches(matchRepo, blockRepo);
  });

  group('DiscoverNearbyMatches', () {
    test('returns empty list for empty prefixes', () async {
      when(() => matchRepo.findByGeohashPrefixes(any())).thenAnswer(
        (_) async => [],
      );

      final result = await usecase(
        const DiscoverNearbyMatchesParams(
          latitude: 51.5074,
          longitude: -0.1278,
          radiusKm: 10,
        ),
      );

      expect(result, isEmpty);
    });

    test('filters by exact distance', () async {
      when(() => matchRepo.findByGeohashPrefixes(any())).thenAnswer(
        (_) async => [
          baseMatch,
          baseMatch.copyWith(
            id: 'm2',
            latitude: 52.0,
            longitude: 0.0,
          ),
        ],
      );
      when(() => blockRepo.isBlocked(any(), any())).thenAnswer(
        (_) async => false,
      );

      final result = await usecase(
        const DiscoverNearbyMatchesParams(
          latitude: 51.5074,
          longitude: -0.1278,
          radiusKm: 10,
        ),
      );

      expect(result.length, 1);
      expect(result.first.id, 'm1');
    });

    test('filters by player position', () async {
      when(() => matchRepo.findByGeohashPrefixes(any())).thenAnswer(
        (_) async => [
          baseMatch.copyWith(
            requiredPositions: const [PlayingPosition.gk],
          ),
          baseMatch.copyWith(
            id: 'm2',
            requiredPositions: const [PlayingPosition.att],
          ),
        ],
      );
      when(() => blockRepo.isBlocked(any(), any())).thenAnswer(
        (_) async => false,
      );

      final result = await usecase(
        const DiscoverNearbyMatchesParams(
          latitude: 51.5074,
          longitude: -0.1278,
          radiusKm: 100,
          playerPosition: 'GK',
        ),
      );

      expect(result.length, 1);
      expect(result.first.requiredPositions.first, PlayingPosition.gk);
    });

    test('filters blocked creators', () async {
      when(() => matchRepo.findByGeohashPrefixes(any())).thenAnswer(
        (_) async => [
          baseMatch.copyWith(createdBy: 'creator1'),
          baseMatch.copyWith(id: 'm2', createdBy: 'creator2'),
        ],
      );
      when(() => blockRepo.isBlocked('creator1', 'player1')).thenAnswer(
        (_) async => true,
      );
      when(() => blockRepo.isBlocked('creator2', 'player1')).thenAnswer(
        (_) async => false,
      );

      final result = await usecase(
        const DiscoverNearbyMatchesParams(
          latitude: 51.5074,
          longitude: -0.1278,
          radiusKm: 100,
          playerUid: 'player1',
        ),
      );

      expect(result.length, 1);
      expect(result.first.createdBy, 'creator2');
    });
  });
}

extension NearbyMatchCopy on NearbyMatch {
  NearbyMatch copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? format,
    DateTime? startTime,
    bool? openToNearby,
    int? slotsNeeded,
    int? slotsRemaining,
    List<PlayingPosition>? requiredPositions,
    String? createdBy,
  }) {
    return NearbyMatch(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      format: format ?? this.format,
      startTime: startTime ?? this.startTime,
      openToNearby: openToNearby ?? this.openToNearby,
      slotsNeeded: slotsNeeded ?? this.slotsNeeded,
      slotsRemaining: slotsRemaining ?? this.slotsRemaining,
      requiredPositions: requiredPositions ?? this.requiredPositions,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
