import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/features/find_nearby/domain/entities/venue.dart';
import 'package:footheroes/services/nominatim_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/appwrite_service.dart';

/// Holds the user's home location — loaded from Appwrite, GPS, or manual search.
class UserLocationState {
  final LatLng? location;
  final String? locationName;
  final bool isLoaded;
  final bool isSaving;
  final String? error;

  const UserLocationState({
    this.location,
    this.locationName,
    this.isLoaded = false,
    this.isSaving = false,
    this.error,
  });

  UserLocationState copyWith({
    LatLng? location,
    String? locationName,
    bool? isLoaded,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return UserLocationState(
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  final AppwriteService _appwriteService;
  final NominatimService _nominatimService;
  Timer? _debounce;

  UserLocationNotifier(this._appwriteService, this._nominatimService)
      : super(const UserLocationState());

  /// Load saved location from Appwrite, falling back to GPS.
  Future<void> loadLocation(String userId) async {
    // Try Appwrite first
    final saved = await _appwriteService.getUserLocation(userId);
    if (saved != null && saved['latitude'] != null && saved['longitude'] != null) {
      state = UserLocationState(
        location: LatLng(
          saved['latitude'] as double,
          saved['longitude'] as double,
        ),
        locationName: saved['locationName'] as String?,
        isLoaded: true,
      );
      return;
    }

    // Fall back to GPS
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final permission2 = await Geolocator.checkPermission();
      if (permission2 == LocationPermission.whileInUse ||
          permission2 == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        state = UserLocationState(
          location: LatLng(position.latitude, position.longitude),
          isLoaded: true,
        );
        return;
      }
    } catch (_) {}

    // Nothing worked — user must search
    state = state.copyWith(isLoaded: true, error: 'Enter your location to find matches');
  }

  /// Search for a location via Nominatim.
  void searchLocation(String query) {
    if (query.trim().length < 2) {
      _debounce?.cancel();
      state = state.copyWith(clearError: true);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _nominatimService.search(query);
        if (results.isNotEmpty) {
          final v = results.first;
          state = state.copyWith(clearError: true);
          await _selectAndSave(v);
        }
      } catch (_) {}
    });
  }

  /// Select a venue/location and persist to Appwrite.
  Future<void> selectAndSaveLocation(Venue venue, String userId) async {
    await _selectAndSave(venue, userId: userId);
  }

  Future<void> _selectAndSave(Venue venue, {String? userId}) async {
    final loc = LatLng(venue.latitude, venue.longitude);
    state = state.copyWith(
      location: loc,
      locationName: venue.name,
      isSaving: true,
      clearError: true,
    );

    if (userId != null) {
      try {
        await _appwriteService.updateUserLocation(
          userId: userId,
          latitude: venue.latitude,
          longitude: venue.longitude,
          locationName: venue.name,
        );
      } catch (_) {}
    }

    state = state.copyWith(isSaving: false);
  }

  /// Set location from GPS without saving.
  void setGpsLocation(LatLng loc) {
    state = state.copyWith(location: loc, isLoaded: true, clearError: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  final nominatimService = ref.watch(nominatimServiceProvider);
  return UserLocationNotifier(appwriteService, nominatimService);
});
