import 'package:appwrite/appwrite.dart';
import '../../../../environment.dart';
import '../../../../services/appwrite_service.dart';
import '../../domain/entities/venue.dart';
import '../../domain/repositories/venue_repository.dart';
import '../models/venue_model.dart';

class VenueRepositoryImpl implements VenueRepository {
  final AppwriteService _service;
  TablesDB get _db => _service.tablesDB;
  String get _databaseId => Environment.appwriteDatabaseId;
  String get _tableId => Environment.venuesCollectionId;

  VenueRepositoryImpl(this._service);

  @override
  Future<Venue?> getById(String id) async {
    try {
      final row = await _db.getRow(
        databaseId: _databaseId,
        tableId: _tableId,
        rowId: id,
      );
      return VenueModel.fromJson(row.data).toEntity();
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<List<Venue>> searchByName(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final result = await _db.listRows(
        databaseId: _databaseId,
        tableId: _tableId,
        queries: [
          Query.startsWith('name', query.trim()),
          Query.limit(20),
        ],
      );
      return result.rows
          .map((r) => VenueModel.fromJson(r.data).toEntity())
          .toList();
    } on AppwriteException {
      return [];
    }
  }

  @override
  Future<Venue> create(Venue venue) async {
    final data = <String, dynamic>{
      'name': venue.name,
      'address': venue.address,
      'latitude': venue.latitude,
      'longitude': venue.longitude,
      'geohash': venue.geohash,
      'createdBy': venue.createdBy,
      'createdAt': venue.createdAt.toIso8601String(),
    };
    final created = await _db.createRow(
      databaseId: _databaseId,
      tableId: _tableId,
      rowId: venue.id,
      data: data,
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(venue.createdBy)),
      ],
    );
    return VenueModel.fromJson(created.data).toEntity();
  }
}
