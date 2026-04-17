import 'dart:convert';

/// Match model matching the Appwrite matches collection.
class MatchModel {
  final String id;
  final String matchId;
  final String homeTeamId;
  final String? awayTeamId;
  final String homeTeamName;
  final String? awayTeamName;
  final String format;
  final String status;
  final int homeScore;
  final int awayScore;
  final List<String>? events;
  final Map<String, dynamic>? stats;
  final DateTime matchDate;
  final String createdBy;
  final DateTime? matchEndTime;
  final bool motmVotingClosed;
  final String? venue;

  const MatchModel({
    required this.id,
    required this.matchId,
    required this.homeTeamId,
    this.awayTeamId,
    this.homeTeamName = '',
    this.awayTeamName,
    required this.format,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    this.events,
    this.stats,
    required this.matchDate,
    required this.createdBy,
    this.matchEndTime,
    this.motmVotingClosed = false,
    this.venue,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['\$id'] ?? '',
      matchId: json['matchId'] ?? '',
      homeTeamId: json['homeTeamId'] ?? '',
      awayTeamId: json['awayTeamId'],
      homeTeamName: json['homeTeamName'] ?? '',
      awayTeamName: json['awayTeamName'],
      format: json['format'] ?? '',
      status: json['status'] ?? 'upcoming',
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      events: json['events'] != null
          ? List<String>.from(json['events'])
          : null,
      stats: json['stats'] != null
          ? jsonDecode(json['stats']) as Map<String, dynamic>
          : null,
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'])
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      matchEndTime: json['matchEndTime'] != null
          ? DateTime.parse(json['matchEndTime'])
          : null,
      motmVotingClosed: json['motmVotingClosed'] ?? false,
      venue: json['venue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'homeTeamId': homeTeamId,
      'format': format,
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'matchDate': matchDate.toIso8601String(),
      'createdBy': createdBy,
      'motmVotingClosed': motmVotingClosed,
      if (awayTeamId != null) 'awayTeamId': awayTeamId,
      if (homeTeamName.isNotEmpty) 'homeTeamName': homeTeamName,
      if (awayTeamName != null && awayTeamName!.isNotEmpty) 'awayTeamName': awayTeamName,
      if (events != null) 'events': events,
      if (stats != null) 'stats': jsonEncode(stats),
      if (matchEndTime != null) 'matchEndTime': matchEndTime!.toIso8601String(),
      if (venue != null && venue!.isNotEmpty) 'venue': venue,
    };
  }

  MatchModel copyWith({
    String? id,
    String? matchId,
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    String? format,
    String? status,
    int? homeScore,
    int? awayScore,
    List<String>? events,
    Map<String, dynamic>? stats,
    DateTime? matchDate,
    String? createdBy,
    DateTime? matchEndTime,
    bool? motmVotingClosed,
    String? venue,
  }) {
    return MatchModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      format: format ?? this.format,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      events: events ?? this.events,
      stats: stats ?? this.stats,
      matchDate: matchDate ?? this.matchDate,
      createdBy: createdBy ?? this.createdBy,
      matchEndTime: matchEndTime ?? this.matchEndTime,
      motmVotingClosed: motmVotingClosed ?? this.motmVotingClosed,
      venue: venue ?? this.venue,
    );
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
}