import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'package:footheroes/providers/auth_provider.dart';
import 'package:footheroes/providers/match_provider.dart';
import 'package:footheroes/providers/match_roster_provider.dart';
import 'package:footheroes/models/match_model.dart';
import 'package:footheroes/core/router/app_router.dart';
import 'package:footheroes/features/match/data/models/live_match_models.dart';
import 'package:footheroes/features/find_nearby/domain/entities/venue.dart';
import 'package:footheroes/features/find_nearby/presentation/screens/venue_picker_screen.dart';
import 'package:footheroes/widgets/add_player_sheet.dart';

/// Redesigned Match creation screen using Dark Colour System.
class MatchCreationScreen extends ConsumerStatefulWidget {
  const MatchCreationScreen({super.key});

  @override
  ConsumerState<MatchCreationScreen> createState() => _MatchCreationScreenState();
}

class _MatchCreationScreenState extends ConsumerState<MatchCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();

  String _selectedFormat = '5v5';
  bool _isCreating = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  Venue? _selectedVenue;
  final List<LivePlayerInfo> _roster = [];

  static const _formats = ['5v5', '7v7', '9v9', '11v11'];

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    super.dispose();
  }

  void _addPlayerToRoster(String team) async {
    final player = await showAddPlayerSheet(
      context,
      ref.read(appwriteServiceProvider),
      team: team,
    );
    if (player != null && mounted) {
      setState(() {
        _roster.add(player);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.themeData,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.themeData,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _startMatch() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a match'),
            backgroundColor: AppTheme.cardinal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isCreating = true);

    try {
      final matchId = ID.unique();

      final isScheduled = _scheduledDate != null;
      DateTime matchDate;
      if (isScheduled && _scheduledTime != null) {
        matchDate = DateTime(
          _scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
          _scheduledTime!.hour, _scheduledTime!.minute,
        );
      } else if (isScheduled) {
        matchDate = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day);
      } else {
        matchDate = DateTime.now();
      }

      final match = MatchModel(
        id: matchId,
        matchId: matchId,
        homeTeamId: userId,
        awayTeamId: null,
        homeTeamName: _homeTeamController.text.trim(),
        awayTeamName: _awayTeamController.text.trim(),
        format: _selectedFormat,
        status: isScheduled ? 'upcoming' : 'live',
        homeScore: 0,
        awayScore: 0,
        events: const [],
        matchDate: matchDate,
        createdBy: userId,
        venue: _selectedVenue?.name,
        venueLatitude: _selectedVenue?.latitude,
        venueLongitude: _selectedVenue?.longitude,
      );

      final repository = ref.read(matchRepositoryProvider);
      final created = await repository.createMatch(match, scorerId: userId);

      if (_roster.isNotEmpty) {
        await ref.read(matchRosterProvider.notifier).saveRosterForMatch(
          created.matchId,
          _roster,
        );
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        if (isScheduled) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${match.homeTeamName} vs ${match.awayTeamName ?? 'Opposition'} scheduled!'),
              backgroundColor: AppTheme.navy,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(AppRoutes.home);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${match.homeTeamName} vs ${match.awayTeamName ?? 'Opposition'} started!'),
              backgroundColor: AppTheme.navy,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.push(AppRoutes.liveMatch, extra: created);
        }
      }
    } catch (e) {
      debugPrint('Match creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.cardinal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      appBar: AppBar(
        backgroundColor: AppTheme.abyss,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.parchment, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'CREATE MATCH',
          style: AppTheme.bebasDisplay.copyWith(fontSize: 18, letterSpacing: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('MATCH FORMAT'),
                const SizedBox(height: 16),
                _buildFormatSelector(),
                const SizedBox(height: 32),
                _buildSectionHeader('TEAMS'),
                const SizedBox(height: 16),
                _buildTeamsCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('VENUE'),
                const SizedBox(height: 16),
                _buildVenueInput(),
                const SizedBox(height: 32),
                _buildSectionHeader('ROSTER'),
                const SizedBox(height: 16),
                _buildTeamRoster('home'),
                const SizedBox(height: 12),
                _buildTeamRoster('away'),
                const SizedBox(height: 32),
                _buildSectionHeader('SCHEDULE'),
                const SizedBox(height: 16),
                _buildScheduleInput(),
                const SizedBox(height: 48),
                _buildStartButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Row(
    children: [
      AppTheme.accentBar(),
      const SizedBox(width: 8),
      Text(title, style: AppTheme.labelSmall),
    ],
  );

  Widget _buildFormatSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _formats.map((f) {
        final isSelected = _selectedFormat == f;
        return GestureDetector(
          onTap: () => setState(() => _selectedFormat = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.cardinal : AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? null : AppTheme.cardBorder,
            ),
            child: Text(
              f,
              style: AppTheme.bebasDisplay.copyWith(
                fontSize: 16,
                color: isSelected ? AppTheme.parchment : AppTheme.gold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamsCard() {
    return Container(
      decoration: AppTheme.standardCard,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTeamField(_homeTeamController, 'HOME TEAM', 'e.g. FC United', AppTheme.cardinal),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppTheme.cardBorderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: AppTheme.bebasDisplay.copyWith(color: AppTheme.gold, fontSize: 14)),
              ),
              Expanded(child: Container(height: 1, color: AppTheme.cardBorderColor)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTeamField(_awayTeamController, 'AWAY TEAM', 'e.g. Athletic FC', AppTheme.navy),
        ],
      ),
    );
  }

  Widget _buildTeamField(TextEditingController controller, String label, String hint, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 8, color: color)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTheme.bodyBold,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.dmSans.copyWith(color: AppTheme.gold.withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppTheme.elevatedSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueInput() => GestureDetector(
    onTap: _pickVenueOnMap,
    child: Container(
      decoration: AppTheme.standardCard,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _selectedVenue != null
                  ? AppTheme.cardinal
                  : AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedVenue != null
                  ? Icons.location_on_rounded
                  : Icons.map_outlined,
              color: AppTheme.parchment, size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedVenue?.name ?? 'SELECT VENUE',
                  style: AppTheme.bodyBold.copyWith(
                    color: _selectedVenue != null
                        ? AppTheme.parchment
                        : AppTheme.gold,
                  ),
                ),
                if (_selectedVenue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _selectedVenue!.address ??
                      '${_selectedVenue!.latitude.toStringAsFixed(4)}, '
                      '${_selectedVenue!.longitude.toStringAsFixed(4)}',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 11, color: AppTheme.gold,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tap to pick on map',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 11, color: AppTheme.mutedParchment,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.gold, size: 20),
        ],
      ),
    ),
  );

  Future<void> _pickVenueOnMap() async {
    final venue = await Navigator.of(context).push<Venue>(
      MaterialPageRoute(
        builder: (_) => const VenuePickerScreen(),
      ),
    );
    if (venue != null && mounted) {
      setState(() => _selectedVenue = venue);
    }
  }

  Widget _buildTeamRoster(String team) {
    final label = team == 'home' ? (_homeTeamController.text.isEmpty ? 'HOME' : _homeTeamController.text) : (_awayTeamController.text.isEmpty ? 'AWAY' : _awayTeamController.text);
    final color = team == 'home' ? AppTheme.cardinal : AppTheme.navy;
    final players = _roster.where((p) => p.team == team).toList();

    return Container(
      decoration: AppTheme.standardCard.copyWith(border: Border.all(color: color.withValues(alpha: 0.15))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: AppTheme.bebasDisplay.copyWith(fontSize: 14, color: color)),
              GestureDetector(
                onTap: () => _addPlayerToRoster(team),
                child: Text('+ ADD PLAYER', style: AppTheme.bodyBold.copyWith(fontSize: 11, color: color)),
              ),
            ],
          ),
          if (players.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...players.map((p) => _playerChip(p)),
          ],
        ],
      ),
    );
  }

  Widget _playerChip(LivePlayerInfo p) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppTheme.elevatedSurface, borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: [
        Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppTheme.abyss, shape: BoxShape.circle), alignment: Alignment.center, child: Text(p.name[0], style: AppTheme.bebasDisplay.copyWith(fontSize: 12))),
        const SizedBox(width: 12),
        Expanded(child: Text(p.name, style: AppTheme.bodyBold)),
        GestureDetector(onTap: () => setState(() => _roster.remove(p)), child: const Icon(Icons.close_rounded, color: AppTheme.gold, size: 16)),
      ],
    ),
  );

  Widget _buildScheduleInput() {
    return Row(
      children: [
        Expanded(child: _scheduleTile(Icons.calendar_today_rounded, _scheduledDate == null ? 'DATE' : '${_scheduledDate!.day}/${_scheduledDate!.month}', _pickDate)),
        const SizedBox(width: 12),
        Expanded(child: _scheduleTile(Icons.access_time_rounded, _scheduledTime == null ? 'TIME' : _scheduledTime!.format(context), _pickTime)),
      ],
    );
  }

  Widget _scheduleTile(IconData i, String l, VoidCallback t) => GestureDetector(
    onTap: t,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.standardCard,
      child: Row(children: [
        Icon(i, color: AppTheme.cardinal, size: 18),
        const SizedBox(width: 12),
        Text(l, style: AppTheme.bodyBold),
      ]),
    ),
  );

  Widget _buildStartButton() => SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      onPressed: _isCreating ? null : _startMatch,
      style: AppTheme.primaryButton,
      child: Text(_scheduledDate != null ? 'SCHEDULE FIXTURE' : 'KICK OFF NOW'),
    ),
  );
}
