import 'formation_model.dart';

/// Lineup model for match day starting XI.
class LineupModel {
  final String id;
  final String lineupId;
  final String matchId;
  final String teamId;
  final String formationType;
  final List<PlayerPositionSlot> startingXI;
  final List<String> substituteIds;
  final String? captainId;
  final String? viceCaptainId;
  final String? teamTalkNotes;
  final DateTime createdAt;

  const LineupModel({
    required this.id,
    required this.lineupId,
    required this.matchId,
    required this.teamId,
    required this.formationType,
    required this.startingXI,
    this.substituteIds = const [],
    this.captainId,
    this.viceCaptainId,
    this.teamTalkNotes,
    required this.createdAt,
  });

  /// Check if lineup is complete (11 players assigned).
  bool get isComplete => startingXI.where((s) => s.isAssigned).length >= 11;

  /// Count assigned players.
  int get assignedCount => startingXI.where((s) => s.isAssigned).length;

  factory LineupModel.fromJson(Map<String, dynamic> json) {
    final slotsData = json['startingXI'] as List? ?? [];
    final subsData = json['substituteIds'] as List? ?? [];
    return LineupModel(
      id: json['\$id'] ?? '',
      lineupId: json['lineupId'] ?? '',
      matchId: json['matchId'] ?? '',
      teamId: json['teamId'] ?? '',
      formationType: json['formationType'] ?? '4-4-2',
      startingXI: slotsData.map((s) => PlayerPositionSlot.fromJson(s as Map<String, dynamic>)).toList(),
      substituteIds: subsData.map((s) => s.toString()).toList(),
      captainId: json['captainId'],
      viceCaptainId: json['viceCaptainId'],
      teamTalkNotes: json['teamTalkNotes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineupId': lineupId,
      'matchId': matchId,
      'teamId': teamId,
      'formationType': formationType,
      'startingXI': startingXI.map((s) => s.toJson()).toList(),
      'substituteIds': substituteIds,
      'captainId': captainId,
      'viceCaptainId': viceCaptainId,
      'teamTalkNotes': teamTalkNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LineupModel copyWith({
    String? id,
    String? lineupId,
    String? matchId,
    String? teamId,
    String? formationType,
    List<PlayerPositionSlot>? startingXI,
    List<String>? substituteIds,
    String? captainId,
    String? viceCaptainId,
    String? teamTalkNotes,
    DateTime? createdAt,
  }) {
    return LineupModel(
      id: id ?? this.id,
      lineupId: lineupId ?? this.lineupId,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      formationType: formationType ?? this.formationType,
      startingXI: startingXI ?? this.startingXI,
      substituteIds: substituteIds ?? this.substituteIds,
      captainId: captainId ?? this.captainId,
      viceCaptainId: viceCaptainId ?? this.viceCaptainId,
      teamTalkNotes: teamTalkNotes ?? this.teamTalkNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}