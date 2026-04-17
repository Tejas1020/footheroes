/// Drill model matching the Appwrite drills collection.
class DrillModel {
  final String id;
  final String drillId;
  final String position;
  final String skillLevel;
  final String type;
  final String title;
  final String description;
  final List<String>? coachingPoints;
  final int duration;
  final String? equipment;
  final String soloOrGroup;

  const DrillModel({
    required this.id,
    required this.drillId,
    required this.position,
    required this.skillLevel,
    required this.type,
    required this.title,
    required this.description,
    this.coachingPoints,
    required this.duration,
    this.equipment,
    required this.soloOrGroup,
  });

  factory DrillModel.fromJson(Map<String, dynamic> json) {
    return DrillModel(
      id: json['\$id'] ?? '',
      drillId: json['drillId'] ?? '',
      position: json['position'] ?? '',
      skillLevel: json['skillLevel'] ?? 'Beginner',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coachingPoints: json['coachingPoints'] != null
          ? List<String>.from(json['coachingPoints'])
          : null,
      duration: json['duration'] ?? 15,
      equipment: json['equipment'],
      soloOrGroup: json['soloOrGroup'] ?? 'Solo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drillId': drillId,
      'position': position,
      'skillLevel': skillLevel,
      'type': type,
      'title': title,
      'description': description,
      'coachingPoints': coachingPoints,
      'duration': duration,
      'equipment': equipment,
      'soloOrGroup': soloOrGroup,
    };
  }

  DrillModel copyWith({
    String? id,
    String? drillId,
    String? position,
    String? skillLevel,
    String? type,
    String? title,
    String? description,
    List<String>? coachingPoints,
    int? duration,
    String? equipment,
    String? soloOrGroup,
  }) {
    return DrillModel(
      id: id ?? this.id,
      drillId: drillId ?? this.drillId,
      position: position ?? this.position,
      skillLevel: skillLevel ?? this.skillLevel,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      coachingPoints: coachingPoints ?? this.coachingPoints,
      duration: duration ?? this.duration,
      equipment: equipment ?? this.equipment,
      soloOrGroup: soloOrGroup ?? this.soloOrGroup,
    );
  }

  bool get isBeginner => skillLevel == 'Beginner';
  bool get isIntermediate => skillLevel == 'Intermediate';
  bool get isAdvanced => skillLevel == 'Advanced';
  bool get isSolo => soloOrGroup == 'Solo';
  bool get isPartner => soloOrGroup == 'Partner';
  bool get isTeam => soloOrGroup == 'Team';
}