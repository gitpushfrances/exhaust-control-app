class RestrictedArea {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String createdBy;
  final DateTime createdAt;

  RestrictedArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdBy,
    required this.createdAt,
  });

  /// Check if a point (lat, lng) is inside this restricted area
  bool containsPoint(double lat, double lng) {
    // Calculate distance using Haversine formula (simplified)
    const double earthRadius = 6371000; // meters

    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);

    final double a =
        (dLat / 2).sin() * (dLat / 2).sin() +
        latitude.toRadians().cos() *
            lat.toRadians().cos() *
            (dLng / 2).sin() *
            (dLng / 2).sin();

    final double c = 2 * a.sqrt().asin();
    final double distance = earthRadius * c;

    return distance <= radius;
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from Firestore Map
  factory RestrictedArea.fromMap(Map<String, dynamic> map) {
    return RestrictedArea(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      radius: (map['radius'] ?? 100).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Helper method to convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  @override
  String toString() {
    return 'RestrictedArea(name: $name, lat: $latitude, lng: $longitude, radius: ${radius}m)';
  }
}

/// Extension for easier radian conversion
extension DoubleExtension on double {
  double toRadians() => this * 3.141592653589793 / 180;
  double sin() => this._sin();
  double cos() => this._cos();
  double asin() => this._asin();
  double sqrt() => this._sqrt();

  // Using dart:math functions
  double _sin() {
    double x = this;
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _cos() {
    double x = this;
    double result = 1;
    double term = 1;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _asin() {
    return 2 * (this / (1 + (1 - this * this).sqrt())).atan();
  }

  double _sqrt() {
    if (this < 0) return double.nan;
    double x = this;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double atan() {
    double x = this;
    double result = x;
    double term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x * (2 * i - 1) / (2 * i + 1);
      result += term;
    }
    return result;
  }
}
