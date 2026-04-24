import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../domain/entities/venue.dart';
import '../../../../services/nominatim_service.dart';

/// Search venues via OSM Nominatim, see location on map, then select.
class VenuePickerScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const VenuePickerScreen({super.key, this.onBack});

  @override
  ConsumerState<VenuePickerScreen> createState() => _VenuePickerScreenState();
}

class _VenuePickerScreenState extends ConsumerState<VenuePickerScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _focusNode = FocusNode();
  LatLng? _selectedLocation;
  Venue? _selectedVenue;
  bool _showResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().length >= 2) {
      _showResults = true;
      ref.read(nominatimSearchProvider.notifier).search(query);
    } else {
      _showResults = false;
      ref.read(nominatimSearchProvider.notifier).clear();
    }
    setState(() {});
  }

  void _selectVenue(Venue venue) {
    setState(() {
      _selectedVenue = venue;
      _selectedLocation = LatLng(venue.latitude, venue.longitude);
      _showResults = false;
    });
    _mapController.move(
      LatLng(venue.latitude, venue.longitude),
      15,
    );
    _searchController.text = venue.name;
    _focusNode.unfocus();
    ref.read(nominatimSearchProvider.notifier).clear();
  }

  void _confirmVenue() {
    if (_selectedVenue != null) {
      Navigator.of(context).pop(_selectedVenue);
    } else if (_selectedLocation != null) {
      final auth = ref.read(authProvider);
      final venue = Venue(
        id: '',
        name: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : 'Custom Location',
        address: null,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        geohash: '',
        createdBy: auth.userId ?? '',
        createdAt: DateTime.now(),
      );
      Navigator.of(context).pop(venue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchField(),
            _buildSearchResults(),
            Expanded(child: _buildMap()),
            _buildBottomBar(),
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
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: AppTheme.cardBorder,
              ),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppTheme.parchment, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'SELECT VENUE',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 20, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: AppTheme.cardBorder,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: AppTheme.dmSans.copyWith(color: AppTheme.parchment, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search venue name...',
            hintStyle: AppTheme.dmSans.copyWith(color: AppTheme.mutedParchment, fontSize: 15),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gold, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _focusNode.unfocus();
                      _showResults = false;
                      ref.read(nominatimSearchProvider.notifier).clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, color: AppTheme.gold, size: 20),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_showResults) return const SizedBox.shrink();

    final searchAsync = ref.watch(nominatimSearchProvider);
    final query = _searchController.text.trim();
    if (query.length < 2) return const SizedBox.shrink();

    return searchAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(12),
          border: AppTheme.cardBorder,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cardinal),
            ),
            SizedBox(width: 12),
            Text('Searching...', style: TextStyle(color: AppTheme.gold, fontSize: 13)),
          ],
        ),
      ),
      error: (err, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.abyss,
          borderRadius: BorderRadius.circular(12),
          border: AppTheme.cardBorder,
        ),
        child: Text('Search error: $err',
          style: AppTheme.dmSans.copyWith(fontSize: 12, color: AppTheme.cardinal)),
      ),
      data: (venues) {
        if (venues.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.abyss,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.cardBorder,
            ),
            child: const Text('No results found',
              style: TextStyle(color: AppTheme.gold, fontSize: 13)),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 220),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.abyss,
            borderRadius: BorderRadius.circular(12),
            border: AppTheme.cardBorder,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: venues.length,
            itemBuilder: (_, i) {
              final v = venues[i];
              return InkWell(
                onTap: () => _selectVenue(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, color: AppTheme.cardinal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: AppTheme.bodyBold.copyWith(fontSize: 13)),
                            if (v.address != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  v.address!.split(',').skip(1).take(3).join(','),
                                  style: AppTheme.dmSans.copyWith(fontSize: 11, color: AppTheme.gold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(51.5, -0.09),
        initialZoom: 5,
        onTap: (_, latLng) {
          setState(() {
            _selectedLocation = latLng;
            _selectedVenue = null;
          });
          _searchController.clear();
          _showResults = false;
          ref.read(nominatimSearchProvider.notifier).clear();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.footheroes.app',
        ),
        if (_selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: AppTheme.cardinal, size: 36),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.abyss,
        border: Border(top: BorderSide(color: AppTheme.cardBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedVenue != null)
                  Text(
                    _selectedVenue!.name,
                    style: AppTheme.bodyBold.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _selectedLocation != null
                      ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                          '${_selectedLocation!.longitude.toStringAsFixed(4)}'
                      : 'Tap on map or search for a venue',
                  style: AppTheme.dmSans.copyWith(fontSize: 11, color: AppTheme.gold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _selectedLocation != null ? _confirmVenue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cardinal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppTheme.elevatedSurface,
            ),
            child: Text(
              _selectedVenue != null ? 'SELECT' : 'USE PIN',
              style: AppTheme.dmSans.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
