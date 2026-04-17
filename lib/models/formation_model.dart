/// Player position slot for formations and lineups.
/// Position stored as percentages of pitch dimensions.
class PlayerPositionSlot {
  final String slotId;
  final String positionLabel;
  final double xPercent;
  final double yPercent;
  final String? assignedPlayerId;
  final String? assignedPlayerName;

  const PlayerPositionSlot({
    required this.slotId,
    required this.positionLabel,
    required this.xPercent,
    required this.yPercent,
    this.assignedPlayerId,
    this.assignedPlayerName,
  });

  bool get isAssigned => assignedPlayerId != null;

  factory PlayerPositionSlot.fromJson(Map<String, dynamic> json) {
    return PlayerPositionSlot(
      slotId: json['slotId'] ?? '',
      positionLabel: json['positionLabel'] ?? '',
      xPercent: (json['xPercent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['yPercent'] as num?)?.toDouble() ?? 0.0,
      assignedPlayerId: json['assignedPlayerId'],
      assignedPlayerName: json['assignedPlayerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'positionLabel': positionLabel,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'assignedPlayerId': assignedPlayerId,
      'assignedPlayerName': assignedPlayerName,
    };
  }

  PlayerPositionSlot copyWith({
    String? slotId,
    String? positionLabel,
    double? xPercent,
    double? yPercent,
    String? assignedPlayerId,
    String? assignedPlayerName,
  }) {
    return PlayerPositionSlot(
      slotId: slotId ?? this.slotId,
      positionLabel: positionLabel ?? this.positionLabel,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      assignedPlayerId: assignedPlayerId ?? this.assignedPlayerId,
      assignedPlayerName: assignedPlayerName ?? this.assignedPlayerName,
    );
  }
}

/// Formation model for team tactics.
class FormationModel {
  final String id;
  final String formationId;
  final String teamId;
  final String name;
  final String formationType;
  final List<PlayerPositionSlot> slots;
  final String? notes;
  final DateTime createdAt;
  final bool isDefault;

  const FormationModel({
    required this.id,
    required this.formationId,
    required this.teamId,
    required this.name,
    required this.formationType,
    required this.slots,
    this.notes,
    required this.createdAt,
    this.isDefault = false,
  });

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    final slotsData = json['slots'] as List? ?? [];
    return FormationModel(
      id: json['\$id'] ?? '',
      formationId: json['formationId'] ?? '',
      teamId: json['teamId'] ?? '',
      name: json['name'] ?? '',
      formationType: json['formationType'] ?? '4-4-2',
      slots: slotsData.map((s) => PlayerPositionSlot.fromJson(s as Map<String, dynamic>)).toList(),
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formationId': formationId,
      'teamId': teamId,
      'name': name,
      'formationType': formationType,
      'slots': slots.map((s) => s.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  FormationModel copyWith({
    String? id,
    String? formationId,
    String? teamId,
    String? name,
    String? formationType,
    List<PlayerPositionSlot>? slots,
    String? notes,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return FormationModel(
      id: id ?? this.id,
      formationId: formationId ?? this.formationId,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      formationType: formationType ?? this.formationType,
      slots: slots ?? this.slots,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Pre-built formation templates with standard position layouts.
class FormationTemplates {
  /// Get slots for a formation type.
  static List<PlayerPositionSlot> getSlotsForFormation(String formationType) {
    switch (formationType) {
      case '4-4-2':
        return _fourFourTwo;
      case '4-3-3':
        return _fourThreeThree;
      case '4-2-3-1':
        return _fourTwoThreeOne;
      case '3-5-2':
        return _threeFiveTwo;
      case '5-4-1':
        return _fiveFourOne;
      case '4-1-4-1':
        return _fourOneFourOne;
      default:
        return _fourFourTwo;
    }
  }

  /// Supported formation types.
  static const List<String> supportedFormations = [
    '4-4-2',
    '4-3-3',
    '4-2-3-1',
    '3-5-2',
    '5-4-1',
    '4-1-4-1',
  ];

  // GK at bottom (yPercent: 0.92), attackers at top (yPercent: 0.08-0.18)
  static final List<PlayerPositionSlot> _fourFourTwo = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'lb', positionLabel: 'LB', xPercent: 0.15, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.35, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.65, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'rb', positionLabel: 'RB', xPercent: 0.85, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'lm', positionLabel: 'LM', xPercent: 0.12, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'cm1', positionLabel: 'CM', xPercent: 0.38, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'cm2', positionLabel: 'CM', xPercent: 0.62, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'rm', positionLabel: 'RM', xPercent: 0.88, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'st1', positionLabel: 'ST', xPercent: 0.38, yPercent: 0.18),
    PlayerPositionSlot(slotId: 'st2', positionLabel: 'ST', xPercent: 0.62, yPercent: 0.18),
  ];

  static final List<PlayerPositionSlot> _fourThreeThree = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'lb', positionLabel: 'LB', xPercent: 0.15, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.35, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.65, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'rb', positionLabel: 'RB', xPercent: 0.85, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cdm', positionLabel: 'CDM', xPercent: 0.5, yPercent: 0.62),
    PlayerPositionSlot(slotId: 'cm1', positionLabel: 'CM', xPercent: 0.32, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'cm2', positionLabel: 'CM', xPercent: 0.68, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'lw', positionLabel: 'LW', xPercent: 0.15, yPercent: 0.22),
    PlayerPositionSlot(slotId: 'rw', positionLabel: 'RW', xPercent: 0.85, yPercent: 0.22),
    PlayerPositionSlot(slotId: 'st', positionLabel: 'ST', xPercent: 0.5, yPercent: 0.12),
  ];

  static final List<PlayerPositionSlot> _fourTwoThreeOne = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'lb', positionLabel: 'LB', xPercent: 0.15, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.35, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.65, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'rb', positionLabel: 'RB', xPercent: 0.85, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cdm1', positionLabel: 'CDM', xPercent: 0.38, yPercent: 0.60),
    PlayerPositionSlot(slotId: 'cdm2', positionLabel: 'CDM', xPercent: 0.62, yPercent: 0.60),
    PlayerPositionSlot(slotId: 'lam', positionLabel: 'LAM', xPercent: 0.25, yPercent: 0.42),
    PlayerPositionSlot(slotId: 'cam', positionLabel: 'CAM', xPercent: 0.5, yPercent: 0.38),
    PlayerPositionSlot(slotId: 'ram', positionLabel: 'RAM', xPercent: 0.75, yPercent: 0.42),
    PlayerPositionSlot(slotId: 'st', positionLabel: 'ST', xPercent: 0.5, yPercent: 0.15),
  ];

  static final List<PlayerPositionSlot> _threeFiveTwo = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.30, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.5, yPercent: 0.80),
    PlayerPositionSlot(slotId: 'cb3', positionLabel: 'CB', xPercent: 0.70, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'lwb', positionLabel: 'LWB', xPercent: 0.12, yPercent: 0.55),
    PlayerPositionSlot(slotId: 'cm1', positionLabel: 'CM', xPercent: 0.35, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'cdm', positionLabel: 'CDM', xPercent: 0.5, yPercent: 0.60),
    PlayerPositionSlot(slotId: 'cm2', positionLabel: 'CM', xPercent: 0.65, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'rwb', positionLabel: 'RWB', xPercent: 0.88, yPercent: 0.55),
    PlayerPositionSlot(slotId: 'st1', positionLabel: 'ST', xPercent: 0.38, yPercent: 0.18),
    PlayerPositionSlot(slotId: 'st2', positionLabel: 'ST', xPercent: 0.62, yPercent: 0.18),
  ];

  static final List<PlayerPositionSlot> _fiveFourOne = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'lwb', positionLabel: 'LWB', xPercent: 0.10, yPercent: 0.72),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.30, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.5, yPercent: 0.82),
    PlayerPositionSlot(slotId: 'cb3', positionLabel: 'CB', xPercent: 0.70, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'rwb', positionLabel: 'RWB', xPercent: 0.90, yPercent: 0.72),
    PlayerPositionSlot(slotId: 'lm', positionLabel: 'LM', xPercent: 0.15, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'cm1', positionLabel: 'CM', xPercent: 0.40, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'cm2', positionLabel: 'CM', xPercent: 0.60, yPercent: 0.52),
    PlayerPositionSlot(slotId: 'rm', positionLabel: 'RM', xPercent: 0.85, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'st', positionLabel: 'ST', xPercent: 0.5, yPercent: 0.15),
  ];

  static final List<PlayerPositionSlot> _fourOneFourOne = [
    PlayerPositionSlot(slotId: 'gk', positionLabel: 'GK', xPercent: 0.5, yPercent: 0.92),
    PlayerPositionSlot(slotId: 'lb', positionLabel: 'LB', xPercent: 0.15, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cb1', positionLabel: 'CB', xPercent: 0.35, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'cb2', positionLabel: 'CB', xPercent: 0.65, yPercent: 0.78),
    PlayerPositionSlot(slotId: 'rb', positionLabel: 'RB', xPercent: 0.85, yPercent: 0.75),
    PlayerPositionSlot(slotId: 'cdm', positionLabel: 'CDM', xPercent: 0.5, yPercent: 0.62),
    PlayerPositionSlot(slotId: 'lm', positionLabel: 'LM', xPercent: 0.12, yPercent: 0.48),
    PlayerPositionSlot(slotId: 'cm1', positionLabel: 'CM', xPercent: 0.38, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'cm2', positionLabel: 'CM', xPercent: 0.62, yPercent: 0.50),
    PlayerPositionSlot(slotId: 'rm', positionLabel: 'RM', xPercent: 0.88, yPercent: 0.48),
    PlayerPositionSlot(slotId: 'st', positionLabel: 'ST', xPercent: 0.5, yPercent: 0.15),
  ];
}