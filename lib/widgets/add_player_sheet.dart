import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../providers/live_match_provider.dart';
import '../../../../../../../features/match/data/models/live_match_models.dart';
import '../services/appwrite_service.dart';

/// Redesigned bottom sheet for adding players to the live match roster.
class AddPlayerSheet extends ConsumerStatefulWidget {
  final String team; // 'home' or 'away'
  const AddPlayerSheet({super.key, required this.team});

  @override
  ConsumerState<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends ConsumerState<AddPlayerSheet> {
  final _nameController = TextEditingController();
  final _posController = TextEditingController();
  String _selectedPos = 'CM';

  @override
  void dispose() {
    _nameController.dispose();
    _posController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final player = LivePlayerInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      position: _selectedPos,
      team: widget.team,
    );

    Navigator.pop(context, player);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(
                'ADD ${widget.team.toUpperCase()} PLAYER',
                style: AppTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            label: 'PLAYER NAME',
            hint: 'Enter full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildPositionSelector(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onSave,
              style: AppTheme.primaryButton,
              child: const Text('ADD TO ROSTER'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: AppTheme.cardBorder,
          ),
          child: TextField(
            controller: controller,
            style: AppTheme.bodyReg,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.dmSans.copyWith(
                color: AppTheme.gold.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppTheme.gold, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSelector() {
    final positions = ['GK', 'LB', 'CB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POSITION', style: AppTheme.labelSmall.copyWith(fontSize: 10)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: positions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final pos = positions[index];
              final isSelected = _selectedPos == pos;
              return GestureDetector(
                onTap: () => setState(() => _selectedPos = pos),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.cardinal : AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? null : AppTheme.cardBorder,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    pos,
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 14,
                      color: isSelected ? AppTheme.parchment : AppTheme.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<LivePlayerInfo?> showAddPlayerSheet(BuildContext context, AppwriteService appwrite, {String team = 'home'}) {
  return showModalBottomSheet<LivePlayerInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddPlayerSheet(team: team),
  );
}
