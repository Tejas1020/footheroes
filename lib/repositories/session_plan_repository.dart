import 'package:appwrite/appwrite.dart';
import '../environment.dart';
import '../models/session_plan_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class SessionPlanRepository extends BaseRepository<SessionPlanModel> {
  SessionPlanRepository(AppwriteService service)
      : super(service, Environment.sessionPlansCollectionId);

  @override
  SessionPlanModel fromJson(Map<String, dynamic> json) => SessionPlanModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(SessionPlanModel item) => item.toJson();

  /// Save a new session plan.
  Future<SessionPlanModel?> saveSessionPlan(SessionPlanModel plan) async {
    return create(plan.sessionId, plan.toJson());
  }

  /// Update an existing session plan.
  Future<SessionPlanModel?> updateSessionPlan(SessionPlanModel plan) async {
    return update(plan.id, plan.toJson());
  }

  /// Get all session plans for a team.
  Future<List<SessionPlanModel>> getTeamSessions(String teamId) async {
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.orderDesc('sessionDate'),
    ]);
  }

  /// Get upcoming sessions for a team.
  Future<List<SessionPlanModel>> getUpcomingSessions(String teamId) async {
    final now = DateTime.now().toIso8601String();
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.greaterThan('sessionDate', now),
      Query.orderAsc('sessionDate'),
    ]);
  }

  /// Get past sessions for a team.
  Future<List<SessionPlanModel>> getPastSessions(String teamId) async {
    final now = DateTime.now().toIso8601String();
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.lessThan('sessionDate', now),
      Query.orderDesc('sessionDate'),
    ]);
  }

  /// Get a session plan by ID.
  Future<SessionPlanModel?> getSession(String sessionId) async {
    return getById(sessionId);
  }

  /// Update attendance for a session.
  Future<SessionPlanModel?> updateAttendance(
    String sessionId,
    List<String> attendeeIds,
  ) async {
    return update(sessionId, {'attendeeIds': attendeeIds});
  }

  /// Add an attendee to a session.
  Future<SessionPlanModel?> addAttendee(String sessionId, String playerId) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    if (plan.attendeeIds.contains(playerId)) return plan;

    final updatedAttendees = [...plan.attendeeIds, playerId];
    return update(sessionId, {'attendeeIds': updatedAttendees});
  }

  /// Remove an attendee from a session.
  Future<SessionPlanModel?> removeAttendee(String sessionId, String playerId) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    final updatedAttendees = plan.attendeeIds.where((id) => id != playerId).toList();
    return update(sessionId, {'attendeeIds': updatedAttendees});
  }

  /// Delete a session plan.
  Future<bool> deleteSession(String sessionId) async {
    return delete(sessionId);
  }

  /// Get sessions within a date range.
  Future<List<SessionPlanModel>> getSessionsInRange(
    String teamId,
    DateTime start,
    DateTime end,
  ) async {
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.greaterThanEqual('sessionDate', start.toIso8601String()),
      Query.lessThanEqual('sessionDate', end.toIso8601String()),
      Query.orderAsc('sessionDate'),
    ]);
  }

  /// Add a warm-up drill.
  Future<SessionPlanModel?> addWarmUpDrill(String sessionId, String drillId) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    if (plan.warmUpDrillIds.contains(drillId)) return plan;

    final updatedDrills = [...plan.warmUpDrillIds, drillId];
    return update(sessionId, {'warmUpDrillIds': updatedDrills});
  }

  /// Add a main drill.
  Future<SessionPlanModel?> addMainDrill(String sessionId, String drillId) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    if (plan.mainDrillIds.contains(drillId)) return plan;

    final updatedDrills = [...plan.mainDrillIds, drillId];
    return update(sessionId, {'mainDrillIds': updatedDrills});
  }

  /// Add a cool-down drill.
  Future<SessionPlanModel?> addCoolDownDrill(String sessionId, String drillId) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    if (plan.coolDownDrillIds.contains(drillId)) return plan;

    final updatedDrills = [...plan.coolDownDrillIds, drillId];
    return update(sessionId, {'coolDownDrillIds': updatedDrills});
  }

  /// Remove a drill from session.
  Future<SessionPlanModel?> removeDrill(
    String sessionId,
    String drillId,
    String section, // 'warmUp', 'main', 'coolDown'
  ) async {
    final plan = await getById(sessionId);
    if (plan == null) return null;

    switch (section) {
      case 'warmUp':
        final updated = plan.warmUpDrillIds.where((id) => id != drillId).toList();
        return update(sessionId, {'warmUpDrillIds': updated});
      case 'main':
        final updated = plan.mainDrillIds.where((id) => id != drillId).toList();
        return update(sessionId, {'mainDrillIds': updated});
      case 'coolDown':
        final updated = plan.coolDownDrillIds.where((id) => id != drillId).toList();
        return update(sessionId, {'coolDownDrillIds': updated});
      default:
        return plan;
    }
  }

  /// Update session notes.
  Future<SessionPlanModel?> updateNotes(String sessionId, String? notes) async {
    return update(sessionId, {'notes': notes});
  }

  /// Reschedule a session.
  Future<SessionPlanModel?> rescheduleSession(
    String sessionId,
    DateTime newDate,
  ) async {
    return update(sessionId, {'sessionDate': newDate.toIso8601String()});
  }
}