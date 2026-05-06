import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Bottom sheet for picking a player position.
class PositionPickerBottomSheet extends StatefulWidget {
  final String currentPosition;
  final ValueChanged<String> onSelected;

  const PositionPickerBottomSheet({
    super.key,
    required this.currentPosition,
    required this.onSelected,
  });

  @override
  State<PositionPickerBottomSheet> createState() => _PositionPickerBottomSheetState();
}

class _PositionPickerBottomSheetState
    extends State<PositionPickerBottomSheet> {
  late String _selected;

  static const _positions = [
    'GK',
    'LB',
    'CB',
    'RB',
    'CDM',
    'CM',
    'CAM',
    'LW',
    'RW',
    'ST',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPosition;
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
              Text('SELECT POSITION', style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _positions.map((pos) {
              final isSelected = _selected == pos;
              return GestureDetector(
                onTap: () => setState(() => _selected = pos),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.cardinal
                        : AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? null : AppTheme.cardBorder,
                  ),
                  child: Text(
                    pos,
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 16,
                      color: isSelected
                          ? AppTheme.parchment
                          : AppTheme.gold,
                      letterSpacing: 0.5,
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
              onPressed: () {
                widget.onSelected(_selected);
                Navigator.pop(context);
              },
              style: AppTheme.primaryButton,
              child: const Text('CONFIRM'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPositionPicker(
  BuildContext context, {
  required String currentPosition,
  required ValueChanged<String> onSelected,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PositionPickerBottomSheet(
      currentPosition: currentPosition,
      onSelected: onSelected,
    ),
  );
}
