import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

class PositionPickerDialog extends StatefulWidget {
  final String? initialPrimary;
  final String? initialSecondary;

  const PositionPickerDialog({
    super.key,
    this.initialPrimary,
    this.initialSecondary,
  });

  @override
  State<PositionPickerDialog> createState() => _PositionPickerDialogState();
}

class _PositionPickerDialogState extends State<PositionPickerDialog> {
  String? _primary;
  String? _secondary;
  int _step = 0;

  static const _positions = [
    {'code': 'GK', 'name': 'Goalkeeper', 'zone': 'DEFENCE'},
    {'code': 'CB', 'name': 'Centre-Back', 'zone': 'DEFENCE'},
    {'code': 'LB', 'name': 'Left-Back', 'zone': 'DEFENCE'},
    {'code': 'RB', 'name': 'Right-Back', 'zone': 'DEFENCE'},
    {'code': 'CDM', 'name': 'Def. Mid', 'zone': 'MIDFIELD'},
    {'code': 'CM', 'name': 'Central Mid', 'zone': 'MIDFIELD'},
    {'code': 'CAM', 'name': 'Att. Mid', 'zone': 'MIDFIELD'},
    {'code': 'LM', 'name': 'Left Mid', 'zone': 'MIDFIELD'},
    {'code': 'RM', 'name': 'Right Mid', 'zone': 'MIDFIELD'},
    {'code': 'LW', 'name': 'Left Wing', 'zone': 'ATTACK'},
    {'code': 'RW', 'name': 'Right Wing', 'zone': 'ATTACK'},
    {'code': 'ST', 'name': 'Striker', 'zone': 'ATTACK'},
  ];

  @override
  void initState() {
    super.initState();
    _primary = widget.initialPrimary;
    _secondary = widget.initialSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mutedParchment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _step == 0 ? 'Primary Position' : 'Secondary Position',
            style: AppTheme.bebasDisplay.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _positions.map((p) {
              final code = p['code']!;
              final isSelected = (_step == 0 && _primary == code) ||
                  (_step == 1 && _secondary == code);
              final isDisabled = _step == 1 && _primary == code;

              return GestureDetector(
                onTap: isDisabled ? null : () {
                  setState(() {
                    if (_step == 0) {
                      _primary = isSelected ? null : code;
                    } else {
                      _secondary = isSelected ? null : code;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.heroCtaGradient : null,
                    color: isDisabled
                        ? AppTheme.elevatedSurface.withValues(alpha: 0.3)
                        : isSelected
                            ? null
                            : AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: AppTheme.cardBorderColorLight),
                  ),
                  child: Column(
                    children: [
                      Text(
                        code,
                        style: AppTheme.bebasDisplay.copyWith(
                          fontSize: 20,
                          color: isDisabled
                              ? AppTheme.mutedParchment
                              : isSelected
                                  ? AppTheme.parchment
                                  : AppTheme.parchment,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['name']!,
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 10,
                          color: isDisabled
                              ? AppTheme.mutedParchment
                              : isSelected
                                  ? AppTheme.gold
                                  : AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step == 1)
                Expanded(
                  child: _button('Back', () => setState(() => _step = 0), isSecondary: true),
                ),
              if (_step == 1) const SizedBox(width: 12),
              Expanded(
                child: _button(
                  _step == 0 ? 'Next' : 'Done',
                  () {
                    if (_step == 0 && _primary != null) {
                      setState(() => _step = 1);
                    } else {
                      Navigator.pop(context, {
                        'primary': _primary,
                        'secondary': _secondary,
                      });
                    }
                  },
                  enabled: _step == 0 ? _primary != null : true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onTap, {bool isSecondary = false, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: isSecondary ? null : AppTheme.heroCtaGradient,
          borderRadius: BorderRadius.circular(12),
          border: isSecondary ? Border.all(color: AppTheme.cardBorderColorLight) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? AppTheme.parchment : AppTheme.mutedParchment,
          ),
        ),
      ),
    );
  }
}
