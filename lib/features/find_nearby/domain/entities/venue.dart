/// Venue entity used for match location pinning.
class Venue {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String geohash;
  final String createdBy;
  final DateTime createdAt;

  const Venue({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.createdBy,
    required this.createdAt,
  });
}
