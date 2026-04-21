import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';
import '../models/session_plan_model.dart';
import '../models/drill_model.dart';
import '../providers/squad_provider.dart';
import '../providers/drill_provider.dart';

/// Session Planner screen — create training sessions with drills.
class SessionPlannerScreen extends ConsumerStatefulWidget {
  final String teamId;
  final SessionPlanModel? existingSession;
  final VoidCallback? onBack;

  const SessionPlannerScreen({
    super.key,
    required this.teamId,
    this.existingSession,
    this.onBack,
  });

  @override
  ConsumerState<SessionPlannerScreen> createState() => _SessionPlannerScreenState();
}

class _SessionPlannerScreenState extends ConsumerState<SessionPlannerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _sessionDate = DateTime.now().add(const Duration(days: 7));
  int _durationMinutes = 90;

  final List<String> _warmUpDrillIds = [];
  final List<String> _mainDrillIds = [];
  final List<String> _coolDownDrillIds = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      _loadExistingSession();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrills();
    });
  }

  void _loadExistingSession() {
    final session = widget.existingSession!;
    _titleController.text = session.title;
    _notesController.text = session.notes ?? '';
    _sessionDate = session.sessionDate;
    _durationMinutes = session.durationMinutes;
    _warmUpDrillIds.addAll(session.warmUpDrillIds);
    _mainDrillIds.addAll(session.mainDrillIds);
    _coolDownDrillIds.addAll(session.coolDownDrillIds);
  }

  void _loadDrills() {
    ref.read(drillProvider.notifier).loadAllDrills();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drillState = ref.watch(drillProvider);

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleInput(),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    const SizedBox(height: 24),
                    _buildDrillSection(
                      'WARM-UP DRILLS',
                      _warmUpDrillIds,
                      drillState.drills.where((d) => d.type.toLowerCase().contains('warm') || d.duration <= 10).toList(),
                      MidnightPitchTheme.championGold,
                    ),
                    const SizedBox(height: 24),
                    _buildDrillSection(
                      'MAIN DRILLS',
                      _mainDrillIds,
                      drillState.drills.where((d) => d.duration > 10 && !d.type.toLowerCase().contains('cool')).toList(),
                      MidnightPitchTheme.electricBlue,
                    ),
                    const SizedBox(height: 24),
                    _buildDrillSection(
                      'COOL-DOWN DRILLS',
                      _coolDownDrillIds,
                      drillState.drills.where((d) => d.type.toLowerCase().contains('cool') || d.duration <= 5).toList(),
                      MidnightPitchTheme.electricBlue,
                    ),
                    const SizedBox(height: 24),
                    _buildNotesInput(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: MidnightPitchTheme.surfaceDim,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    if (router.canPop()) {
                      router.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: MidnightPitchTheme.electricBlue),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COACH MODE',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: MidnightPitchTheme.championGold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    widget.existingSession != null ? 'Edit Session' : 'New Session',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily,
        color: MidnightPitchTheme.primaryText,
      ),
      decoration: InputDecoration(
        labelText: 'Session Title',
        labelStyle: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          color: MidnightPitchTheme.mutedText,
        ),
        filled: true,
        fillColor: MidnightPitchTheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidnightPitchTheme.electricBlue),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: MidnightPitchTheme.electricBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_sessionDate),
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      color: MidnightPitchTheme.primaryText,
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
            onTap: () => _selectTime(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: MidnightPitchTheme.electricBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(_sessionDate),
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 14,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DURATION: $_durationMinutes MINUTES',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MidnightPitchTheme.mutedText,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 30,
          max: 180,
          divisions: 10,
          activeColor: MidnightPitchTheme.electricBlue,
          inactiveColor: MidnightPitchTheme.surfaceContainerHigh,
          onChanged: (value) {
            setState(() => _durationMinutes = value.round());
          },
        ),
      ],
    );
  }

  Widget _buildDrillSection(
    String title,
    List<String> selectedIds,
    List<DrillModel> availableDrills,
    Color accentColor,
  ) {
    final selectedDrills = availableDrills.where((d) => selectedIds.contains(d.drillId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MidnightPitchTheme.mutedText,
                letterSpacing: 0.08,
              ),
            ),
            GestureDetector(
              onTap: () => _showDrillPicker(title, selectedIds, availableDrills, accentColor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+ Add',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedDrills.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MidnightPitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MidnightPitchTheme.ghostBorder),
            ),
            child: Center(
              child: Text(
                'No drills selected',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 12,
                  color: MidnightPitchTheme.mutedText,
                ),
              ),
            ),
          )
        else
          ...selectedDrills.map((drill) => _buildDrillItem(drill, selectedIds, accentColor)),
      ],
    );
  }

  Widget _buildDrillItem(DrillModel drill, List<String> selectedIds, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.sports_soccer, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.title,
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MidnightPitchTheme.primaryText,
                  ),
                ),
                Text(
                  '${drill.soloOrGroup} · ${drill.duration} min',
                  style: TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 11,
                    color: MidnightPitchTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => selectedIds.remove(drill.drillId)),
            child: const Icon(Icons.close, color: MidnightPitchTheme.mutedText, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      style: TextStyle(
        fontFamily: MidnightPitchTheme.fontFamily,
        color: MidnightPitchTheme.primaryText,
      ),
      decoration: InputDecoration(
        labelText: 'Session Notes (optional)',
        labelStyle: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          color: MidnightPitchTheme.mutedText,
        ),
        filled: true,
        fillColor: MidnightPitchTheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MidnightPitchTheme.electricBlue),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalDrills = _warmUpDrillIds.length + _mainDrillIds.length + _coolDownDrillIds.length;
    final estimatedDuration = _warmUpDrillIds.length * 15 + _mainDrillIds.length * 20 + _coolDownDrillIds.length * 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SESSION SUMMARY',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MidnightPitchTheme.mutedText,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalDrills drills planned',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ESTIMATED',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$estimatedDuration min',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: MidnightPitchTheme.electricBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem('Warm-up', _warmUpDrillIds.length, MidnightPitchTheme.championGold),
              const SizedBox(width: 16),
              _buildSummaryItem('Main', _mainDrillIds.length, MidnightPitchTheme.electricBlue),
              const SizedBox(width: 16),
              _buildSummaryItem('Cool-down', _coolDownDrillIds.length, MidnightPitchTheme.electricBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: MidnightPitchTheme.electricBlue,
          foregroundColor: MidnightPitchTheme.surfaceDim,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(MidnightPitchTheme.surfaceDim),
                ),
              )
            : Text(
                widget.existingSession != null ? 'UPDATE SESSION' : 'SAVE SESSION',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MidnightPitchTheme.electricBlue,
              surface: MidnightPitchTheme.surfaceDim,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _sessionDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _sessionDate.hour,
          _sessionDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sessionDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MidnightPitchTheme.electricBlue,
              surface: MidnightPitchTheme.surfaceDim,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _sessionDate = DateTime(
          _sessionDate.year,
          _sessionDate.month,
          _sessionDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showDrillPicker(
    String title,
    List<String> selectedIds,
    List<DrillModel> availableDrills,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MidnightPitchTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: availableDrills.length,
                itemBuilder: (context, index) {
                  final drill = availableDrills[index];
                  final isSelected = selectedIds.contains(drill.drillId);
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : MidnightPitchTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: isSelected ? MidnightPitchTheme.surfaceDim : accentColor,
                      ),
                    ),
                    title: Text(
                      drill.title,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        color: MidnightPitchTheme.primaryText,
                      ),
                    ),
                    subtitle: Text(
                      '${drill.soloOrGroup} · ${drill.duration} min',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: accentColor)
                        : Icon(Icons.add_circle_outline, color: MidnightPitchTheme.mutedText),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIds.remove(drill.drillId);
                        } else {
                          selectedIds.add(drill.drillId);
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('Please enter a session title');
      return;
    }

    setState(() => _isSaving = true);

    final session = SessionPlanModel(
      id: widget.existingSession?.id ?? 'session_${widget.teamId}_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: widget.existingSession?.sessionId ?? 'session_${widget.teamId}_${DateTime.now().millisecondsSinceEpoch}',
      teamId: widget.teamId,
      title: _titleController.text,
      sessionDate: _sessionDate,
      durationMinutes: _durationMinutes,
      warmUpDrillIds: _warmUpDrillIds,
      mainDrillIds: _mainDrillIds,
      coolDownDrillIds: _coolDownDrillIds,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      attendeeIds: [],
      createdAt: widget.existingSession?.createdAt ?? DateTime.now(),
    );

    final success = await ref.read(squadProvider.notifier).createSession(session);

    setState(() => _isSaving = false);

    if (success) {
      _showSnackBar('Session saved!');
      if (widget.onBack != null) {
        widget.onBack!();
      }
    } else {
      _showSnackBar('Failed to save session');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$ampm';
  }
}