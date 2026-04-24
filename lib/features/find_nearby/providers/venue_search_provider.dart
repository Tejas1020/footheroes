import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/venue.dart';
import 'repositories_provider.dart';

part 'venue_search_provider.g.dart';

@riverpod
class VenueSearchNotifier extends _$VenueSearchNotifier {
  @override
  Future<List<Venue>> build() async {
    return const [];
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(venueRepositoryProvider);
      return repo.searchByName(query);
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}
