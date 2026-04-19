import 'package:flutter/material.dart';
import '../theme/midnight_pitch_theme.dart';
import '../services/appwrite_service.dart';
import '../features/match/data/models/live_match_models.dart';

/// Reusable bottom sheet for adding a player with Appwrite user search.
/// Shows name + email autocomplete as the user types.
class AddPlayerSheet extends StatefulWidget {
  final void Function(LivePlayerInfo player) onAdd;
  final AppwriteService appwriteService;

  const AddPlayerSheet({
    super.key,
    required this.onAdd,
    required this.appwriteService,
  });

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  final _nameCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedPosition;
  String _selectedTeam = 'home';
  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  Map<String, String>? _confirmedUser;

  static const _positions = [
    ('GK', 'Goalkeeper'),
    ('CB', 'Centre-Back'),
    ('LB', 'Left-Back'),
    ('RB', 'Right-Back'),
    ('CDM', 'Def. Midfielder'),
    ('CM', 'Central Mid'),
    ('CAM', 'Att. Midfielder'),
    ('LM', 'Left Mid'),
    ('RM', 'Right Mid'),
    ('LW', 'Left Winger'),
    ('RW', 'Right Winger'),
    ('ST', 'Striker'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged() async {
    final query = _nameCtrl.text.trim();
    if (query.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await widget.appwriteService.searchUsersByName(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _selectSuggestion(Map<String, String> user) {
    setState(() {
      _confirmedUser = user;
      _nameCtrl.text = user['name'] ?? '';
      _suggestions = [];
      if (user['primaryPosition']?.isNotEmpty == true) {
        _selectedPosition = user['primaryPosition'];
      }
    });
  }

  void _clearSuggestion() {
    setState(() {
      _confirmedUser = null;
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a player name'),
          backgroundColor: MidnightPitchTheme.liveRed,
        ),
      );
      return;
    }

    final LivePlayerInfo player;
    if (_confirmedUser != null) {
      player = LivePlayerInfo(
        id: _confirmedUser!['id']!,
        name: _confirmedUser!['name']!,
        position: _selectedPosition ?? _confirmedUser!['primaryPosition'] ?? '',
        email: _confirmedUser!['email'],
        isRegistered: true,
        team: _selectedTeam,
      );
    } else {
      player = LivePlayerInfo(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        position: _selectedPosition ?? '',
        isRegistered: false,
        team: _selectedTeam,
      );
    }

    widget.onAdd(player);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Player to Roster',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.primaryText,
                )),
            const SizedBox(height: 20),
            // Player name with autocomplete
            TextField(
              controller: _nameCtrl,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(color: MidnightPitchTheme.primaryText),
              decoration: InputDecoration(
                labelText: 'Player Name',
                labelStyle: TextStyle(color: MidnightPitchTheme.mutedText),
                hintText: 'Type to search registered players...',
                hintStyle: TextStyle(
                  color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: MidnightPitchTheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MidnightPitchTheme.electricBlue,
                          ),
                        ),
                      )
                    : _confirmedUser != null
                        ? IconButton(
                            icon: Icon(Icons.close, size: 18,
                              color: MidnightPitchTheme.mutedText),
                            onPressed: () {
                              _nameCtrl.clear();
                              _clearSuggestion();
                            },
                          )
                        : null,
              ),
              onChanged: (_) {},
            ),
            // Suggestions list
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: MidnightPitchTheme.surfaceContainerHigh,
                  ),
                  itemBuilder: (context, index) {
                    final user = _suggestions[index];
                    final isSelected = _confirmedUser?['id'] == user['id'];
                    return InkWell(
                      onTap: () => _selectSuggestion(user),
                      borderRadius: index == 0
                          ? const BorderRadius.vertical(top: Radius.circular(12))
                          : index == _suggestions.length - 1
                              ? const BorderRadius.vertical(bottom: Radius.circular(12))
                              : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isSelected
                            ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.1)
                            : null,
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (user['name'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                fontFamily: MidnightPitchTheme.fontFamily,
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: MidnightPitchTheme.electricBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] ?? '',
                                    style: TextStyle(
                                      fontFamily: MidnightPitchTheme.fontFamily,
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: MidnightPitchTheme.primaryText,
                                    )),
                                const SizedBox(height: 2),
                                Text(user['email'] ?? '',
                                    style: TextStyle(
                                      fontFamily: MidnightPitchTheme.fontFamily,
                                      fontSize: 11,
                                      color: MidnightPitchTheme.mutedText,
                                    )),
                              ],
                            ),
                          ),
                          if (user['primaryPosition']?.isNotEmpty == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MidnightPitchTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(user['primaryPosition']!,
                                  style: TextStyle(
                                    fontFamily: MidnightPitchTheme.fontFamily,
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: MidnightPitchTheme.mutedText,
                                  )),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.add_circle_outline,
                            color: isSelected
                                ? MidnightPitchTheme.electricBlue
                                : MidnightPitchTheme.mutedText,
                            size: 20),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
            // Confirmed user badge
            if (_confirmedUser != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.verified, size: 16, color: MidnightPitchTheme.electricBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registered player — stats will be tracked',
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: MidnightPitchTheme.electricBlue,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            // Position selector
            Text('POSITION',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.1,
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positions.map((p) {
                final isSelected = _selectedPosition == p.$1;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedPosition = isSelected ? null : p.$1;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MidnightPitchTheme.electricBlue
                          : MidnightPitchTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: MidnightPitchTheme.electricBlue)
                          : null,
                    ),
                    child: Text(
                      p.$1,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? MidnightPitchTheme.surfaceDim
                            : MidnightPitchTheme.primaryText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Team selector
            Text('TEAM',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.mutedText,
                  letterSpacing: 0.1,
                )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTeam = 'home'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTeam == 'home'
                          ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                          : MidnightPitchTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: _selectedTeam == 'home'
                          ? Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text('HOME',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: _selectedTeam == 'home' ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedTeam == 'home'
                              ? MidnightPitchTheme.electricBlue
                              : MidnightPitchTheme.mutedText,
                        )),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTeam = 'away'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTeam == 'away'
                          ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                          : MidnightPitchTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: _selectedTeam == 'away'
                          ? Border.all(color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text('AWAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: _selectedTeam == 'away' ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedTeam == 'away'
                              ? MidnightPitchTheme.electricBlue
                              : MidnightPitchTheme.mutedText,
                        )),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            // Add button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MidnightPitchTheme.electricBlue,
                  foregroundColor: MidnightPitchTheme.surfaceDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _confirmedUser != null ? 'ADD REGISTERED PLAYER' : 'ADD PLAYER',
                  style: const TextStyle(
                    fontFamily: MidnightPitchTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Show the Add Player sheet as a modal bottom sheet.
Future<LivePlayerInfo?> showAddPlayerSheet(BuildContext context, AppwriteService appwriteService) async {
  LivePlayerInfo? result;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: MidnightPitchTheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => AddPlayerSheet(
      appwriteService: appwriteService,
      onAdd: (player) {
        result = player;
      },
    ),
  );
  return result;
}