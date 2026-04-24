import 'package:appwrite/appwrite.dart';
import '../../../../environment.dart';
import '../../../../services/appwrite_service.dart';
import '../../domain/entities/join_request.dart';
import '../../domain/repositories/join_request_repository.dart';
import '../models/join_request_model.dart';

class JoinRequestRepositoryImpl implements JoinRequestRepository {
  final AppwriteService _service;
  TablesDB get _db => _service.tablesDB;
  String get _databaseId => Environment.appwriteDatabaseId;
  String get _tableId => Environment.joinRequestsCollectionId;

  JoinRequestRepositoryImpl(this._service);

  @override
  Future<JoinRequest> create({
    required String matchId,
    required String requesterUid,
    required String requesterPosition,
    String? requesterMessage,
  }) async {
    final data = <String, dynamic>{
      'matchId': matchId,
      'requesterUid': requesterUid,
      'requesterPosition': requesterPosition,
      'requesterMessage': requesterMessage,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final created = await _db.createRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: ID.unique(),
      data: data,
    );
    return JoinRequestModel.fromJson(created.data).toEntity();
  }

  @override
  Future<JoinRequest?> getById(String id) async {
    try {
      final row = await _db.getRow(
        databaseId: _databaseId,
        tableId: _tableId,
        rowId: id,
      );
      return JoinRequestModel.fromJson(row.data).toEntity();
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<List<JoinRequest>> getPendingForMatch(String matchId) async {
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.equal('matchId', matchId),
          Query.equal('status', 'pending'),
          Query.orderAsc('createdAt'),
        ],
      );
      return result.rows
          .map((r) => JoinRequestModel.fromJson(r.data).toEntity())
          .toList();
    } on AppwriteException {
      return [];
    }
  }

  @override
  Future<List<JoinRequest>> getByRequester(String requesterUid) async {
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.equal('requesterUid', requesterUid),
          Query.orderDesc('createdAt'),
        ],
      );
      return result.rows
          .map((r) => JoinRequestModel.fromJson(r.data).toEntity())
          .toList();
    } on AppwriteException {
      return [];
    }
  }

  @override
  Future<JoinRequest> approve(String id, String side) async {
    final updated = await _db.updateRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: id,
      data: {
        'status': 'approved',
        'assignedSide': side,
        'respondedAt': DateTime.now().toIso8601String(),
      },
    );
    return JoinRequestModel.fromJson(updated.data).toEntity();
  }

  @override
  Future<JoinRequest> decline(String id) async {
    final updated = await _db.updateRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: id,
      data: {
        'status': 'declined',
        'respondedAt': DateTime.now().toIso8601String(),
      },
    );
    return JoinRequestModel.fromJson(updated.data).toEntity();
  }

  @override
  Future<JoinRequest> cancel(String id) async {
    final updated = await _db.updateRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: id,
      data: {
        'status': 'cancelled',
        'respondedAt': DateTime.now().toIso8601String(),
      },
    );
    return JoinRequestModel.fromJson(updated.data).toEntity();
  }

  @override
  Future<int> expireStaleRequests(DateTime cutoff) async {
    // Appwrite does not support bulk updates natively via TablesDB.
    // Fetch and update individually.
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.equal('status', 'pending'),
          Query.lessThan('createdAt', cutoff.toIso8601String()),
        ],
      );
      var count = 0;
      for (final row in result.rows) {
        await _db.updateRow(
          databaseId: _databaseId,
          tableId: _tableId,
          rowId: row.$id,
          data: {'status': 'expired'},
        );
        count++;
      }
      return count;
    } on AppwriteException {
      return 0;
    }
  }

  @override
  Future<JoinRequest?> promoteWaitlisted(String matchId) async {
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.equal('matchId', matchId),
          Query.equal('status', 'waitlisted'),
          Query.orderAsc('createdAt'),
          Query.limit(1),
        ],
      );
      if (result.rows.isEmpty) return null;
      final row = result.rows.first;
      final updated = await _db.updateRow(
        databaseId: _databaseId,
        tableId: _tableId,
        rowId: row.$id,
        data: {'status': 'pending'},
      );
      return JoinRequestModel.fromJson(updated.data).toEntity();
    } on AppwriteException {
      return null;
    }
  }
}
