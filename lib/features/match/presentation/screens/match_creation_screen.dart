import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/match_provider.dart';
import '../../../../providers/match_roster_provider.dart';
import '../../../../models/match_model.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/match/data/models/live_match_models.dart';
import '../../../../widgets/add_player_sheet.dart';

/// Match creation screen — selects format, enters team names, adds roster, starts a match.
class MatchCreationScreen extends ConsumerStatefulWidget {
  const MatchCreationScreen({super.key});

  @override
  ConsumerState<MatchCreationScreen> createState() => _MatchCreationScreenState();
}

class _MatchCreationScreenState extends ConsumerState<MatchCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();
  final _venueController = TextEditingController();

  String _selectedFormat = '5v5';
  bool _isCreating = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final List<LivePlayerInfo> _roster = [];

  static const _formats = ['5v5', '7v7', '9v9', '11v11'];

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _addPlayerToRoster(String team) async {
    final player = await showAddPlayerSheet(
      context,
      ref.read(appwriteServiceProvider),
    );
    if (player != null && mounted) {
      setState(() {
        _roster.add(player.copyWith(team: team));
      });
    }
  }

  void _removePlayerFromRoster(int index) {
    setState(() {
      _roster.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MidnightPitchTheme.electricMint,
              surface: MidnightPitchTheme.surfaceDim,
            ),
          ),
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
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MidnightPitchTheme.electricMint,
              surface: MidnightPitchTheme.surfaceDim,
            ),
          ),
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
            backgroundColor: MidnightPitchTheme.liveRed,
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
        venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
      );

      final repository = ref.read(matchRepositoryProvider);
      final created = await repository.createMatch(match, scorerId: userId);

      // Save roster to Appwrite so it persists across sessions
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
              backgroundColor: MidnightPitchTheme.electricMint,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(AppRoutes.home);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${match.homeTeamName} vs ${match.awayTeamName ?? 'Opposition'} started!'),
              backgroundColor: MidnightPitchTheme.electricMint,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(AppRoutes.liveMatch, extra: created);
        }
      }
    } catch (e) {
      debugPrint('Match creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: MidnightPitchTheme.liveRed,
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
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MidnightPitchTheme.primaryText),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          'Create Match',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
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
                // ── Format Section ──────────────────────────────────
                Text(
                  'FORMAT',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _formats.map((format) {
                          final isSelected = _selectedFormat == format;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFormat = format),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MidnightPitchTheme.electricMint
                                    : MidnightPitchTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                format,
                                style: TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? MidnightPitchTheme.surfaceDim
                                      : MidnightPitchTheme.primaryText,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Team Names Section ────────────────────────────────
                Text(
                  'TEAMS',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTeamField(
                        controller: _homeTeamController,
                        label: 'Home team',
                        hint: 'e.g. FC United',
                        icon: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: MidnightPitchTheme.surfaceContainerHigh,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: MidnightPitchTheme.electricMint,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: MidnightPitchTheme.surfaceContainerHigh,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTeamField(
                        controller: _awayTeamController,
                        label: 'Away team',
                        hint: 'e.g. Athletic FC',
                        icon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Venue Section ────────────────────────────────────
                Text(
                  'VENUE',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _venueController,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 14,
                        color: MidnightPitchTheme.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Hackney Marshes, Regent\'s Park',
                        hintStyle: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 14,
                          color: MidnightPitchTheme.mutedText,
                        ),
                        prefixIcon: Icon(Icons.location_on_outlined, color: MidnightPitchTheme.mutedText, size: 20),
                        filled: true,
                        fillColor: MidnightPitchTheme.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: MidnightPitchTheme.electricMint),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Roster Section — split Home/Away ────────────────
                Text(
                  'ROSTER',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTeamRoster(
                  label: _homeTeamController.text.trim().isNotEmpty
                      ? _homeTeamController.text.trim()
                      : 'Home',
                  team: 'home',
                  accentColor: MidnightPitchTheme.electricMint,
                ),
                const SizedBox(height: 16),
                _buildTeamRoster(
                  label: _awayTeamController.text.trim().isNotEmpty
                      ? _awayTeamController.text.trim()
                      : 'Away',
                  team: 'away',
                  accentColor: MidnightPitchTheme.mutedText,
                ),

                const SizedBox(height: 24),

                // ── Schedule Section ─────────────────────────────────
                Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MidnightPitchTheme.mutedText,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: MidnightPitchTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: MidnightPitchTheme.electricMint),
                                    const SizedBox(width: 10),
                                    Text(
                                      _scheduledDate != null
                                          ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                          : 'Date',
                                      style: TextStyle(
                                        fontFamily: MidnightPitchTheme.fontFamily,
                                        fontSize: 14,
                                        color: _scheduledDate != null
                                            ? MidnightPitchTheme.primaryText
                                            : MidnightPitchTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: MidnightPitchTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 18, color: MidnightPitchTheme.electricMint),
                                    const SizedBox(width: 10),
                                    Text(
                                      _scheduledTime != null
                                          ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Time',
                                      style: TextStyle(
                                        fontFamily: MidnightPitchTheme.fontFamily,
                                        fontSize: 14,
                                        color: _scheduledTime != null
                                            ? MidnightPitchTheme.primaryText
                                            : MidnightPitchTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_scheduledDate != null || _scheduledTime != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _scheduledDate = null;
                                _scheduledTime = null;
                              }),
                              child: Icon(Icons.close, size: 18, color: MidnightPitchTheme.mutedText),
                            ),
                          ],
                        ],
                      ),
                      if (_scheduledDate != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: MidnightPitchTheme.mutedText),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Match will appear in Upcoming',
                                style: TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 11,
                                  color: MidnightPitchTheme.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Start Match Button ──────────────────────────────
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: MidnightPitchTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: MidnightPitchTheme.electricMint.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _startMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: MidnightPitchTheme.surfaceDim,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MidnightPitchTheme.surfaceDim,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _scheduledDate != null ? 'SCHEDULE MATCH' : 'START MATCH',
                                style: TextStyle(
                                  fontFamily: MidnightPitchTheme.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRoster({
    required String label,
    required String team,
    required Color accentColor,
  }) {
    final teamPlayers = _roster.asMap().entries.where((e) => e.value.team == team).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.shield_outlined, size: 14, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${teamPlayers.length}',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _addPlayerToRoster(team),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'ADD',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (teamPlayers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No players added',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            ...teamPlayers.map((entry) {
              final player = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: player.isRegistered
                            ? accentColor.withValues(alpha: 0.15)
                            : MidnightPitchTheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: player.isRegistered
                          ? Icon(Icons.verified, size: 14, color: accentColor)
                          : Text(
                              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.primaryText,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MidnightPitchTheme.primaryText,
                            ),
                          ),
                          if (player.email != null) ...[
                            Text(
                              player.email!,
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 10,
                                color: MidnightPitchTheme.mutedText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (player.position.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MidnightPitchTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.position,
                          style: TextStyle(
                            fontFamily: MidnightPitchTheme.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MidnightPitchTheme.mutedText,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removePlayerFromRoster(_roster.indexOf(player)),
                      child: Icon(Icons.close, size: 16, color: MidnightPitchTheme.mutedText),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTeamField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 14,
              color: MidnightPitchTheme.primaryText,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                color: MidnightPitchTheme.mutedText,
              ),
              prefixIcon: Icon(icon, color: MidnightPitchTheme.mutedText, size: 20),
              filled: true,
              fillColor: MidnightPitchTheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MidnightPitchTheme.electricMint),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}