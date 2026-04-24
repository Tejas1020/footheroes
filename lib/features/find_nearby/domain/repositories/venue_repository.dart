import '../entities/venue.dart';

/// Repository for venue CRUD and search.
abstract class VenueRepository {
  Future<Venue?> getById(String id);
  Future<List<Venue>> searchByName(String query);
  Future<Venue> create(Venue venue);
}
