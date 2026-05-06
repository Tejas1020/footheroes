import 'package:flutter/material.dart';

class FootballPosition {
  final String code;
  final String name;
  final String category; // goalkeeper, defender, midfielder, forward
  final IconData icon;

  const FootballPosition({
    required this.code,
    required this.name,
    required this.category,
    required this.icon,
  });

  static const List<FootballPosition> all = [
    FootballPosition(code: 'GK', name: 'Goalkeeper', category: 'goalkeeper', icon: Icons.radio_button_checked),
    FootballPosition(code: 'CB', name: 'Centre-Back', category: 'defender', icon: Icons.shield),
    FootballPosition(code: 'LB', name: 'Left-Back', category: 'defender', icon: Icons.shield_outlined),
    FootballPosition(code: 'RB', name: 'Right-Back', category: 'defender', icon: Icons.shield_outlined),
    FootballPosition(code: 'LWB', name: 'Left Wing-Back', category: 'defender', icon: Icons.arrow_right_alt),
    FootballPosition(code: 'RWB', name: 'Right Wing-Back', category: 'defender', icon: Icons.arrow_right_alt),
    FootballPosition(code: 'CDM', name: 'Defensive Midfielder', category: 'midfielder', icon: Icons.sync_alt),
    FootballPosition(code: 'CM', name: 'Central Midfielder', category: 'midfielder', icon: Icons.sync_alt),
    FootballPosition(code: 'CAM', name: 'Attacking Midfielder', category: 'midfielder', icon: Icons.bolt),
    FootballPosition(code: 'LM', name: 'Left Midfielder', category: 'midfielder', icon: Icons.bolt),
    FootballPosition(code: 'RM', name: 'Right Midfielder', category: 'midfielder', icon: Icons.bolt),
    FootballPosition(code: 'LW', name: 'Left Winger', category: 'forward', icon: Icons.flash_on),
    FootballPosition(code: 'RW', name: 'Right Winger', category: 'forward', icon: Icons.flash_on),
    FootballPosition(code: 'ST', name: 'Striker', category: 'forward', icon: Icons.sports_soccer),
    FootballPosition(code: 'CF', name: 'Centre Forward', category: 'forward', icon: Icons.sports_soccer),
  ];

  static List<FootballPosition> get primaryPositions => all;

  static List<FootballPosition> get secondaryPositions => all;

  static List<FootballPosition> getByCategory(String category) =>
      all.where((p) => p.category == category).toList();
}
