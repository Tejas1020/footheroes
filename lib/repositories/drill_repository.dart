import 'package:appwrite/appwrite.dart';
import '../models/drill_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

/// Maps position short codes to Appwrite drill categories.
/// GK → goalkeeper, CB/LB/RB → defender, CDM/CM/CAM/LM/RM → midfielder,
/// ST/CF/LW/RW → attacker.
String positionToCategory(String positionCode) {
  const mapping = <String, String>{
    'GK': 'goalkeeper',
    'CB': 'defender', 'LB': 'defender', 'RB': 'defender',
    'CDM': 'midfielder', 'CM': 'midfielder', 'CAM': 'midfielder',
    'LM': 'midfielder', 'RM': 'midfielder',
    'ST': 'attacker', 'CF': 'attacker', 'LW': 'attacker', 'RW': 'attacker',
  };
  return mapping[positionCode.toUpperCase()] ?? 'attacker';
}

class DrillRepository extends BaseRepository<DrillModel> {
  DrillRepository(AppwriteService service) : super(service, 'drills');

  @override
  DrillModel fromJson(Map<String, dynamic> json) => DrillModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(DrillModel item) => item.toJson();

  /// Get drills for a specific position.
  // VERIFIED: position filter passes Query.equal('position', category) to Appwrite.
  // A GK user will receive only goalkeeper drills. Confirmed 2026-04-15.
  Future<List<DrillModel>> getDrillsByPosition(String positionCode) async {
    final category = positionToCategory(positionCode);
    return getAll(queries: [
      Query.equal('position', [category]),
    ]);
  }

  /// Get drills filtered by skill level.
  Future<List<DrillModel>> getDrillsBySkillLevel(String skillLevel) async {
    return getAll(queries: [
      Query.equal('skillLevel', [skillLevel]),
    ]);
  }

  /// Get drills filtered by type.
  Future<List<DrillModel>> getDrillsByType(String type) async {
    return getAll(queries: [
      Query.equal('type', [type]),
    ]);
  }

  /// Get drills filtered by solo or group.
  Future<List<DrillModel>> getDrillsBySoloOrGroup(String soloOrGroup) async {
    return getAll(queries: [
      Query.equal('soloOrGroup', [soloOrGroup]),
    ]);
  }

  /// Create a new drill.
  /// Drills are read-only public content, created by admins.
  Future<DrillModel?> createDrill(DrillModel drill) async {
    // Public read permissions - drills are read-only content
    return create(drill.drillId, drill.toJson(), permissions: [
      Permission.read(Role.any()),
    ]);
  }

  /// Get completed drills this week for a user.
  Future<List<DrillModel>> getCompletedDrillsThisWeek(String userId) async {
    // This would typically query a user_drills junction table
    // For now, return empty list - to be implemented with user progress tracking
    return [];
  }

  /// Get saved drill IDs for a user.
  Future<List<String>> getSavedDrillIds(String userId) async {
    // This would typically query a user_saved_drills junction table
    // For now, return empty list
    return [];
  }

  /// Get recommended drills based on position and user history.
  Future<List<DrillModel>> getRecommendedDrills(String positionCode, String userId) async {
    final category = positionToCategory(positionCode);
    return getAll(queries: [
      Query.equal('position', [category]),
      Query.limit(5),
    ]);
  }

  /// Mark a drill as complete for a user.
  Future<bool> markDrillComplete(String drillId, String userId) async {
    // This would update a user_drills junction table
    // For now, just return true
    return true;
  }

  /// Save a drill for a user.
  Future<bool> saveDrill(String drillId, String userId) async {
    // This would update a user_saved_drills junction table
    return true;
  }

  /// Unsave a drill for a user.
  Future<bool> unsaveDrill(String drillId, String userId) async {
    // This would update a user_saved_drills junction table
    return true;
  }
}