import 'package:appwrite/appwrite.dart';
import '../../../../environment.dart';
import '../../../../services/appwrite_service.dart';
import '../../domain/entities/discovery_block.dart';
import '../../domain/repositories/discovery_block_repository.dart';
import '../models/discovery_block_model.dart';

class DiscoveryBlockRepositoryImpl implements DiscoveryBlockRepository {
  final AppwriteService _service;
  TablesDB get _db => _service.tablesDB;
  String get _databaseId => Environment.appwriteDatabaseId;
  String get _tableId => Environment.discoveryBlocksCollectionId;

  DiscoveryBlockRepositoryImpl(this._service);

  @override
  Future<bool> isBlocked(String creatorUid, String playerUid) async {
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.equal('creatorUid', creatorUid),
          Query.equal('playerUid', playerUid),
          Query.limit(1),
        ],
      );
      return result.rows.isNotEmpty;
    } on AppwriteException {
      return false;
    }
  }

  @override
  Future<DiscoveryBlock> block(String creatorUid, String playerUid) async {
    final data = <String, dynamic>{
      'creatorUid': creatorUid,
      'playerUid': playerUid,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final created = await _db.createRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: ID.unique(),
      data: data,
    );
    return DiscoveryBlockModel.fromJson(created.data).toEntity();
  }
}
