import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';
import '../../providers/nearby_matches_provider.dart';
import '../../providers/user_location_provider.dart';
import '../widgets/match_detail_sheet.dart';
import '../widgets/request_to_join_dialog.dart';
import '../../../../widgets/location_picker_sheet.dart';

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

  final _mapController = MapController();

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
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId == null) return;

    await ref.read(userLocationProvider.notifier).loadLocation(userId);

    final locState = ref.read(userLocationProvider);
    if (locState.location != null) {
      _discover();
    }

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
        final auth = ref.read(authProvider);
        final loc = LatLng(position.latitude, position.longitude);
        await ref
            .read(userLocationProvider.notifier)
            .saveGpsLocation(loc, auth.userId ?? '');
        _discover();
      }
    } catch (_) {}
  }

  Future<void> _onEditLocation() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
    if (!mounted) return;
    _discover();
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
        child: locState.needsSetup
            ? _buildLocationSetup(locState)
            : Column(
                children: [
                  _buildAppBar(),
                  _buildLocationBar(locState),
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

  Widget _buildLocationSetup(UserLocationState locState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.heroCtaGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardinal.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Set Your Location',
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 32,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need your location to find\nnearby matches and players.',
            textAlign: TextAlign.center,
            style: AppTheme.dmSans.copyWith(
              fontSize: 14,
              color: AppTheme.mutedParchment,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _SetupOptionCard(
            icon: Icons.map_rounded,
            title: 'Pick on Map',
            subtitle: 'Search or tap to select your location',
            color: AppTheme.cardinal,
            onTap: _onEditLocation,
          ),
          const SizedBox(height: 14),
          _SetupOptionCard(
            icon: Icons.my_location_rounded,
            title: 'Use Current Location',
            subtitle: 'Detect your location via GPS',
            color: AppTheme.sparkBlue,
            onTap: _useGpsLocation,
          ),
          if (locState.isSaving)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.cardinal,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saving location...',
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.gold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLocationBar(UserLocationState locState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: _onEditLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: AppTheme.cardBorder,
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppTheme.cardinal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locState.locationName ?? 'Your location',
                      style: AppTheme.dmSans.copyWith(
                        color: AppTheme.parchment,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to change',
                      style: AppTheme.dmSans.copyWith(
                        color: AppTheme.gold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (locState.isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.cardinal,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.edit_rounded, color: AppTheme.gold, size: 16),
            ],
          ),
        ),
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

class _SetupOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SetupOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.parchment,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.mutedParchment,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
