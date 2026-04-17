import 'package:appwrite/appwrite.dart';
import '../environment.dart';
import '../models/lineup_model.dart';
import '../models/formation_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class LineupRepository extends BaseRepository<LineupModel> {
  LineupRepository(AppwriteService service)
      : super(service, Environment.lineupsCollectionId);

  @override
  LineupModel fromJson(Map<String, dynamic> json) => LineupModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(LineupModel item) => item.toJson();

  /// Save a new lineup.
  Future<LineupModel?> saveLineup(LineupModel lineup) async {
    return create(lineup.lineupId, lineup.toJson());
  }

  /// Update an existing lineup.
  Future<LineupModel?> updateLineup(LineupModel lineup) async {
    return update(lineup.id, lineup.toJson());
  }

  /// Get the lineup for a specific match.
  Future<LineupModel?> getLineup(String matchId, String teamId) async {
    final lineups = await getAll(queries: [
      Query.equal('matchId', [matchId]),
      Query.equal('teamId', [teamId]),
      Query.limit(1),
    ]);
    return lineups.isNotEmpty ? lineups.first : null;
  }

  /// Get all lineups for a team.
  Future<List<LineupModel>> getTeamLineups(String teamId) async {
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.orderDesc('createdAt'),
    ]);
  }

  /// Get lineups for a specific match (both teams).
  Future<List<LineupModel>> getMatchLineups(String matchId) async {
    return getAll(queries: [
      Query.equal('matchId', [matchId]),
    ]);
  }

  /// Create a new lineup from a formation.
  Future<LineupModel?> createFromFormation({
    required String matchId,
    required String teamId,
    required FormationModel formation,
  }) async {
    final lineupId = 'lineup_${matchId}_$teamId';

    final lineup = LineupModel(
      id: lineupId,
      lineupId: lineupId,
      matchId: matchId,
      teamId: teamId,
      formationType: formation.formationType,
      startingXI: formation.slots, // Copy slots from formation
      substituteIds: [],
      captainId: null,
      viceCaptainId: null,
      teamTalkNotes: null,
      createdAt: DateTime.now(),
    );

    return saveLineup(lineup);
  }

  /// Assign a player to a position slot.
  Future<LineupModel?> assignPlayerToSlot(
    String lineupId,
    String slotId,
    String playerId,
    String playerName,
  ) async {
    final lineup = await getById(lineupId);
    if (lineup == null) return null;

    final updatedSlots = lineup.startingXI.map((slot) {
      if (slot.slotId == slotId) {
        return slot.copyWith(
          assignedPlayerId: playerId,
          assignedPlayerName: playerName,
        );
      }
      return slot;
    }).toList();

    return update(lineupId, {
      'startingXI': updatedSlots.map((s) => s.toJson()).toList(),
    });
  }

  /// Remove a player from a position slot.
  Future<LineupModel?> removePlayerFromSlot(String lineupId, String slotId) async {
    final lineup = await getById(lineupId);
    if (lineup == null) return null;

    final updatedSlots = lineup.startingXI.map((slot) {
      if (slot.slotId == slotId) {
        return slot.copyWith(
          assignedPlayerId: null,
          assignedPlayerName: null,
        );
      }
      return slot;
    }).toList();

    return update(lineupId, {
      'startingXI': updatedSlots.map((s) => s.toJson()).toList(),
    });
  }

  /// Set captain for the lineup.
  Future<LineupModel?> setCaptain(String lineupId, String playerId) async {
    return update(lineupId, {'captainId': playerId});
  }

  /// Set vice captain for the lineup.
  Future<LineupModel?> setViceCaptain(String lineupId, String playerId) async {
    return update(lineupId, {'viceCaptainId': playerId});
  }

  /// Add a substitute.
  Future<LineupModel?> addSubstitute(String lineupId, String playerId) async {
    final lineup = await getById(lineupId);
    if (lineup == null) return null;

    if (lineup.substituteIds.contains(playerId)) return lineup;

    final updatedSubs = [...lineup.substituteIds, playerId];
    return update(lineupId, {'substituteIds': updatedSubs});
  }

  /// Remove a substitute.
  Future<LineupModel?> removeSubstitute(String lineupId, String playerId) async {
    final lineup = await getById(lineupId);
    if (lineup == null) return null;

    final updatedSubs = lineup.substituteIds.where((id) => id != playerId).toList();
    return update(lineupId, {'substituteIds': updatedSubs});
  }

  /// Update team talk notes.
  Future<LineupModel?> updateTeamTalk(String lineupId, String notes) async {
    return update(lineupId, {'teamTalkNotes': notes});
  }

  /// Change formation type (updates slot positions).
  Future<LineupModel?> changeFormation(String lineupId, String formationType) async {
    final lineup = await getById(lineupId);
    if (lineup == null) return null;

    // Get new slots from template, preserving assignments where possible
    final newSlots = FormationTemplates.getSlotsForFormation(formationType);

    // Try to preserve player assignments for common positions
    final playerAssignments = <String, (String, String)?>{};
    for (final slot in lineup.startingXI) {
      if (slot.isAssigned) {
        playerAssignments[slot.positionLabel] = (slot.assignedPlayerId!, slot.assignedPlayerName!);
      }
    }

    // Apply assignments to new slots
    final preservedSlots = newSlots.map((slot) {
      final assignment = playerAssignments[slot.positionLabel];
      if (assignment != null) {
        return slot.copyWith(
          assignedPlayerId: assignment.$1,
          assignedPlayerName: assignment.$2,
        );
      }
      return slot;
    }).toList();

    return update(lineupId, {
      'formationType': formationType,
      'startingXI': preservedSlots.map((s) => s.toJson()).toList(),
    });
  }

  /// Delete a lineup.
  Future<bool> deleteLineup(String lineupId) async {
    return delete(lineupId);
  }
}