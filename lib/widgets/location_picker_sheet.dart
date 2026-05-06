import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/features/find_nearby/domain/entities/venue.dart';
import 'package:footheroes/features/find_nearby/providers/user_location_provider.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/services/nominatim_service.dart';

/// Full-height bottom sheet: search/select location on OSM map, save to Appwrite.
class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _searchFocus = FocusNode();
  LatLng? _pickedLocation;
  String? _pickedName;
  List<Venue> _searchResults = [];
  bool _showResults = false;
  Timer? _debounce;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final locState = ref.read(userLocationProvider);
    if (locState.location != null) {
      _pickedLocation = locState.location;
      _pickedName = locState.locationName;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await ref.read(nominatimServiceProvider).search(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _showResults = true;
      });
    });
  }

  void _selectVenue(Venue venue) {
    final loc = LatLng(venue.latitude, venue.longitude);
    setState(() {
      _pickedLocation = loc;
      _pickedName = venue.name;
      _showResults = false;
      _searchResults = [];
    });
    _searchController.text = venue.name;
    _searchFocus.unfocus();
    _mapController.move(loc, 14);
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _pickedLocation = point;
      _pickedName = null;
    });
    _searchController.clear();
    _showResults = false;
    _searchResults = [];
  }

  Future<void> _useGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final permission2 = await Geolocator.checkPermission();
      if (permission2 == LocationPermission.whileInUse ||
          permission2 == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        final loc = LatLng(position.latitude, position.longitude);
        setState(() {
          _pickedLocation = loc;
          _pickedName = 'Current Location';
        });
        _searchController.clear();
        _searchFocus.unfocus();
        _mapController.move(loc, 14);
      }
    } catch (_) {}
  }

  Future<void> _saveLocation() async {
    if (_pickedLocation == null) return;
    setState(() => _saving = true);

    final auth = ref.read(authProvider);
    final name = _pickedName ??
        (_searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : 'Picked Location');

    // Use Nominatim reverse geocode to get a proper name if none set
    String locationName = name;
    if (_pickedName == null && _searchController.text.trim().isEmpty) {
      try {
        final results = await ref.read(nominatimServiceProvider).search(
            '${_pickedLocation!.latitude.toStringAsFixed(4)} ${_pickedLocation!.longitude.toStringAsFixed(4)}');
        if (results.isNotEmpty) {
          locationName = results.first.name;
        }
      } catch (_) {}
    }

    final venue = Venue(
      id: '',
      name: locationName,
      address: null,
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      geohash: '',
      createdBy: auth.userId ?? '',
      createdAt: DateTime.now(),
    );

    await ref
        .read(userLocationProvider.notifier)
        .selectAndSaveLocation(venue, auth.userId ?? '');

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  LatLng get _mapCenter {
    if (_pickedLocation != null) return _pickedLocation!;
    final locState = ref.read(userLocationProvider);
    if (locState.location != null) return locState.location!;
    return const LatLng(51.5, -0.09); // London default
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.abyss,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set Your Location',
                style: AppTheme.bodyBold.copyWith(
                  fontSize: 16,
                  color: AppTheme.parchment,
                ),
              ),
              const SizedBox(height: 8),
              // Search bar
              _buildSearchBar(),
              // Search results
              _buildSearchResults(),
              // Map
              Expanded(child: _buildMap()),
              // Bottom bar
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: AppTheme.cardBorder,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: AppTheme.dmSans.copyWith(
                  color: AppTheme.parchment,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search city, area or postcode...',
                  hintStyle: AppTheme.dmSans.copyWith(
                    color: AppTheme.mutedParchment,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.gold, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _showResults = false;
                            _searchResults = [];
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.gold, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.sparkBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _useGps,
                icon: const Icon(Icons.my_location, size: 18),
                color: AppTheme.sparkBlue,
                padding: EdgeInsets.zero,
                tooltip: 'Use GPS',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_showResults || _searchResults.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: AppTheme.cardBorder,
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (_, i) {
          final v = _searchResults[i];
          return InkWell(
            onTap: () => _selectVenue(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppTheme.cardinal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: AppTheme.bodyBold.copyWith(fontSize: 12)),
                        if (v.address != null)
                          Text(
                            v.address!.split(',').skip(1).take(3).join(','),
                            style: AppTheme.dmSans.copyWith(
                                fontSize: 10, color: AppTheme.gold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (v.type != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cardinal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        v.type!,
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.cardinal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: _pickedLocation != null ? 14 : 5,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.footheroes.app',
            ),
            if (_pickedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin,
                        color: AppTheme.cardinal, size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _pickedLocation != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.voidBg,
        border: Border(top: BorderSide(color: AppTheme.cardBorderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pickedName != null)
                    Text(
                      _pickedName!,
                      style: AppTheme.bodyBold.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    _pickedLocation != null
                        ? '${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}'
                        : 'Search or tap the map to pick a location',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: hasSelection && !_saving ? _saveLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardinal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppTheme.elevatedSurface,
                disabledForegroundColor: AppTheme.mutedParchment,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'SAVE LOCATION',
                      style: AppTheme.dmSans.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the location picker as a bottom sheet.
void showLocationPickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LocationPickerSheet(),
  );
}
