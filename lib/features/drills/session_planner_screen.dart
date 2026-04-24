import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../models/session_plan_model.dart';
import '../../../models/drill_model.dart';
import '../../../providers/squad_provider.dart';
import '../../../providers/drill_provider.dart';

/// Session Planner screen — create training sessions using Dark Colour System.
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
      ref.read(drillProvider.notifier).loadAllDrills();
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
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('SESSION BASICS'),
                    const SizedBox(height: 16),
                    _buildTitleInput(),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(),
                    const SizedBox(height: 16),
                    _buildDurationSelector(),
                    const SizedBox(height: 32),
                    _buildDrillSection(
                      'WARM-UP',
                      _warmUpDrillIds,
                      drillState.drills.where((d) => d.skillLevel.toLowerCase().contains('beginner') || d.duration <= 10).toList(),
                      AppTheme.rose,
                    ),
                    const SizedBox(height: 24),
                    _buildDrillSection(
                      'MAIN SESSION',
                      _mainDrillIds,
                      drillState.drills.where((d) => d.duration > 10).toList(),
                      AppTheme.cardinal,
                    ),
                    const SizedBox(height: 24),
                    _buildDrillSection(
                      'COOL-DOWN',
                      _coolDownDrillIds,
                      drillState.drills.where((d) => d.duration <= 10).toList(),
                      AppTheme.navy,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionLabel('COACH NOTES'),
                    const SizedBox(height: 12),
                    _buildNotesInput(),
                    const SizedBox(height: 32),
                    _buildSummaryCard(),
                    const SizedBox(height: 40),
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

  Widget _buildSectionLabel(String label) => Row(
    children: [
      AppTheme.accentBar(),
      const SizedBox(width: 8),
      Text(label, style: AppTheme.labelSmall),
    ],
  );

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.abyss,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.parchment, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            widget.existingSession != null ? 'EDIT SESSION' : 'NEW SESSION',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 18, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Container(
      decoration: AppTheme.standardCard,
      child: TextField(
        controller: _titleController,
        style: AppTheme.bodyBold,
        decoration: InputDecoration(
          hintText: 'Session Title (e.g. Pre-Match Tactical)',
          hintStyle: AppTheme.dmSans.copyWith(color: AppTheme.gold.withValues(alpha: 0.4)),
          filled: true,
          fillColor: AppTheme.cardSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(child: _dateTile(Icons.calendar_today_rounded, _formatDate(_sessionDate), _selectDate)),
        const SizedBox(width: 12),
        Expanded(child: _dateTile(Icons.access_time_rounded, _formatTime(_sessionDate), _selectTime)),
      ],
    );
  }

  Widget _dateTile(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.standardCard,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.cardinal, size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.dmSans.copyWith(fontSize: 13, color: AppTheme.parchment, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DURATION: $_durationMinutes MIN', style: AppTheme.labelSmall.copyWith(fontSize: 9)),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 30, max: 180, divisions: 10,
          activeColor: AppTheme.cardinal,
          inactiveColor: AppTheme.elevatedSurface,
          onChanged: (v) => setState(() => _durationMinutes = v.round()),
        ),
      ],
    );
  }

  Widget _buildDrillSection(String title, List<String> ids, List<DrillModel> available, Color color) {
    final selected = available.where((d) => ids.contains(d.drillId)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.dmSans.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.gold, letterSpacing: 1)),
            GestureDetector(
              onTap: () => _showDrillPicker(title, ids, available, color),
              child: Text('+ ADD', style: AppTheme.bodyBold.copyWith(fontSize: 11, color: color)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selected.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.elevatedSurface, borderRadius: BorderRadius.circular(12), border: AppTheme.cardBorder),
            child: Text('No drills selected', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
          )
        else
          ...selected.map((d) => _drillItem(d, ids, color)),
      ],
    );
  }

  Widget _drillItem(DrillModel d, List<String> ids, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: AppTheme.standardCard.copyWith(border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.sports_soccer, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(d.title.toUpperCase(), style: AppTheme.bebasDisplay.copyWith(fontSize: 16, color: AppTheme.parchment))),
        GestureDetector(onTap: () => setState(() => ids.remove(d.drillId)), child: const Icon(Icons.close_rounded, color: AppTheme.gold, size: 18)),
      ],
    ),
  );

  Widget _buildNotesInput() => Container(
    decoration: AppTheme.standardCard,
    child: TextField(
      controller: _notesController,
      maxLines: 3,
      style: AppTheme.bodyReg,
      decoration: InputDecoration(
        hintText: 'Add private coaching notes...',
        hintStyle: AppTheme.dmSans.copyWith(color: AppTheme.gold.withValues(alpha: 0.4)),
        filled: true, fillColor: AppTheme.cardSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _buildSummaryCard() {
    final count = _warmUpDrillIds.length + _mainDrillIds.length + _coolDownDrillIds.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sumItem('DRILLS', '$count'),
          _sumItem('PLAN', '$_durationMinutes MIN'),
          _sumItem('INTENSITY', 'HIGH'),
        ],
      ),
    );
  }

  Widget _sumItem(String l, String v) => Column(children: [
    Text(v, style: AppTheme.bebasDisplay.copyWith(fontSize: 22, color: AppTheme.parchment)),
    Text(l, style: AppTheme.labelSmall.copyWith(fontSize: 8)),
  ]);

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _saveSession,
      style: AppTheme.primaryButton,
      child: Text(widget.existingSession != null ? 'UPDATE SESSION' : 'CREATE SESSION'),
    ),
  );

  Future<void> _selectDate() async {
    final p = await showDatePicker(context: context, initialDate: _sessionDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (p != null) setState(() => _sessionDate = DateTime(p.year, p.month, p.day, _sessionDate.hour, _sessionDate.minute));
  }

  Future<void> _selectTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_sessionDate));
    if (t != null) setState(() => _sessionDate = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, t.hour, t.minute));
  }

  void _showDrillPicker(String t, List<String> ids, List<DrillModel> available, Color c) {
    showModalBottomSheet(
      context: context, backgroundColor: AppTheme.abyss,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        children: [
          Padding(padding: const EdgeInsets.all(20), child: Text(t, style: AppTheme.bebasDisplay.copyWith(fontSize: 20))),
          Expanded(child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (ctx, i) {
              final d = available[i];
              final s = ids.contains(d.drillId);
              return ListTile(
                leading: Icon(Icons.sports_soccer, color: s ? c : AppTheme.gold),
                title: Text(d.title, style: AppTheme.bodyBold),
                trailing: Icon(s ? Icons.check_circle : Icons.add_circle_outline, color: s ? c : AppTheme.gold),
                onTap: () {
                  setState(() => s ? ids.remove(d.drillId) : ids.add(d.drillId));
                  Navigator.pop(ctx);
                },
              );
            },
          )),
        ],
      ),
    );
  }

  Future<void> _saveSession() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _isSaving = true);
    final s = SessionPlanModel(
      id: widget.existingSession?.id ?? 's_${DateTime.now().msSinceEpoch}',
      sessionId: widget.existingSession?.sessionId ?? 's_${DateTime.now().msSinceEpoch}',
      teamId: widget.teamId, title: _titleController.text, sessionDate: _sessionDate,
      durationMinutes: _durationMinutes, warmUpDrillIds: _warmUpDrillIds, mainDrillIds: _mainDrillIds,
      coolDownDrillIds: _coolDownDrillIds, notes: _notesController.text, attendeeIds: [], createdAt: DateTime.now(),
    );
    await ref.read(squadProvider.notifier).createSession(s);
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime d) => '${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday-1]} ${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]}';
  String _formatTime(DateTime d) => '${d.hour > 12 ? d.hour-12 : d.hour}:${d.minute.toString().padLeft(2,'0')}${d.hour >= 12 ? 'PM' : 'AM'}';
}

extension on DateTime { int get msSinceEpoch => millisecondsSinceEpoch; }
