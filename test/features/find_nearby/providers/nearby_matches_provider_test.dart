import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:footheroes/features/find_nearby/domain/entities/nearby_match.dart';
import 'package:footheroes/features/find_nearby/domain/entities/playing_position.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/discovery_block_repository.dart';
import 'package:footheroes/features/find_nearby/domain/repositories/nearby_match_repository.dart';
import 'package:footheroes/features/find_nearby/providers/nearby_matches_provider.dart';
import 'package:footheroes/features/find_nearby/providers/repositories_provider.dart';

class MockNearbyMatchRepository extends Mock implements NearbyMatchRepository {}

class MockDiscoveryBlockRepository extends Mock
    implements DiscoveryBlockRepository {}

void main() {
  late MockNearbyMatchRepository matchRepo;
  late MockDiscoveryBlockRepository blockRepo;

  final testMatch = NearbyMatch(
    id: 'm1',
    latitude: 51.5,
    longitude: -0.1,
    format: '5-a-side',
    startTime: DateTime.now().add(const Duration(hours: 2)),
    openToNearby: true,
    slotsNeeded: 10,
    slotsRemaining: 5,
    requiredPositions: const [PlayingPosition.any],
    createdBy: 'creator1',
  );

  ProviderContainer createContainer() {
    matchRepo = MockNearbyMatchRepository();
    blockRepo = MockDiscoveryBlockRepository();

    return ProviderContainer(
      overrides: [
        nearbyMatchRepositoryProvider.overrideWithValue(matchRepo),
        discoveryBlockRepositoryProvider.overrideWithValue(blockRepo),
      ],
    );
  }

  group('NearbyMatchesNotifier', () {
    test('initial state is empty', () async {
      final container = createContainer();
      final state = await container.read(nearbyMatchesNotifierProvider.future);
      expect(state, isEmpty);
    });

    test('discovers matches', () async {
      final container = createContainer();
      when(() => matchRepo.findByGeohashPrefixes(any())).thenAnswer(
        (_) async => [testMatch],
      );
      when(() => blockRepo.isBlocked(any(), any())).thenAnswer(
        (_) async => false,
      );

      final notifier = container.read(nearbyMatchesNotifierProvider.notifier);
      await notifier.discover(
        latitude: 51.5,
        longitude: -0.1,
        radiusKm: 10,
      );

      final state = container.read(nearbyMatchesNotifierProvider);
      expect(state.valueOrNull?.length, 1);
      expect(state.valueOrNull?.first.id, 'm1');
    });

    test('handles errors gracefully', () async {
      final container = createContainer();
      when(() => matchRepo.findByGeohashPrefixes(any())).thenThrow(
        Exception('network error'),
      );

      final notifier = container.read(nearbyMatchesNotifierProvider.notifier);
      await notifier.discover(
        latitude: 51.5,
        longitude: -0.1,
        radiusKm: 10,
      );

      final state = container.read(nearbyMatchesNotifierProvider);
      expect(state.hasError, true);
    });
  });
}
