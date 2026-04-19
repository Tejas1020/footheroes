import 'package:appwrite/appwrite.dart';
import '../environment.dart';
import '../models/formation_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class FormationRepository extends BaseRepository<FormationModel> {
  FormationRepository(AppwriteService service)
      : super(service, Environment.formationsCollectionId);

  @override
  FormationModel fromJson(Map<String, dynamic> json) => FormationModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(FormationModel item) => item.toJson();

  /// Save a new formation.
  Future<FormationModel?> saveFormation(FormationModel formation) async {
    return create(formation.formationId, formation.toJson());
  }

  /// Update an existing formation.
  Future<FormationModel?> updateFormation(FormationModel formation) async {
    return update(formation.id, formation.toJson());
  }

  /// Get all formations for a team.
  Future<List<FormationModel>> getTeamFormations(String teamId) async {
    return getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.orderDesc('createdAt'),
    ]);
  }

  /// Get the default formation for a team.
  Future<FormationModel?> getDefaultFormation(String teamId) async {
    final formations = await getAll(queries: [
      Query.equal('teamId', [teamId]),
      Query.equal('isDefault', [true]),
      Query.limit(1),
    ]);
    return formations.isNotEmpty ? formations.first : null;
  }

  /// Set a formation as the default for a team.
  Future<bool> setDefaultFormation(String teamId, String formationId) async {
    // First, unset any existing default
    final currentDefault = await getDefaultFormation(teamId);
    if (currentDefault != null && currentDefault.id != formationId) {
      await update(currentDefault.id, {'isDefault': false});
    }

    // Set the new default
    await update(formationId, {'isDefault': true});
    return true;
  }

  /// Delete a formation.
  Future<bool> deleteFormation(String formationId) async {
    return delete(formationId);
  }

  /// Get a formation by its formationId (not the document $id).
  Future<FormationModel?> getByFormationId(String formationId) async {
    final formations = await getAll(queries: [
      Query.equal('formationId', [formationId]),
      Query.limit(1),
    ]);
    return formations.isNotEmpty ? formations.first : null;
  }

  /// Create formation from template.
  Future<FormationModel?> createFromTemplate({
    required String teamId,
    required String name,
    required String formationType,
    String? notes,
  }) async {
    final slots = FormationTemplates.getSlotsForFormation(formationType);
    final formationId = 'form_${teamId}_${DateTime.now().millisecondsSinceEpoch}';

    final formation = FormationModel(
      id: formationId,
      formationId: formationId,
      teamId: teamId,
      name: name,
      formationType: formationType,
      slots: slots,
      notes: notes,
      createdAt: DateTime.now(),
      isDefault: false,
    );

    return saveFormation(formation);
  }

  /// Duplicate an existing formation.
  Future<FormationModel?> duplicateFormation(FormationModel original, String newName) async {
    final newFormationId = 'form_${original.teamId}_${DateTime.now().millisecondsSinceEpoch}';

    final duplicate = original.copyWith(
      id: newFormationId,
      formationId: newFormationId,
      name: newName,
      createdAt: DateTime.now(),
      isDefault: false,
    );

    return saveFormation(duplicate);
  }
}