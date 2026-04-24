import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drill_model.dart';
import '../repositories/drill_repository.dart';
import 'auth_provider.dart';

final drillRepositoryProvider = Provider<DrillRepository>((ref) {
  return DrillRepository(ref.watch(appwriteServiceProvider));
});

// Drill state
enum DrillStatus { initial, loading, loaded, error }

class DrillState {
  final DrillStatus status;
  final List<DrillModel> drills;
  final List<DrillModel> filteredDrills;
  final String? activeCategory;
  final String? activeType;
  final String? error;

  const DrillState({
    this.status = DrillStatus.initial,
    this.drills = const [],
    this.filteredDrills = const [],
    this.activeCategory,
    this.activeType,
    this.error,
  });

  bool get isLoading => status == DrillStatus.loading;

  DrillState copyWith({
    DrillStatus? status,
    List<DrillModel>? drills,
    List<DrillModel>? filteredDrills,
    String? activeCategory,
    String? activeType,
    String? error,
  }) {
    return DrillState(
      status: status ?? this.status,
      drills: drills ?? this.drills,
      filteredDrills: filteredDrills ?? this.filteredDrills,
      activeCategory: activeCategory ?? this.activeCategory,
      activeType: activeType ?? this.activeType,
      error: error,
    );
  }
}

// Drill notifier
class DrillNotifier extends StateNotifier<DrillState> {
  final DrillRepository _drillRepo;

  DrillNotifier(this._drillRepo) : super(const DrillState());

  Future<void> loadDrills(String position) async {
    state = state.copyWith(status: DrillStatus.loading);
    try {
      final drills = await _drillRepo.getDrillsByPosition(position);
      state = state.copyWith(
        status: DrillStatus.loaded,
        drills: drills,
        filteredDrills: drills,
      );
    } catch (e) {
      state = state.copyWith(status: DrillStatus.error, error: e.toString());
    }
  }

  Future<void> loadAllDrills() async {
    state = state.copyWith(status: DrillStatus.loading);
    try {
      final drills = await _drillRepo.getAll();
      state = state.copyWith(
        status: DrillStatus.loaded,
        drills: drills,
        filteredDrills: drills,
      );
    } catch (e) {
      state = state.copyWith(status: DrillStatus.error, error: e.toString());
    }
  }

  void filterByCategory(String? category) {
    final filtered = category == null || category == 'All'
        ? state.drills
        : state.drills.where((d) => d.type == category).toList();
    state = state.copyWith(
      activeCategory: category,
      filteredDrills: filtered,
    );
  }

  void filterByType(String? type) {
    final filtered = type == null
        ? state.drills
        : state.filteredDrills.where((d) => d.soloOrGroup == type).toList();
    state = state.copyWith(
      activeType: type,
      filteredDrills: filtered,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      filteredDrills: state.drills,
      activeCategory: null,
      activeType: null,
    );
  }
}

// Drill provider
final drillProvider = StateNotifierProvider<DrillNotifier, DrillState>((ref) {
  return DrillNotifier(ref.watch(drillRepositoryProvider));
});