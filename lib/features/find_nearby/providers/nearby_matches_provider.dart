import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/nearby_match.dart';
import '../domain/usecases/discover_nearby_matches.dart';
import 'repositories_provider.dart';

part 'nearby_matches_provider.g.dart';

@riverpod
class NearbyMatchesNotifier extends _$NearbyMatchesNotifier {
  @override
  Future<List<NearbyMatch>> build() async {
    return const [];
  }

  Future<void> discover({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? playerPosition,
    String? playerUid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.read(discoverNearbyMatchesProvider);
      return usecase(DiscoverNearbyMatchesParams(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        playerPosition: playerPosition,
        playerUid: playerUid,
      ));
    });
  }

  Future<void> refresh({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? playerPosition,
    String? playerUid,
  }) async {
    return discover(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      playerPosition: playerPosition,
      playerUid: playerUid,
    );
  }
}
