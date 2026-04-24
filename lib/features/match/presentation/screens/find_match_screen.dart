import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../../../../models/team_model.dart';
import '../../../../../../../providers/find_match_provider.dart';
import '../../../../../../../providers/team_provider.dart';

/// Find a Match screen — discover nearby teams, filter by format,
/// and challenge opponents.
class FindMatchScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const FindMatchScreen({super.key, this.onBack});

  @override
  ConsumerState<FindMatchScreen> createState() => _FindMatchScreenState();
}

class _FindMatchScreenState extends ConsumerState<FindMatchScreen> {
  String _selectedFormat = 'all';
  String _selectedSkill = 'all';
  String _selectedDay = 'all';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeams());
  }

  Future<void> _loadTeams() async {
    // Load available teams
    ref.read(findMatchProvider.notifier).searchTeams(
      TeamSearchFilters(
        format: _selectedFormat == 'all' ? null : _selectedFormat,
        skillLevel: _selectedSkill == 'all' ? null : _selectedSkill,
      ),
    );
  }

  Future<void> _requestLocationAndSearch() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location access is needed to find teams near you.'),
              backgroundColor: AppTheme.navy,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable in settings.'),
            backgroundColor: AppTheme.navy,
          ),
        );
      }
      return;
    }

    // Location permission granted - proceed with location-based search
    await _loadTeams();
  }

  @override
  Widget build(BuildContext context) {
    final findMatchState = ref.watch(findMatchProvider);
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocation(),
                    const SizedBox(height: 20),
                    _buildFilters(),
                    if (_showFilters) ...[
                      const SizedBox(height: 16),
                      _buildExpandedFilters(),
                    ],
                    const SizedBox(height: 24),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    findMatchState.isLoading
                        ? _buildLoadingState()
                        : _buildContent(findMatchState, teamState),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // TOP BAR
  // =============================================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.voidBg,
      child: Row(
        children: [
          Text(
            'Find a Match',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.parchment,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Icon(Icons.tune, color: AppTheme.gold, size: 24),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // LOCATION
  // =============================================================================

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on, color: AppTheme.gold, size: 18),
        const SizedBox(width: 6),
        Text(
          'Hackney, London',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedParchment,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showLocationPicker,
          child: Text(
            'Change',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.parchment,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // FILTERS
  // =============================================================================

  Widget _buildFilters() {
    final formats = ['All', '5v5', '7v7', '11v11'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: formats.map((format) {
          final isSelected = _selectedFormat == format.toLowerCase() ||
              (format == 'All' && _selectedFormat == 'all');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFormat = format == 'All' ? 'all' : format.toLowerCase();
                });
                _loadTeams();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.navy : AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.navy : AppTheme.elevatedSurface,
                  ),
                ),
                child: Text(
                  format,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.voidBg : AppTheme.gold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.elevatedSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow('Skill Level', ['Any', 'Casual', 'Competitive'], _selectedSkill, (value) {
            setState(() => _selectedSkill = value.toLowerCase());
            _loadTeams();
          }),
          const SizedBox(height: 12),
          _buildFilterRow('Day', ['Any', 'Today', 'This Weekend', 'Weekday'], _selectedDay, (value) {
            setState(() => _selectedDay = value.toLowerCase().replaceAll(' ', '_'));
            _loadTeams();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String label, List<String> options, String selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.gold,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selected == option.toLowerCase() ||
                (option == 'Any' && selected == 'all');
            return GestureDetector(
              onTap: () => onSelect(option == 'Any' ? 'all' : option.toLowerCase()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.navy.withValues(alpha: 0.2) : AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.navy : Colors.transparent,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.parchment : AppTheme.gold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =============================================================================
  // TABS
  // =============================================================================

  Widget _buildTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.parchment,
            unselectedLabelColor: AppTheme.gold,
            indicatorColor: AppTheme.navy,
            labelStyle: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'Available Teams'),
              Tab(text: 'My Challenges'),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // CONTENT
  // =============================================================================

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.navy),
      ),
    );
  }

  Widget _buildContent(FindMatchState state, TeamState teamState) {
    return Column(
      children: [
        if (state.error != null)
          _buildErrorState(state.error!)
        else if (state.availableTeams.isEmpty)
          _buildEmptyState()
        else
          ...state.availableTeams.map((team) => _buildTeamCard(team)),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardinal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.elevatedSurface),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppTheme.cardinal, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading teams',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: AppTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.elevatedSurface),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: AppTheme.gold, size: 48),
          const SizedBox(height: 16),
          Text(
            'No teams found',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: AppTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.elevatedSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.parchment,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            team.format.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.parchment,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (team.location != null)
                          Text(
                            team.location!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.gold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance placeholder
              Row(
                children: [
                  const Icon(Icons.near_me, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '0.0 mi',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _showChallengeDialog(team),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: AppTheme.voidBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('CHALLENGE'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _viewTeamProfile(team),
                child: Text(
                  'View profile',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parchment,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // ACTIONS
  // =============================================================================

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Location',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppTheme.navy),
              title: Text('Use current location', style: TextStyle(color: AppTheme.parchment)),
              onTap: () {
                Navigator.pop(context);
                _requestLocationAndSearch();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.search, color: AppTheme.navy),
              title: Text('Enter city or postcode', style: TextStyle(color: AppTheme.parchment)),
              onTap: () {
                Navigator.pop(context);
                _showCitySearchDialog();
              },
            ),
            // Add more locations
          ],
        ),
      ),
    );
  }

  void _showCitySearchDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Enter City or Postcode',
          style: TextStyle(color: AppTheme.parchment),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.parchment),
          decoration: InputDecoration(
            hintText: 'e.g. London, E1 6AN',
            hintStyle: TextStyle(color: AppTheme.gold),
            filled: true,
            fillColor: AppTheme.elevatedSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Use the city/postcode for search
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Searching near ${controller.text}...'),
                  backgroundColor: AppTheme.navy,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: AppTheme.voidBg,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showChallengeDialog(TeamModel team) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00';
    String selectedFormat = team.format;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge ${team.name}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.parchment,
                ),
              ),
              const SizedBox(height: 24),
              // Format
              Text(
                'Format',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['5v5', '7v7', '11v11'].map((format) {
                  final isSelected = selectedFormat == format;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFormat = format),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.navy : AppTheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        format,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTheme.voidBg : AppTheme.gold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, (date) {
                            setState(() => selectedDate = date);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(color: AppTheme.parchment),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(selectedTime, style: TextStyle(color: AppTheme.parchment)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Send button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    // FIX: find_match_screen — use_build_context_synchronously: capture context state BEFORE async call
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final success = await ref.read(findMatchProvider.notifier).sendChallenge(
                      fromTeamId: ref.read(teamProvider).currentTeam?.teamId ?? '',
                      toTeamId: team.teamId,
                      proposedDate: selectedDate,
                      format: selectedFormat,
                    );

                    if (!mounted) return;
                    await navigator.maybePop();
                    if (success) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Challenge sent to ${team.name}!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    foregroundColor: AppTheme.voidBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SEND CHALLENGE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewTeamProfile(TeamModel team) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: AppTheme.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.parchment,
                        ),
                      ),
                      Text(
                        '${team.format.toUpperCase()} · ${team.location ?? "Unknown location"}',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: AppTheme.parchment,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onSelected) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navy,
              surface: AppTheme.voidBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }
}