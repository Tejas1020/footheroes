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
import '../widgets/match_detail_sheet.dart';
import '../widgets/request_to_join_dialog.dart';

/// Discover open matches near your location.
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
  LatLng? _currentLocation;

  final List<String> _formats = const [
    '5-a-side',
    '7-a-side',
    '11-a-side',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission || !mounted) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _discover();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  Future<bool> _checkPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _discover() {
    if (_currentLocation == null) return;
    final auth = ref.read(authProvider);
    ref.read(nearbyMatchesNotifierProvider.notifier).discover(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          radiusKm: _radiusKm,
          playerPosition: _selectedPosition?.value,
          playerUid: auth.userId,
        );
  }

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

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(nearbyMatchesNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildFilters(),
            Expanded(
              child: _mapExpanded
                  ? _buildMapWithOverlay(matchesAsync)
                  : _buildList(matchesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.screenPadding,
        vertical: 16,
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
              style: AppTheme.dmSans.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.screenPadding,
        vertical: 12,
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

  Widget _buildMapWithOverlay(AsyncValue<List<NearbyMatch>> matchesAsync) {
    return Stack(
      children: [
        if (_currentLocation != null)
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.footheroes.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.parchment,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ..._buildMatchMarkers(matchesAsync),
                ],
              ),
            ],
          )
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: AppTheme.screenPadding,
          left: AppTheme.screenPadding,
          right: AppTheme.screenPadding,
          child: _buildMatchListOverlay(matchesAsync),
        ),
      ],
    );
  }

  List<Marker> _buildMatchMarkers(AsyncValue<List<NearbyMatch>> matchesAsync) {
    return matchesAsync.when(
      data: (matches) => matches.where((m) {
        return m.latitude != null && m.longitude != null;
      }).map((m) {
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
                border: Border.all(
                  color: AppTheme.parchment,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 20,
                color: Colors.white,
              ),
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
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: AppTheme.mutedParchment,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTheme.dmSans.copyWith(
              color: AppTheme.mutedParchment,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      ),
    );
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
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
                  color: AppTheme.parchment,
                ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
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
                  color: AppTheme.parchment,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ..._formats.map((f) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.screenPadding,
                  ),
                  title: Text(
                    f,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.parchment,
                    ),
                  ),
                  trailing: _selectedFormat == f
                      ? Icon(Icons.check,
                          color: AppTheme.cardinal)
                      : null,
                  onTap: () {
                    setState(() => _selectedFormat =
                        _selectedFormat == f ? null : f);
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
                  color: AppTheme.parchment,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...PlayingPosition.values.map((p) => ListTile(
                  title: Text(
                    p.value,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.parchment,
                    ),
                  ),
                  trailing: _selectedPosition == p
                      ? Icon(Icons.check,
                          color: AppTheme.cardinal)
                      : null,
                  onTap: () {
                    setState(() => _selectedPosition =
                        _selectedPosition == p ? null : p);
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
            color: isActive
                ? AppTheme.cardinal
                : AppTheme.cardBorderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppTheme.cardinal
                : AppTheme.parchment,
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
          border: Border.all(
            color: AppTheme.cardBorderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardinal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.format,
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cardinal,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${match.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 11,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              match.venueName ?? 'Unknown venue',
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(match.startTime),
              style: AppTheme.dmSans.copyWith(
                fontSize: 12,
                color: AppTheme.gold,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: AppTheme.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  '${match.slotsRemaining}/${match.slotsNeeded} spots',
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 11,
                    color: AppTheme.gold,
                  ),
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
          border: Border.all(
            color: AppTheme.cardBorderColor,
            width: 1,
          ),
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
              child: const Icon(
                Icons.sports_soccer,
                color: AppTheme.cardinal,
              ),
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
                      color: AppTheme.parchment,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.format} · ${_formatTime(match.startTime)}',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 12,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.slotsRemaining} spots left · ${match.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                    style: AppTheme.dmSans.copyWith(
                      fontSize: 12,
                      color: AppTheme.mutedParchment,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.gold,
            ),
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
