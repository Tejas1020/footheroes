import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/models/match_model.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_provider.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/widgets/location_picker_sheet.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';
import '../../providers/nearby_matches_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/user_location_provider.dart';
import '../widgets/match_detail_sheet.dart';
import '../widgets/request_to_join_dialog.dart';

/// Find a Match screen with two tabs:
/// 1. Available Matches — discover nearby open matches.
/// 2. Join a Match — enter a match code to join directly.
class FindNearbyMatchScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const FindNearbyMatchScreen({super.key, this.onBack});

  @override
  ConsumerState<FindNearbyMatchScreen> createState() =>
      _FindNearbyMatchScreenState();
}

class _FindNearbyMatchScreenState extends ConsumerState<FindNearbyMatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters for Available Matches
  double _radiusKm = 10.0;
  String? _selectedFormat;
  PlayingPosition? _selectedPosition;

  // Join by code state
  final _codeController = TextEditingController();
  MatchModel? _foundMatch;
  bool _searchingMatch = false;
  String? _searchError;

  // Location init tracking
  bool _authReady = false;
  bool _locationLoading = true;

  final List<String> _formats = const [
    '5-a-side',
    '7-a-side',
    '11-a-side',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScreen());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated && auth.userId != null) {
      setState(() => _authReady = true);
      await _loadLocation(auth.userId!);
    } else if (auth.status == AuthStatus.loading) {
      // Auth still loading — listen for change
      ref.listenManual(authProvider, (prev, next) {
        if (next.status == AuthStatus.authenticated &&
            next.userId != null &&
            !_authReady) {
          setState(() => _authReady = true);
          _loadLocation(next.userId!);
        }
      });
    } else {
      setState(() => _locationLoading = false);
    }
  }

  Future<void> _loadLocation(String userId) async {
    setState(() => _locationLoading = true);
    await ref.read(userLocationProvider.notifier).loadLocation(userId);
    if (!mounted) return;
    setState(() => _locationLoading = false);

    final locState = ref.read(userLocationProvider);
    if (locState.location != null) {
      _discover();
    }
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

  // ── JOIN BY CODE ─────────────────────────────────────────────

  Future<void> _searchMatchByCode() async {
    setState(() {
      _searchingMatch = true;
      _searchError = null;
      _foundMatch = null;
    });
    try {
      final repo = ref.read(matchRepositoryProvider);
      final match = await repo.getById(_codeController.text.trim());
      if (match == null) {
        setState(() => _searchError = 'Match not found. Check the code and try again.');
      } else {
        setState(() => _foundMatch = match);
      }
    } catch (e) {
      setState(() => _searchError = 'Error searching match: $e');
    } finally {
      setState(() => _searchingMatch = false);
    }
  }

  Future<void> _sendJoinRequest(MatchModel match) async {
    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to request joining'),
          backgroundColor: AppTheme.cardinal,
        ),
      );
      return;
    }

    String selectedPosition = 'CM';
    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.abyss,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  AppTheme.accentBar(),
                  const SizedBox(width: 8),
                  Text('REQUEST TO JOIN', style: AppTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                match.homeTeamName,
                style: AppTheme.bebasDisplay.copyWith(fontSize: 20, color: AppTheme.parchment),
              ),
              const SizedBox(height: 20),
              Text('PREFERRED POSITION', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['GK', 'LB', 'CB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'].map((pos) {
                  final isSelected = selectedPosition == pos;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedPosition = pos),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.cardinal : AppTheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : AppTheme.cardBorder,
                      ),
                      child: Text(
                        pos,
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 14,
                          color: isSelected ? AppTheme.parchment : AppTheme.gold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: AppTheme.primaryButton,
                  child: const Text('SEND REQUEST'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldSend != true) return;

    try {
      final repo = ref.read(joinRequestRepositoryProvider);
      await repo.create(
        matchId: match.matchId,
        requesterUid: userId,
        requesterPosition: selectedPosition,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent!'),
            backgroundColor: AppTheme.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppTheme.cardinal,
          ),
        );
      }
    }
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildLocationBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableMatchesTab(),
                  _buildJoinByCodeTab(),
                ],
              ),
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
                  'Find a Match',
                  style: AppTheme.bodyBold.copyWith(
                    fontSize: 20,
                    color: AppTheme.parchment,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBar() {
    final locState = ref.watch(userLocationProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: GestureDetector(
        onTap: _onEditLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.heroCtaGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardinal.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locState.locationName ?? 'Set Location',
                      style: AppTheme.dmSans.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      locState.location != null
                          ? 'Tap to update your location'
                          : 'Tap to pick your location on map',
                      style: AppTheme.dmSans.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: AppTheme.cardBorder,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.cardinal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardinal, width: 1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.cardinal,
        unselectedLabelColor: AppTheme.mutedParchment,
        labelStyle: AppTheme.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTheme.dmSans.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Available Matches'),
          Tab(text: 'Join a Match'),
        ],
      ),
    );
  }

  // ── TAB 1: AVAILABLE MATCHES ─────────────────────────────────

  Widget _buildAvailableMatchesTab() {
    final locState = ref.watch(userLocationProvider);
    final matchesAsync = ref.watch(nearbyMatchesNotifierProvider);

    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.cardinal),
            SizedBox(height: 14),
            Text(
              'Loading your location...',
              style: TextStyle(color: AppTheme.gold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (locState.location == null) {
      return _buildLocationSetup(locState);
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return _buildEmptyState('No open matches nearby within ${_radiusKm.toStringAsFixed(0)} km.');
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
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSetup(UserLocationState locState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              'We need your location to find nearby matches.\nTap the button above to get started.',
              textAlign: TextAlign.center,
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                color: AppTheme.mutedParchment,
                height: 1.5,
              ),
            ),
            if (locState.isSaving) ...[
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.cardinal,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Saving location...',
                    style: TextStyle(color: AppTheme.gold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
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

  // ── TAB 2: JOIN BY CODE ──────────────────────────────────────

  Widget _buildJoinByCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a match code?',
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 24,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the code shared by the match creator to send a join request.',
            style: AppTheme.dmSans.copyWith(
              fontSize: 13,
              color: AppTheme.mutedParchment,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.cardBorder,
            ),
            child: TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: AppTheme.dmSans.copyWith(
                color: AppTheme.parchment,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'PASTE MATCH CODE',
                hintStyle: AppTheme.dmSans.copyWith(
                  color: AppTheme.mutedParchment,
                  fontSize: 15,
                  letterSpacing: 2,
                ),
                prefixIcon: const Icon(Icons.vpn_key_rounded,
                    color: AppTheme.gold, size: 22),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _codeController.clear();
                          setState(() {
                            _foundMatch = null;
                            _searchError = null;
                          });
                        },
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.gold, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _codeController.text.trim().isNotEmpty && !_searchingMatch
                  ? _searchMatchByCode
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardinal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppTheme.elevatedSurface,
                disabledForegroundColor: AppTheme.mutedParchment,
                elevation: 0,
              ),
              child: _searchingMatch
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'SEARCH MATCH',
                      style: AppTheme.dmSans.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 20),
            _buildErrorState(_searchError!),
          ],
          if (_foundMatch != null) ...[
            const SizedBox(height: 24),
            _buildFoundMatchCard(_foundMatch!),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.feedbackError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.feedbackError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.feedbackError, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.dmSans.copyWith(
                color: AppTheme.feedbackError,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundMatchCard(MatchModel match) {
    final auth = ref.watch(authProvider);
    final userId = auth.userId;
    final isCreator = match.createdBy == userId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: AppTheme.cardBorder,
        boxShadow: [
          BoxShadow(
            color: const Color(0x1000458E),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroCtaGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_soccer, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.homeTeamName,
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.parchment,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.venue ?? 'Venue TBD',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 12,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(Icons.calendar_today,
                  '${match.matchDate.day}/${match.matchDate.month}/${match.matchDate.year}'),
              const SizedBox(width: 12),
              _chip(Icons.schedule,
                  '${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardinal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 16),
          if (isCreator)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You created this match. View it in Upcoming Matches.',
                textAlign: TextAlign.center,
                style: AppTheme.dmSans.copyWith(
                  fontSize: 12,
                  color: AppTheme.navy,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _sendJoinRequest(match),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardinal,
                  foregroundColor: AppTheme.parchment,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'REQUEST TO JOIN',
                  style: AppTheme.dmSans.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.gold),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.dmSans.copyWith(fontSize: 11, color: AppTheme.gold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
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
