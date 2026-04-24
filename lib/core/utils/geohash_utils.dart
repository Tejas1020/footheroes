import 'dart:math';

/// Utility functions for geohash encoding and geographic distance calculations.
/// Uses the dart_geohash package internally.
class GeohashUtils {
  GeohashUtils._();

  /// Encode latitude/longitude into a geohash string with given precision.
  static String encode(double latitude, double longitude, int precision) {
    // dart_geohash encode takes (longitude, latitude)
    return _encode(longitude, latitude, precision);
  }

  /// Get all unique geohash prefixes that cover a search radius.
  ///
  /// Returns the center prefix and its 8 neighbors at the given precision.
  static Set<String> getNeighborPrefixes(String geohash) {
    final neighbors = _neighbors(geohash);
    return {geohash, ...neighbors.values};
  }

  /// Calculate Haversine distance between two lat/lng points in kilometers.
  static double haversineDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  // ---------------------------------------------------------------------------
  // Inline geohash implementation to avoid depending on the exact package API
  // ---------------------------------------------------------------------------

  static const String _baseSequence = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String _encode(double longitude, double latitude, int precision) {
    var originalPrecision = precision;
    if (longitude < -180.0 || longitude > 180.0) {
      throw RangeError.range(longitude, -180, 180, 'Longitude');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw RangeError.range(latitude, -90, 90, 'Latitude');
    }

    if (precision % 2 == 1) {
      precision = precision + 1;
    }
    if (precision != 1) {
      precision ~/= 2;
    }

    final longitudeBits = _doubleToBits(
      value: longitude,
      lower: -180.0,
      upper: 180.0,
      length: precision * 5,
    );
    final latitudeBits = _doubleToBits(
      value: latitude,
      lower: -90.0,
      upper: 90.0,
      length: precision * 5,
    );

    final ret = <int>[];
    for (var i = 0; i < longitudeBits.length; i++) {
      ret.add(longitudeBits[i]);
      ret.add(latitudeBits[i]);
    }
    final geohashString = _bitsToGeoHash(ret);

    if (originalPrecision == 1) {
      return geohashString.substring(0, 1);
    }
    if (originalPrecision % 2 == 1) {
      return geohashString.substring(0, geohashString.length - 1);
    }
    return geohashString;
  }

  static List<int> _doubleToBits({
    required double value,
    double lower = -90.0,
    double middle = 0.0,
    double upper = 90.0,
    int length = 15,
  }) {
    final ret = <int>[];
    for (var i = 0; i < length; i++) {
      if (value >= middle) {
        lower = middle;
        ret.add(1);
      } else {
        upper = middle;
        ret.add(0);
      }
      middle = (upper + lower) / 2;
    }
    return ret;
  }

  static String _bitsToGeoHash(List<int> bitValue) {
    final geoHashList = <String>[];
    var remainingBits = List<int>.from(bitValue);
    var subBits = <int>[];
    String subBitsAsString;
    for (var i = 0, n = bitValue.length / 5; i < n; i++) {
      subBits = remainingBits.sublist(0, 5);
      remainingBits = remainingBits.sublist(5);
      subBitsAsString = '';
      for (final value in subBits) {
        subBitsAsString += value.toString();
      }
      final value =
          int.parse(int.parse(subBitsAsString, radix: 2).toRadixString(10));
      geoHashList.add(_baseSequence[value]);
    }
    return geoHashList.join('');
  }

  static Map<String, String> _neighbors(String geohash) {
    _ensureValid(geohash);
    final adjacentN = _adjacent(geohash: geohash, direction: _Direction.north);
    final adjacentS = _adjacent(geohash: geohash, direction: _Direction.south);
    return {
      'NORTH': adjacentN,
      'NORTHEAST': _adjacent(geohash: adjacentN, direction: _Direction.east),
      'EAST': _adjacent(geohash: geohash, direction: _Direction.east),
      'SOUTHEAST': _adjacent(geohash: adjacentS, direction: _Direction.east),
      'SOUTH': adjacentS,
      'SOUTHWEST': _adjacent(geohash: adjacentS, direction: _Direction.west),
      'WEST': _adjacent(geohash: geohash, direction: _Direction.west),
      'NORTHWEST': _adjacent(geohash: adjacentN, direction: _Direction.west),
    };
  }

  static void _ensureValid(String geohash) {
    if (geohash.isEmpty) {
      throw ArgumentError.value(geohash, 'geohash', 'GeoHash is empty');
    }
    if (!RegExp('^[$_baseSequence]+\$').hasMatch(geohash)) {
      throw ArgumentError.value(
        geohash,
        'geohash',
        'Invalid character in GeoHash',
      );
    }
  }

  static final _neighbor = <_Direction, List<String>>{
    _Direction.north: [
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'bc01fg45238967deuvhjyznpkmstqrwx',
    ],
    _Direction.south: [
      '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      '238967debc01fg45kmstqrwxuvhjyznp',
    ],
    _Direction.east: [
      'bc01fg45238967deuvhjyznpkmstqrwx',
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
    ],
    _Direction.west: [
      '238967debc01fg45kmstqrwxuvhjyznp',
      '14365h7k9dcfesgujnmqp0r2twvyx8zb',
    ],
  };

  static final _border = <_Direction, List<String>>{
    _Direction.north: ['prxz', 'bcfguvyz'],
    _Direction.south: ['028b', '0145hjnp'],
    _Direction.east: ['bcfguvyz', 'prxz'],
    _Direction.west: ['0145hjnp', '028b'],
  };

  static String _adjacent({
    required String geohash,
    required _Direction direction,
  }) {
    if (geohash == '') {
      throw ArgumentError.value(geohash, 'geohash');
    }

    final last = geohash[geohash.length - 1];
    final t = geohash.length % 2;

    var parent = geohash.substring(0, geohash.length - 1);
    if (_border[direction]![t].contains(last) && parent != '') {
      parent = _adjacent(geohash: parent, direction: direction);
    }

    return parent +
        _baseSequence[_neighbor[direction]![t].indexOf(last)];
  }
}

enum _Direction { north, south, east, west }
