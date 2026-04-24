import 'package:appwrite/appwrite.dart';
import '../../../../environment.dart';
import '../../../../services/appwrite_service.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/repositories/nearby_match_repository.dart';
import '../models/nearby_match_model.dart';

class NearbyMatchRepositoryImpl implements NearbyMatchRepository {
  final AppwriteService _service;
  TablesDB get _db => _service.tablesDB;
  String get _databaseId => Environment.appwriteDatabaseId;
  String get _tableId => Environment.matchesCollectionId;

  NearbyMatchRepositoryImpl(this._service);

  @override
  Future<List<NearbyMatch>> findByGeohashPrefixes(
    List<String> prefixes, {
    NearbyMatchFilters? filters,
  }) async {
    if (prefixes.isEmpty) return [];
    try {
      final queries = <String>[
        Query.equal('geohashPrefix', prefixes),
        Query.equal('openToNearby', true),
        Query.greaterThan('startTime', DateTime.now().toIso8601String()),
        Query.greaterThan('slotsRemaining', 0),
        Query.orderAsc('startTime'),
      ];

      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: queries,
      );
      return result.rows
          .map((r) => NearbyMatchModel.fromJson(r.data).toEntity())
          .toList();
    } on AppwriteException {
      return [];
    }
  }

  @override
  Future<NearbyMatch?> getById(String id) async {
    try {
      final row = await _db.getRow(
        databaseId: _databaseId,
        tableId: _tableId,
        rowId: id,
      );
      return NearbyMatchModel.fromJson(row.data).toEntity();
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<NearbyMatch> update(String id, Map<String, dynamic> data) async {
    final updated = await _db.updateRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: id,
      data: data,
    );
    return NearbyMatchModel.fromJson(updated.data).toEntity();
  }
}
