import 'package:appwrite/appwrite.dart';
import '../models/team_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class TeamRepository extends BaseRepository<TeamModel> {
  TeamRepository(AppwriteService service)
      : super(service, 'teams');

  @override
  TeamModel fromJson(Map<String, dynamic> json) => TeamModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(TeamModel item) => item.toJson();

  /// Get teams where the user is a member.
  Future<List<TeamModel>> getTeamsForUser(String userId) async {
    return getAll(queries: [
      Query.contains('memberUids', [userId]),
    ]);
  }

  /// Get a team by invite code.
  Future<TeamModel?> getTeamByInviteCode(String code) async {
    final teams = await getAll(queries: [
      Query.equal('inviteCode', [code]),
    ]);
    return teams.isNotEmpty ? teams.first : null;
  }

  /// Get teams the user is captain of.
  Future<List<TeamModel>> getTeamsCaptainedBy(String userId) async {
    return getAll(queries: [
      Query.equal('captainUid', [userId]),
    ]);
  }

  /// Create a new team.
  Future<TeamModel?> createTeam(TeamModel team) async {
    return create(team.teamId, team.toJson());
  }

  /// Add a member to a team.
  Future<TeamModel?> addMember(String teamId, String userId) async {
    final team = await getById(teamId);
    if (team == null) return null;
    final updatedMembers = [...team.memberUids, userId];
    return update(teamId, {'memberUids': updatedMembers});
  }

  /// Remove a member from a team.
  Future<TeamModel?> removeMember(String teamId, String userId) async {
    final team = await getById(teamId);
    if (team == null) return null;
    final updatedMembers = team.memberUids.where((id) => id != userId).toList();
    return update(teamId, {'memberUids': updatedMembers});
  }

  /// Get teams filtered by format.
  Future<List<TeamModel>> getTeamsByFormat(String format) async {
    return getAll(queries: [
      Query.equal('format', [format]),
    ]);
  }

  /// Get teams filtered by location.
  Future<List<TeamModel>> getTeamsByLocation(String location) async {
    return getAll(queries: [
      Query.equal('location', [location]),
    ]);
  }

  /// Get team members with their details.
  /// Returns a list of maps with player info.
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final team = await getById(teamId);
    if (team == null) return [];

    // For now, return placeholder members based on memberUids
    // In production, this would join with users collection
    return team.memberUids.map((uid) => TeamMember(
      userId: uid,
      name: 'Player',
      position: '',
      isCaptain: uid == team.captainUid,
    )).toList();
  }

  /// Get payment status for team members.
  Future<Map<String, bool>> getPaymentStatus(String teamId) async {
    // This would query a payments table
    // For now, return empty map
    return {};
  }

  /// Update payment status for a player.
  Future<bool> updatePaymentStatus(String teamId, String playerId, bool paid) async {
    // This would update a payments table
    return true;
  }

  /// Update member position.
  Future<bool> updateMemberPosition(String playerId, String position) async {
    // This would update the user's position in users collection
    return true;
  }
}

/// Simple team member model for squad display.
class TeamMember {
  final String userId;
  final String name;
  final String position;
  final bool isCaptain;

  const TeamMember({
    required this.userId,
    required this.name,
    required this.position,
    this.isCaptain = false,
  });
}