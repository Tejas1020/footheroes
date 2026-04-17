import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/formation_model.dart';
import '../repositories/formation_repository.dart';
import 'auth_provider.dart';

final formationRepositoryProvider = Provider<FormationRepository>((ref) {
  return FormationRepository(ref.watch(appwriteServiceProvider));
});

// Formation state
enum FormationStatus { initial, loading, loaded, error }

class FormationState {
  final FormationStatus status;
  final List<FormationModel> formations;
  final FormationModel? currentFormation;
  final FormationModel? defaultFormation;
  final String? error;

  const FormationState({
    this.status = FormationStatus.initial,
    this.formations = const [],
    this.currentFormation,
    this.defaultFormation,
    this.error,
  });

  FormationState copyWith({
    FormationStatus? status,
    List<FormationModel>? formations,
    FormationModel? currentFormation,
    FormationModel? defaultFormation,
    String? error,
  }) {
    return FormationState(
      status: status ?? this.status,
      formations: formations ?? this.formations,
      currentFormation: currentFormation ?? this.currentFormation,
      defaultFormation: defaultFormation ?? this.defaultFormation,
      error: error,
    );
  }
}

// Formation notifier
class FormationNotifier extends StateNotifier<FormationState> {
  final FormationRepository _formationRepo;

  FormationNotifier(this._formationRepo) : super(const FormationState());

  Future<void> loadTeamFormations(String teamId) async {
    state = state.copyWith(status: FormationStatus.loading);
    try {
      final formations = await _formationRepo.getTeamFormations(teamId);
      final defaultFormation = formations.where((f) => f.isDefault).firstOrNull;
      state = state.copyWith(
        status: FormationStatus.loaded,
        formations: formations,
        currentFormation: defaultFormation ?? formations.firstOrNull,
        defaultFormation: defaultFormation,
      );
    } catch (e) {
      state = state.copyWith(status: FormationStatus.error, error: e.toString());
    }
  }

  Future<void> selectFormation(String formationId) async {
    final formation = state.formations.where((f) => f.id == formationId).firstOrNull;
    if (formation != null) {
      state = state.copyWith(currentFormation: formation);
    }
  }

  Future<bool> saveFormation(FormationModel formation) async {
    try {
      final saved = await _formationRepo.saveFormation(formation);
      if (saved != null) {
        await loadTeamFormations(formation.teamId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateFormation(FormationModel formation) async {
    try {
      final updated = await _formationRepo.updateFormation(formation);
      if (updated != null) {
        await loadTeamFormations(formation.teamId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createFromTemplate({
    required String teamId,
    required String name,
    required String formationType,
    String? notes,
  }) async {
    try {
      final formation = await _formationRepo.createFromTemplate(
        teamId: teamId,
        name: name,
        formationType: formationType,
        notes: notes,
      );
      if (formation != null) {
        await loadTeamFormations(teamId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> setDefault(String teamId, String formationId) async {
    try {
      final success = await _formationRepo.setDefaultFormation(teamId, formationId);
      if (success) {
        await loadTeamFormations(teamId);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> duplicateFormation(FormationModel original, String newName) async {
    try {
      final duplicate = await _formationRepo.duplicateFormation(original, newName);
      if (duplicate != null) {
        await loadTeamFormations(original.teamId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteFormation(String formationId, String teamId) async {
    try {
      final success = await _formationRepo.deleteFormation(formationId);
      if (success) {
        await loadTeamFormations(teamId);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Formation provider
final formationProvider = StateNotifierProvider<FormationNotifier, FormationState>((ref) {
  return FormationNotifier(ref.watch(formationRepositoryProvider));
});

// Derived providers
final defaultFormationProvider = Provider<FormationModel?>((ref) {
  return ref.watch(formationProvider).defaultFormation;
});

final currentFormationProvider = Provider<FormationModel?>((ref) {
  return ref.watch(formationProvider).currentFormation;
});

final supportedFormationsProvider = Provider<List<String>>((ref) {
  return FormationTemplates.supportedFormations;
});