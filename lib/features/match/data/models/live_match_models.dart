/// In-memory player info used during a live match session.
class LivePlayerInfo {
  final String id;
  final String name;
  final String position;
  final String? email;
  final bool isRegistered;
  final String team; // 'home' or 'away'

  const LivePlayerInfo({
    required this.id,
    required this.name,
    required this.position,
    this.email,
    this.isRegistered = false,
    this.team = 'home',
  });

  LivePlayerInfo copyWith({
    String? id,
    String? name,
    String? position,
    String? email,
    bool? isRegistered,
    String? team,
  }) {
    return LivePlayerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      email: email ?? this.email,
      isRegistered: isRegistered ?? this.isRegistered,
      team: team ?? this.team,
    );
  }
}