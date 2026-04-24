import 'package:flutter_test/flutter_test.dart';
import 'package:footheroes/features/find_nearby/data/models/discovery_block_model.dart';
import 'package:footheroes/features/find_nearby/data/models/join_request_model.dart';
import 'package:footheroes/features/find_nearby/data/models/nearby_match_model.dart';
import 'package:footheroes/features/find_nearby/data/models/venue_model.dart';
import 'package:footheroes/features/find_nearby/domain/entities/join_request.dart';

void main() {
  group('VenueModel', () {
    test('serializes and deserializes', () {
      final model = VenueModel(
        id: 'v1',
        name: 'Wembley',
        address: 'London',
        latitude: 51.5,
        longitude: -0.1,
        geohash: 'gcpvj0',
        createdBy: 'user1',
        createdAt: DateTime.parse('2026-04-24T12:00:00Z'),
      );

      final json = model.toJson();
      final decoded = VenueModel.fromJson(json);

      expect(decoded.name, 'Wembley');
      expect(decoded.latitude, 51.5);
    });

    test('maps to entity', () {
      final model = VenueModel(
        id: 'v1',
        name: 'Wembley',
        latitude: 51.5,
        longitude: -0.1,
        geohash: 'gcpvj0',
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      final entity = model.toEntity();
      expect(entity.name, 'Wembley');
      expect(entity.id, 'v1');
    });
  });

  group('NearbyMatchModel', () {
    test('serializes and deserializes', () {
      final model = NearbyMatchModel(
        id: 'm1',
        format: '5-a-side',
        startTime: DateTime.parse('2026-04-24T15:00:00Z'),
        openToNearby: true,
        slotsNeeded: 10,
        slotsRemaining: 5,
        requiredPositions: 'ANY',
        createdBy: 'user1',
      );

      final json = model.toJson();
      final decoded = NearbyMatchModel.fromJson(json);

      expect(decoded.format, '5-a-side');
      expect(decoded.slotsRemaining, 5);
    });
  });

  group('JoinRequestModel', () {
    test('maps status string to enum', () {
      final model = JoinRequestModel(
        id: 'r1',
        matchId: 'm1',
        requesterUid: 'u1',
        requesterPosition: 'GK',
        status: 'approved',
        assignedSide: 'home',
        createdAt: DateTime.now(),
      );

      final entity = model.toEntity();
      expect(entity.status, JoinRequestStatus.approved);
      expect(entity.assignedSide, AssignedSide.home);
    });

    test('defaults to pending for unknown status', () {
      final model = JoinRequestModel(
        id: 'r1',
        matchId: 'm1',
        requesterUid: 'u1',
        requesterPosition: 'GK',
        status: 'unknown',
        createdAt: DateTime.now(),
      );

      final entity = model.toEntity();
      expect(entity.status, JoinRequestStatus.pending);
    });
  });

  group('DiscoveryBlockModel', () {
    test('maps to entity', () {
      final model = DiscoveryBlockModel(
        id: 'b1',
        creatorUid: 'u1',
        playerUid: 'u2',
        createdAt: DateTime.now(),
      );

      final entity = model.toEntity();
      expect(entity.creatorUid, 'u1');
      expect(entity.playerUid, 'u2');
    });
  });
}
