import 'dart:convert';

/// Team model matching the Appwrite teams collection.
class TeamModel {
  final String id;
  final String teamId;
  final String name;
  final String captainUid;
  final List<String> memberUids;
  final String format;
  final String? location;
  final Map<String, dynamic>? stats;
  final String inviteCode;

  const TeamModel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.captainUid,
    required this.memberUids,
    required this.format,
    this.location,
    this.stats,
    required this.inviteCode,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['\$id'] ?? '',
      teamId: json['teamId'] ?? '',
      name: json['name'] ?? '',
      captainUid: json['captainUid'] ?? '',
      memberUids: json['memberUids'] != null
          ? List<String>.from(json['memberUids'])
          : [],
      format: json['format'] ?? '',
      location: json['location'],
      stats: json['stats'] != null
          ? jsonDecode(json['stats']) as Map<String, dynamic>
          : null,
      inviteCode: json['inviteCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'name': name,
      'captainUid': captainUid,
      'memberUids': memberUids,
      'format': format,
      'location': location,
      'stats': stats != null ? jsonEncode(stats) : null,
      'inviteCode': inviteCode,
    };
  }

  TeamModel copyWith({
    String? id,
    String? teamId,
    String? name,
    String? captainUid,
    List<String>? memberUids,
    String? format,
    String? location,
    Map<String, dynamic>? stats,
    String? inviteCode,
  }) {
    return TeamModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      captainUid: captainUid ?? this.captainUid,
      memberUids: memberUids ?? this.memberUids,
      format: format ?? this.format,
      location: location ?? this.location,
      stats: stats ?? this.stats,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}