import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_model.dart';

/// Tournament creation screen - allows organizers to set up new tournaments.
/// Handles format selection, type selection, team limits, and optional sponsor.
class TournamentCreateScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCreated;

  const TournamentCreateScreen({
    super.key,
    this.onBack,
    this.onCreated,
  });

  @override
  ConsumerState<TournamentCreateScreen> createState() => _TournamentCreateScreenState();
}

class _TournamentCreateScreenState extends ConsumerState<TournamentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sponsorNameController = TextEditingController();

  String _selectedFormat = '5v5';
  String _selectedType = 'knockout';
  int _selectedMaxTeams = 8;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;

  final List<String> _formatOptions = ['5v5', '7v7', '9v9', '11v11'];
  final List<String> _typeOptions = ['knockout', 'league', 'group_knockout'];
  final List<int> _teamOptions = [4, 8, 16, 32];

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _sponsorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceDim,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: MidnightPitchTheme.primaryText),
          onPressed: widget.onBack ?? () => context.pop(),
        ),
        title: Text(
          'Create Tournament',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createTournament,
            child: Text(
              'Create',
              style: TextStyle(
                color: MidnightPitchTheme.electricMint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSection(
              'Basic Info',
              [
                _buildNameField(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Format',
              [
                _buildFormatSelector(),
                const SizedBox(height: 16),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildTeamCountSelector(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Details',
              [
                _buildVenueField(),
                const SizedBox(height: 16),
                _buildDatePickers(),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Optional',
              [
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildSponsorField(),
              ],
            ),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MidnightPitchTheme.electricMint,
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
            children: children,
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // NAME FIELD
  // =============================================================================

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(color: MidnightPitchTheme.primaryText),
      decoration: InputDecoration(
        labelText: 'Tournament Name',
        labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.electricMint),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a tournament name';
        }
        if (value.length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  // =============================================================================
  // FORMAT SELECTORS
  // =============================================================================

  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Format',
          style: TextStyle(
            color: MidnightPitchTheme.mutedText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _formatOptions.map((format) {
            final isSelected = _selectedFormat == format;
            return GestureDetector(
              onTap: () => setState(() => _selectedFormat = format),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MidnightPitchTheme.electricMint
                      : MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  format,
                  style: TextStyle(
                    color: MidnightPitchTheme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Type',
          style: TextStyle(
            color: MidnightPitchTheme.mutedText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _typeOptions.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MidnightPitchTheme.electricMint
                      : MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: 18,
                      color: isSelected ? MidnightPitchTheme.primaryText : MidnightPitchTheme.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTypeLabel(type),
                      style: TextStyle(
                        color: MidnightPitchTheme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'knockout':
        return Icons.timer;
      case 'league':
        return Icons.calendar_view_month;
      case 'group_knockout':
        return Icons.dashboard;
      default:
        return Icons.emoji_events;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'knockout':
        return 'Knockout';
      case 'league':
        return 'League';
      case 'group_knockout':
        return 'Groups + Knockout';
      default:
        return type;
    }
  }

  Widget _buildTeamCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Teams',
          style: TextStyle(
            color: MidnightPitchTheme.mutedText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _teamOptions.map((count) {
            final isSelected = _selectedMaxTeams == count;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMaxTeams = count),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MidnightPitchTheme.electricMint
                        : MidnightPitchTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MidnightPitchTheme.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
  // DETAILS
  // =============================================================================

  Widget _buildVenueField() {
    return TextFormField(
      controller: _venueController,
      style: TextStyle(color: MidnightPitchTheme.primaryText),
      decoration: InputDecoration(
        labelText: 'Venue (optional)',
        labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
        prefixIcon: Icon(Icons.location_on_outlined, color: MidnightPitchTheme.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.electricMint),
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            'Start Date',
            _startDate,
            (date) => setState(() => _startDate = date),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDatePicker(
            'End Date',
            _endDate,
            (date) => setState(() => _endDate = date),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, void Function(DateTime) onSelect) {
    return GestureDetector(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: MidnightPitchTheme.electricMint,
                  onPrimary: MidnightPitchTheme.surfaceContainer,
                  surface: MidnightPitchTheme.surfaceDim,
                  onSurface: MidnightPitchTheme.primaryText,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selected != null) {
          onSelect(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: MidnightPitchTheme.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? _formatDate(date) : 'Select',
              style: TextStyle(
                color: MidnightPitchTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // OPTIONAL FIELDS
  // =============================================================================

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: TextStyle(color: MidnightPitchTheme.primaryText),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.electricMint),
        ),
      ),
    );
  }

  Widget _buildSponsorField() {
    return TextFormField(
      controller: _sponsorNameController,
      style: TextStyle(color: MidnightPitchTheme.primaryText),
      decoration: InputDecoration(
        labelText: 'Sponsor Name (optional)',
        labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
        prefixIcon: Icon(Icons.star_outline, color: MidnightPitchTheme.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MidnightPitchTheme.electricMint),
        ),
      ),
    );
  }

  // =============================================================================
  // PREVIEW
  // =============================================================================

  Widget _buildPreview() {
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Tournament Name';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.3),
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MidnightPitchTheme.electricMint.withValues(alpha: 0.3),
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
                  color: MidnightPitchTheme.electricMint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedFormat,
                  style: TextStyle(
                    color: MidnightPitchTheme.electricMint,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getTypeLabel(_selectedType),
                  style: TextStyle(
                    color: Colors.purple.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              color: MidnightPitchTheme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.groups, size: 16, color: MidnightPitchTheme.mutedText),
              const SizedBox(width: 4),
              Text(
                '$_selectedMaxTeams teams max',
                style: TextStyle(
                  color: MidnightPitchTheme.mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // CREATE TOURNAMENT
  // =============================================================================

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: MidnightPitchTheme.liveRed,
          ),
        );
      }
      return;
    }

    if (_startDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a start date'),
            backgroundColor: MidnightPitchTheme.liveRed,
          ),
        );
      }
      return;
    }

    setState(() => _isCreating = true);

    // Read auth state before async gap
    final authState = ref.read(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create a tournament'),
            backgroundColor: MidnightPitchTheme.liveRed,
          ),
        );
      }
      return;
    }

    final tournamentId = 't_${DateTime.now().millisecondsSinceEpoch}';

    final tournament = TournamentModel(
      id: tournamentId,
      tournamentId: tournamentId,
      name: _nameController.text.trim(),
      format: _selectedFormat,
      type: _selectedType,
      maxTeams: _selectedMaxTeams,
      teamIds: [],
      createdBy: userId,
      status: 'draft',
      startDate: _startDate,
      endDate: _endDate,
      venue: _venueController.text.isNotEmpty ? _venueController.text.trim() : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text.trim() : null,
      isPaid: false,
      sponsorName: _sponsorNameController.text.isNotEmpty ? _sponsorNameController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    try {
      // Read tournament notifier before async gap
      final tournamentNotifier = ref.read(tournamentProvider.notifier);
      final created = await tournamentNotifier.createTournament(tournament);

      setState(() => _isCreating = false);

      if (created != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${created.name} created!'),
            backgroundColor: MidnightPitchTheme.electricMint,
          ),
        );
        widget.onCreated?.call();
        if (mounted) context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create tournament. Please try again.'),
            backgroundColor: MidnightPitchTheme.liveRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: MidnightPitchTheme.liveRed,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}