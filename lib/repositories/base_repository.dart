import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../environment.dart';
import '../services/appwrite_service.dart';

/// Abstract base repository providing generic CRUD operations
/// for Appwrite database tables using the TablesDB API.
abstract class BaseRepository<T> {
  final AppwriteService _appwriteService;
  final String _tableId;

  BaseRepository(this._appwriteService, this._tableId);

  String get databaseId => Environment.appwriteDatabaseId;
  String get tableId => _tableId;
  TablesDB get _tablesDB => _appwriteService.tablesDB;

  /// Convert Appwrite row JSON to domain model.
  T fromJson(Map<String, dynamic> json);

  /// Convert domain model to Appwrite row JSON.
  Map<String, dynamic> toJson(T item);

  /// Get a row by its ID.
  Future<T?> getById(String rowId) async {
    try {
      final row = await _tablesDB.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
      );
      return fromJson(row.data);
    } on AppwriteException catch (e) {
      debugPrint('[$tableId] getById failed: ${e.message} (${e.code})');
      return null;
    }
  }

  /// List all rows with optional queries.
  Future<List<T>> getAll({List<String>? queries}) async {
    try {
      final result = await _tablesDB.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: queries ?? [],
      );
      return result.rows.map((row) => fromJson(row.data)).toList();
    } on AppwriteException catch (e) {
      debugPrint('[$tableId] getAll failed: ${e.message} (${e.code})');
      return [];
    }
  }

  /// Create a new row with optional permissions.
  /// Throws [AppwriteException] on failure so callers can surface the error.
  Future<T> create(String rowId, Map<String, dynamic> data, {List<String>? permissions}) async {
    try {
      final row = await _tablesDB.createRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
        data: data,
        permissions: permissions,
      );
      return fromJson(row.data);
    } on AppwriteException catch (e) {
      debugPrint('[$tableId] create failed: ${e.message} (${e.code})');
      rethrow;
    }
  }

  /// Update an existing row.
  /// Throws [AppwriteException] on failure so callers can surface the error.
  Future<T> update(String rowId, Map<String, dynamic> data) async {
    try {
      final row = await _tablesDB.updateRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
        data: data,
      );
      return fromJson(row.data);
    } on AppwriteException catch (e) {
      debugPrint('[$tableId] update failed: ${e.message} (${e.code})');
      rethrow;
    }
  }

  /// Delete a row by ID.
  Future<bool> delete(String rowId) async {
    try {
      await _tablesDB.deleteRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
      );
      return true;
    } on AppwriteException catch (e) {
      debugPrint('[$tableId] delete failed: ${e.message} (${e.code})');
      return false;
    }
  }

  /// List rows filtered by a field value.
  Future<List<T>> getByField(String field, dynamic value) async {
    return getAll(queries: [
      Query.equal(field, [value]),
    ]);
  }

  /// List rows ordered by a field.
  Future<List<T>> getOrdered(String field, {bool descending = false}) async {
    return getAll(queries: [
      descending
          ? Query.orderDesc(field)
          : Query.orderAsc(field),
    ]);
  }

  /// List rows with a limit.
  Future<List<T>> getLimited(int limit, {List<String>? extraQueries}) async {
    final queries = [...?extraQueries, Query.limit(limit)];
    return getAll(queries: queries);
  }
}