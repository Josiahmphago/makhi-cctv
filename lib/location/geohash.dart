// lib/location/geohash.dart
// Minimal, null-safe Geohash encoder/decoder + neighbors.
// Good enough for proximity indexing & Firestore range queries.

class GeoHash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const _bits = [16, 8, 4, 2, 1];

  /// Encode lat/lng to geohash string with [precision] (1..12 typical; 6–8 is common).
  static String encode(
    double latitude,
    double longitude, {
    int precision = 7,
  }) {
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;

    var hash = StringBuffer();
    int bit = 0, ch = 0;
    bool even = true;

    while (hash.length < precision) {
      if (even) {
        final mid = (lonMin + lonMax) / 2.0;
        if (longitude >= mid) {
          ch |= _bits[bit];
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2.0;
        if (latitude >= mid) {
          ch |= _bits[bit];
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        hash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return hash.toString();
  }

  /// Decode geohash to approximate center lat/lng.
  static ({double lat, double lng}) decode(String hash) {
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    bool even = true;

    for (final c in hash.split('')) {
      final cd = _base32.indexOf(c);
      if (cd == -1) throw ArgumentError('Invalid geohash char: $c');
      for (var mask in _bits) {
        if (even) {
          final mid = (lonMin + lonMax) / 2.0;
          if ((cd & mask) != 0) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2.0;
          if ((cd & mask) != 0) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        even = !even;
      }
    }
    return (lat: (latMin + latMax) / 2.0, lng: (lonMin + lonMax) / 2.0);
  }

  /// Adjacent geohash in a cardinal direction.
  static String adjacent(String hash, String direction) {
    final neighbor = {
      'n': [
        'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
        'bc01fg45238967deuvhjyznpkmstqrwx'
      ],
      's': [
        '14365h7k9dcfesgujnmqp0r2twvyx8zb',
        '238967debc01fg45kmstqrwxuvhjyznp'
      ],
      'e': [
        'bc01fg45238967deuvhjyznpkmstqrwx',
        'p0r21436x8zb9dcf5h7kjnmqesgutwvy'
      ],
      'w': [
        '238967debc01fg45kmstqrwxuvhjyznp',
        '14365h7k9dcfesgujnmqp0r2twvyx8zb'
      ],
    };
    final border = {
      'n': ['prxz',     'bcfguvyz' ],
      's': ['028b',     '0145hjnp' ],
      'e': ['bcfguvyz', 'prxz'     ],
      'w': ['0145hjnp', '028b'     ],
    };

    final last = hash[hash.length - 1];
    var parent = hash.substring(0, hash.length - 1);
    final type = hash.length.isOdd ? 1 : 0;

    if (border[direction]![type].contains(last) && parent.isNotEmpty) {
      parent = adjacent(parent, direction);
    }

    final nIndex = neighbor[direction]![type].indexOf(last);
    return parent + _base32[nIndex];
  }

  /// Cardinal + diagonal neighbors (8).
  static List<String> neighbors(String hash) {
    final n = adjacent(hash, 'n');
    final s = adjacent(hash, 's');
    final e = adjacent(hash, 'e');
    final w = adjacent(hash, 'w');
    return [
      n,
      s,
      e,
      w,
      adjacent(n, 'e'),
      adjacent(n, 'w'),
      adjacent(s, 'e'),
      adjacent(s, 'w'),
    ];
  }
}
