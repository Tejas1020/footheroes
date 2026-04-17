/// Session plan model for team training sessions.
class SessionPlanModel {
  final String id;
  final String sessionId;
  final String teamId;
  final String title;
  final DateTime sessionDate;
  final int durationMinutes;
  final List<String> warmUpDrillIds;
  final List<String> mainDrillIds;
  final List<String> coolDownDrillIds;
  final String? notes;
  final List<String> attendeeIds;
  final DateTime createdAt;

  const SessionPlanModel({
    required this.id,
    required this.sessionId,
    required this.teamId,
    required this.title,
    required this.sessionDate,
    required this.durationMinutes,
    this.warmUpDrillIds = const [],
    this.mainDrillIds = const [],
    this.coolDownDrillIds = const [],
    this.notes,
    this.attendeeIds = const [],
    required this.createdAt,
  });

  /// Total estimated duration from all drills.
  int get totalEstimatedMinutes {
    // Rough estimate: 15 min per warmup, 20 min per main, 10 min per cooldown
    return warmUpDrillIds.length * 15 + mainDrillIds.length * 20 + coolDownDrillIds.length * 10;
  }

  /// Total drill count.
  int get totalDrills => warmUpDrillIds.length + mainDrillIds.length + coolDownDrillIds.length;

  factory SessionPlanModel.fromJson(Map<String, dynamic> json) {
    return SessionPlanModel(
      id: json['\$id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      teamId: json['teamId'] ?? '',
      title: json['title'] ?? 'Training Session',
      sessionDate: json['sessionDate'] != null
          ? DateTime.parse(json['sessionDate'])
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 60,
      warmUpDrillIds: (json['warmUpDrillIds'] as List?)?.map((s) => s.toString()).toList() ?? [],
      mainDrillIds: (json['mainDrillIds'] as List?)?.map((s) => s.toString()).toList() ?? [],
      coolDownDrillIds: (json['coolDownDrillIds'] as List?)?.map((s) => s.toString()).toList() ?? [],
      notes: json['notes'],
      attendeeIds: (json['attendeeIds'] as List?)?.map((s) => s.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'teamId': teamId,
      'title': title,
      'sessionDate': sessionDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'warmUpDrillIds': warmUpDrillIds,
      'mainDrillIds': mainDrillIds,
      'coolDownDrillIds': coolDownDrillIds,
      'notes': notes,
      'attendeeIds': attendeeIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SessionPlanModel copyWith({
    String? id,
    String? sessionId,
    String? teamId,
    String? title,
    DateTime? sessionDate,
    int? durationMinutes,
    List<String>? warmUpDrillIds,
    List<String>? mainDrillIds,
    List<String>? coolDownDrillIds,
    String? notes,
    List<String>? attendeeIds,
    DateTime? createdAt,
  }) {
    return SessionPlanModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      warmUpDrillIds: warmUpDrillIds ?? this.warmUpDrillIds,
      mainDrillIds: mainDrillIds ?? this.mainDrillIds,
      coolDownDrillIds: coolDownDrillIds ?? this.coolDownDrillIds,
      notes: notes ?? this.notes,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}