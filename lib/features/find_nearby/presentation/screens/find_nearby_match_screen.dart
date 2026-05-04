import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/features/find_nearby/domain/entities/venue.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/nominatim_service.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';
import '../../providers/nearby_matches_provider.dart';
import '../../providers/user_location_provider.dart';
import '../widgets/match_detail_sheet.dart';
import '../widgets/request_to_join_dialog.dart';

/// Discover open matches near your location.
/// Uses OSM map, Nominatim location search, Appwrite persistence.
class FindNearbyMatchScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const FindNearbyMatchScreen({super.key, this.onBack});

  @override
  ConsumerState<FindNearbyMatchScreen> createState() =>
      _FindNearbyMatchScreenState();
}

class _FindNearbyMatchScreenState extends ConsumerState<FindNearbyMatchScreen> {
  double _radiusKm = 10.0;
  String? _selectedFormat;
  PlayingPosition? _selectedPosition;
  bool _mapExpanded = true;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _mapController = MapController();
  List<Venue> _searchResults = [];
  bool _showResults = false;
  Timer? _searchDebounce;

  final List<String> _formats = const [
    '5-a-side',
    '7-a-side',
    '11-a-side',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScreen());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initScreen() async {
    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId == null) return;

    await ref.read(userLocationProvider.notifier).loadLocation(userId);
    _discover();

    // Listen for location changes to re-discover
    ref.listenManual(userLocationProvider, (prev, next) {
      if (prev?.location != next.location && next.location != null) {
        _mapController.move(next.location!, 13);
        _discover();
      }
    });
  }

  void _discover() {
    final locState = ref.read(userLocationProvider);
    final loc = locState.location;
    if (loc == null) return;
    final auth = ref.read(authProvider);
    ref.read(nearbyMatchesNotifierProvider.notifier).discover(
          latitude: loc.latitude,
          longitude: loc.longitude,
          radiusKm: _radiusKm,
          playerPosition: _selectedPosition?.value,
          playerUid: auth.userId,
        );
  }

  // ── LOCATION SEARCH ──────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results =
          await ref.read(nominatimServiceProvider).search(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _showResults = true;
      });
    });
  }

  Future<void> _selectLocation(Venue venue) async {
    final auth = ref.read(authProvider);
    setState(() {
      _showResults = false;
      _searchResults = [];
    });
    _searchController.text = venue.name;
    _searchFocus.unfocus();
    await ref
        .read(userLocationProvider.notifier)
        .selectAndSaveLocation(venue, auth.userId ?? '');
  }

  Future<void> _useGpsLocation() async {
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
        _searchController.clear();
        _searchFocus.unfocus();
        ref
            .read(userLocationProvider.notifier)
            .setGpsLocation(LatLng(position.latitude, position.longitude));
        _discover();
      }
    } catch (_) {}
  }

  // ── MATCH ACTIONS ────────────────────────────────────────────

  void _showMatchDetail(NearbyMatch match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MatchDetailSheet(
        match: match,
        onRequestToJoin: () => _onRequestToJoin(match),
      ),
    );
  }

  void _onRequestToJoin(NearbyMatch match) {
    context.pop();
    showDialog(
      context: context,
      builder: (_) => RequestToJoinDialog(
        match: match,
        onSent: () => _discover(),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(nearbyMatchesNotifierProvider);
    final locState = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildLocationSearch(locState),
            _buildSearchResults(),
            _buildFilters(),
            Expanded(
              child: _mapExpanded
                  ? _buildMapWithOverlay(matchesAsync, locState)
                  : _buildList(matchesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: AppTheme.voidBg.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppTheme.parchment,
                ),
              Expanded(
                child: Text(
                  'Find Nearby Matches',
                  style: AppTheme.bodyBold.copyWith(
                    fontSize: 20,
                    color: AppTheme.parchment,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
                icon: Icon(
                  _mapExpanded ? Icons.list_rounded : Icons.map_rounded,
                  color: AppTheme.parchment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSearch(UserLocationState locState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                  hintText: locState.locationName ?? 'Search your city or area...',
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
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.sparkBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _useGpsLocation,
                icon: const Icon(Icons.my_location, size: 18),
                color: AppTheme.sparkBlue,
                padding: EdgeInsets.zero,
                tooltip: 'Use GPS location',
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
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.abyss,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: AppTheme.cardBorderColor),
          right: BorderSide(color: AppTheme.cardBorderColor),
          bottom: BorderSide(color: AppTheme.cardBorderColor),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (_, i) {
          final v = _searchResults[i];
          return InkWell(
            onTap: () => _selectLocation(v),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.screenPadding,
        vertical: 10,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: '${_radiusKm.toStringAsFixed(0)} km',
            onTap: _showRadiusPicker,
            isActive: true,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedFormat ?? 'Any format',
            onTap: _showFormatPicker,
            isActive: _selectedFormat != null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedPosition?.value ?? 'Any position',
            onTap: _showPositionPicker,
            isActive: _selectedPosition != null,
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithOverlay(
      AsyncValue<List<NearbyMatch>> matchesAsync, UserLocationState locState) {
    final loc = locState.location;
    if (loc == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.cardinal),
            const SizedBox(height: 16),
            Text(
              locState.error ?? 'Loading location...',
              style: AppTheme.dmSans.copyWith(
                color: AppTheme.gold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (!locState.isLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Search for your city above',
                  style: AppTheme.dmSans.copyWith(
                    color: AppTheme.mutedParchment,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: loc,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.footheroes.app',
            ),
            MarkerLayer(
              markers: [
                _buildUserMarker(loc),
                ..._buildMatchMarkers(matchesAsync),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: AppTheme.screenPadding,
          left: AppTheme.screenPadding,
          right: AppTheme.screenPadding,
          child: _buildMatchListOverlay(matchesAsync),
        ),
      ],
    );
  }

  Marker _buildUserMarker(LatLng loc) {
    return Marker(
      point: loc,
      width: 44,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.sparkBlue,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sparkBlue.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.my_location, size: 20, color: Colors.white),
      ),
    );
  }

  List<Marker> _buildMatchMarkers(AsyncValue<List<NearbyMatch>> matchesAsync) {
    return matchesAsync.when(
      data: (matches) => matches
          .where((m) => m.latitude != null && m.longitude != null)
          .map((m) {
        return Marker(
          point: LatLng(m.latitude!, m.longitude!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showMatchDetail(m),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardinal,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.parchment, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cardinal.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.sports_soccer, size: 20, color: Colors.white),
            ),
          ),
        );
      }).toList(),
      loading: () => [],
      error: (_, _) => [],
    );
  }

  Widget _buildMatchListOverlay(AsyncValue<List<NearbyMatch>> matchesAsync) {
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 152,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.parchment.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: AppTheme.parchment.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: matches.length,
            itemBuilder: (_, i) => _MatchCard(
              match: matches[i],
              onTap: () => _showMatchDetail(matches[i]),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildList(AsyncValue<List<NearbyMatch>> matchesAsync) {
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return _buildEmptyState('No open matches nearby.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          itemCount: matches.length,
          itemBuilder: (_, i) => _MatchListTile(
            match: matches[i],
            onTap: () => _showMatchDetail(matches[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildEmptyState('Error: $err'),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: AppTheme.mutedParchment),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTheme.dmSans.copyWith(color: AppTheme.mutedParchment),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── FILTER PICKERS ───────────────────────────────────────────

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Text(
                'Search Radius',
                style: AppTheme.dmSans.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parchment),
              ),
            ),
            StatefulBuilder(
              builder: (context, setLocalState) {
                return Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radiusKm.toStringAsFixed(0)} km',
                  activeColor: AppTheme.cardinal,
                  inactiveColor: AppTheme.cardinal.withValues(alpha: 0.2),
                  onChanged: (v) => setLocalState(() => _radiusKm = v),
                  onChangeEnd: (_) {
                    context.pop();
                    _discover();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Text(
                'Select Format',
                style: AppTheme.dmSans.copyWith(
                    color: AppTheme.parchment, fontWeight: FontWeight.w700),
              ),
            ),
            ..._formats.map((f) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.screenPadding),
                  title: Text(f,
                      style: AppTheme.dmSans.copyWith(color: AppTheme.parchment)),
                  trailing: _selectedFormat == f
                      ? Icon(Icons.check, color: AppTheme.cardinal)
                      : null,
                  onTap: () {
                    setState(() =>
                        _selectedFormat = _selectedFormat == f ? null : f);
                    context.pop();
                    _discover();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showPositionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Select Position',
                style: AppTheme.dmSans.copyWith(
                    color: AppTheme.parchment, fontWeight: FontWeight.w700),
              ),
            ),
            ...PlayingPosition.values.map((p) => ListTile(
                  title: Text(p.value,
                      style:
                          AppTheme.dmSans.copyWith(color: AppTheme.parchment)),
                  trailing: _selectedPosition == p
                      ? Icon(Icons.check, color: AppTheme.cardinal)
                      : null,
                  onTap: () {
                    setState(() =>
                        _selectedPosition = _selectedPosition == p ? null : p);
                    context.pop();
                    _discover();
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── PRIVATE WIDGETS ────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.cardinal.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.cardinal : AppTheme.cardBorderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.cardinal : AppTheme.parchment,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final NearbyMatch match;
  final VoidCallback onTap;

  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: AppTheme.cardGap),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardinal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.format,
                    style: AppTheme.dmSans.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cardinal),
                  ),
                ),
                const Spacer(),
                Text(
                  '${match.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                  style: AppTheme.dmSans.copyWith(
                      fontSize: 11, color: AppTheme.gold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              match.venueName ?? 'Unknown venue',
              style: AppTheme.dmSans.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.parchment),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(match.startTime),
              style: AppTheme.dmSans.copyWith(fontSize: 12, color: AppTheme.gold),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: AppTheme.gold),
                const SizedBox(width: 4),
                Text(
                  '${match.slotsRemaining}/${match.slotsNeeded} spots',
                  style: AppTheme.dmSans.copyWith(
                      fontSize: 11, color: AppTheme.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${_dayName(dt.weekday)} ${dt.day}';
  }

  String _dayName(int w) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[w - 1];
  }
}

class _MatchListTile extends StatelessWidget {
  final NearbyMatch match;
  final VoidCallback onTap;

  const _MatchListTile({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.cardGap),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardinal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.sports_soccer, color: AppTheme.cardinal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.venueName ?? 'Unknown venue',
                    style: AppTheme.dmSans.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.parchment),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.format} · ${_formatTime(match.startTime)}',
                    style: AppTheme.dmSans.copyWith(
                        fontSize: 12, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.slotsRemaining} spots left · ${match.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                    style: AppTheme.dmSans.copyWith(
                        fontSize: 12, color: AppTheme.mutedParchment),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.gold),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
