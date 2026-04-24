import 'package:flutter_test/flutter_test.dart';
import 'package:footheroes/core/utils/geohash_utils.dart';

void main() {
  group('GeohashUtils.encode', () {
    test('encodes London at precision 6', () {
      final hash = GeohashUtils.encode(51.5074, -0.1278, 6);
      expect(hash, equals('gcpvj0'));
    });

    test('encodes New York at precision 6', () {
      final hash = GeohashUtils.encode(40.7128, -74.0060, 6);
      expect(hash, equals('dr5reg'));
    });

    test('throws for out-of-range latitude', () {
      expect(
        () => GeohashUtils.encode(91.0, 0.0, 6),
        throwsRangeError,
      );
    });

    test('throws for out-of-range longitude', () {
      expect(
        () => GeohashUtils.encode(0.0, 181.0, 6),
        throwsRangeError,
      );
    });
  });

  group('GeohashUtils.getNeighborPrefixes', () {
    test('returns center + 8 neighbors', () {
      final prefixes = GeohashUtils.getNeighborPrefixes('gcpvj0');
      expect(prefixes.length, equals(9));
      expect(prefixes, contains('gcpvj0'));
    });

    test('all neighbors have same length as input', () {
      final prefixes = GeohashUtils.getNeighborPrefixes('gcpvj0');
      for (final p in prefixes) {
        expect(p.length, equals(6));
      }
    });
  });

  group('GeohashUtils.haversineDistanceKm', () {
    test('distance from London to Paris is ~344 km', () {
      final distance = GeohashUtils.haversineDistanceKm(
        51.5074, -0.1278, // London
        48.8566, 2.3522, // Paris
      );
      expect(distance, closeTo(344, 1));
    });

    test('same point returns zero', () {
      final distance = GeohashUtils.haversineDistanceKm(
        51.5074, -0.1278,
        51.5074, -0.1278,
      );
      expect(distance, equals(0));
    });

    test('distance from New York to Los Angeles is ~3940 km', () {
      final distance = GeohashUtils.haversineDistanceKm(
        40.7128, -74.0060, // New York
        34.0522, -118.2437, // Los Angeles
      );
      expect(distance, closeTo(3940, 10));
    });
  });
}
