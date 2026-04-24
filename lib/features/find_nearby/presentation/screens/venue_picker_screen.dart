import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/midnight_pitch_theme.dart';
import '../../../../core/utils/geohash_utils.dart';
import '../../../../providers/auth_provider.dart';
import '../../domain/entities/venue.dart';
import '../../providers/venue_search_provider.dart';

/// Pick or create a venue for a match.
class VenuePickerScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const VenuePickerScreen({super.key, this.onBack});

  @override
  ConsumerState<VenuePickerScreen> createState() => _VenuePickerScreenState();
}

class _VenuePickerScreenState extends ConsumerState<VenuePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng? _pinLocation;
  String? _pinAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _pinLocation = latLng);
      _mapController.move(latLng, 15);
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (query.trim().length >= 2) {
      ref.read(venueSearchNotifierProvider.notifier).search(query);
    } else {
      ref.read(venueSearchNotifierProvider.notifier).clear();
    }
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    setState(() => _pinLocation = latLng);
  }

  void _selectVenue(Venue venue) {
    context.pop(venue);
  }

  void _confirmCustomVenue() {
    if (_pinLocation == null) return;
    final name = _searchController.text.trim().isEmpty
        ? 'Custom Location'
        : _searchController.text.trim();
    final auth = ref.read(authProvider);
    final venue = Venue(
      id: '',
      name: name,
      address: _pinAddress,
      latitude: _pinLocation!.latitude,
      longitude: _pinLocation!.longitude,
      geohash: GeohashUtils.encode(
        _pinLocation!.longitude,
        _pinLocation!.latitude,
        6,
      ),
      createdBy: auth.userId ?? '',
      createdAt: DateTime.now(),
    );
    context.pop(venue);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(venueSearchNotifierProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchField(),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pinLocation ?? const LatLng(51.5, -0.09),
                      initialZoom: _pinLocation != null ? 15 : 5,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.footheroes.app',
                      ),
                      if (_pinLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pinLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: MidnightPitchTheme.cardinal,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: FloatingActionButton.small(
                      onPressed: _initLocation,
                      backgroundColor: MidnightPitchTheme.cardSurface,
                      child: const Icon(
                        Icons.my_location,
                        color: MidnightPitchTheme.parchment,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchResults(searchAsync),
            _buildConfirmBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: MidnightPitchTheme.parchment,
            ),
          Expanded(
            child: Text(
              'Pick Venue',
              style: MidnightPitchTheme.dmSans.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.parchment,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: MidnightPitchTheme.parchment),
        decoration: InputDecoration(
          hintText: 'Search venue name...',
          hintStyle: TextStyle(color: MidnightPitchTheme.mutedParchment),
          prefixIcon: Icon(Icons.search, color: MidnightPitchTheme.steelBlue),
          filled: true,
          fillColor: MidnightPitchTheme.cardSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Venue>> searchAsync) {
    return searchAsync.when(
      data: (venues) {
        if (venues.isEmpty) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          color: MidnightPitchTheme.abyss,
          child: ListView.builder(
            itemCount: venues.length,
            itemBuilder: (_, i) {
              final v = venues[i];
              return ListTile(
                leading: Icon(Icons.place, color: MidnightPitchTheme.cardinal),
                title: Text(
                  v.name,
                  style: MidnightPitchTheme.dmSans.copyWith(
                    color: MidnightPitchTheme.parchment,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: v.address != null
                    ? Text(
                        v.address!,
                        style: MidnightPitchTheme.dmSans.copyWith(
                          color: MidnightPitchTheme.steelBlue,
                        ),
                      )
                    : null,
                onTap: () => _selectVenue(v),
              );
            },
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.abyss,
        border: Border(
          top: BorderSide(color: const Color(0x0AFFFFFF)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _pinLocation != null
                  ? 'Lat: ${_pinLocation!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_pinLocation!.longitude.toStringAsFixed(4)}'
                  : 'Tap map to drop pin',
              style: MidnightPitchTheme.dmSans.copyWith(
                fontSize: 12,
                color: MidnightPitchTheme.steelBlue,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _pinLocation != null ? _confirmCustomVenue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MidnightPitchTheme.cardinal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: MidnightPitchTheme.dmSans.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
