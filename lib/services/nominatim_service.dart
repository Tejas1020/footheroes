import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/features/find_nearby/domain/entities/venue.dart';
import 'package:footheroes/core/utils/geohash_utils.dart';

/// Searches real locations via OpenStreetMap Nominatim API.
class NominatimService {
  static const _userAgent = 'FootHeroesApp/1.0';

  Future<List<Venue>> search(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.trim(),
      'format': 'json',
      'limit': '15',
      'addressdetails': '1',
    });

    final response = await http.get(uri, headers: {
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) return [];

    final List data = jsonDecode(response.body);
    return data.map((item) {
      final lat = double.parse(item['lat'] as String);
      final lon = double.parse(item['lon'] as String);
      final fullName = item['display_name'] as String;
      final name = fullName.split(',').first.trim();

      return Venue(
        id: '',
        name: name,
        address: fullName,
        latitude: lat,
        longitude: lon,
        geohash: GeohashUtils.encode(lon, lat, 6),
        createdBy: '',
        createdAt: DateTime.now(),
      );
    }).toList();
  }
}

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});

/// Search result state for Nominatim
final nominatimSearchProvider =
    StateNotifierProvider<NominatimSearchNotifier, AsyncValue<List<Venue>>>((ref) {
  return NominatimSearchNotifier(ref.read(nominatimServiceProvider));
});

class NominatimSearchNotifier extends StateNotifier<AsyncValue<List<Venue>>> {
  final NominatimService _service;
  Timer? _debounce;
  String _currentQuery = '';

  NominatimSearchNotifier(this._service) : super(const AsyncData([]));

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _debounce?.cancel();
      state = const AsyncData([]);
      return;
    }
    _currentQuery = trimmed;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      try {
        final results = await _service.search(_currentQuery);
        state = AsyncData(results);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    _currentQuery = '';
    state = const AsyncData([]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
