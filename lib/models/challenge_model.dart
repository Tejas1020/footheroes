/// Challenge model matching the Appwrite challenges collection.
class ChallengeModel {
  final String id;
  final String challengeId;
  final int weekNumber;
  final String position;
  final String description;
  final List<String>? completedBy;
  final DateTime expiresAt;

  const ChallengeModel({
    required this.id,
    required this.challengeId,
    required this.weekNumber,
    required this.position,
    required this.description,
    this.completedBy,
    required this.expiresAt,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['\$id'] ?? '',
      challengeId: json['challengeId'] ?? '',
      weekNumber: json['weekNumber'] ?? 0,
      position: json['position'] ?? '',
      description: json['description'] ?? '',
      completedBy: json['completedBy'] != null
          ? List<String>.from(json['completedBy'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'weekNumber': weekNumber,
      'position': position,
      'description': description,
      'completedBy': completedBy,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? challengeId,
    int? weekNumber,
    String? position,
    String? description,
    List<String>? completedBy,
    DateTime? expiresAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      weekNumber: weekNumber ?? this.weekNumber,
      position: position ?? this.position,
      description: description ?? this.description,
      completedBy: completedBy ?? this.completedBy,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isCompletedBy(String userId) {
    return completedBy?.contains(userId) ?? false;
  }
}