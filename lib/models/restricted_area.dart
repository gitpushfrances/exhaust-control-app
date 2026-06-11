import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class RestrictedArea {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String createdBy;
  final DateTime createdAt;

  // Phase 7 fields
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? barangayId;
  final String? submittedByUid;
  final String? remarks;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedByUid;

  RestrictedArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdBy,
    required this.createdAt,
    this.status = 'approved',
    this.barangayId,
    this.submittedByUid,
    this.remarks,
    this.rejectionReason,
    this.approvedAt,
    this.approvedByUid,
  });

  bool containsPoint(double lat, double lng) {
    const double earthRadius = 6371000;
    final double dLat = (lat - latitude) * math.pi / 180;
    final double dLng = (lng - longitude) * math.pi / 180;
    final double a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(latitude * math.pi / 180) *
            math.cos(lat * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    final double c = 2 * math.asin(math.sqrt(a));
    final double distance = earthRadius * c;
    debugPrint(
      '📏 distance to $name: ${distance.toStringAsFixed(1)}m (radius: ${radius}m)',
    );
    return distance <= radius;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'barangay_id': barangayId,
      'submitted_by_uid': submittedByUid,
      'remarks': remarks,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by_uid': approvedByUid,
    };
  }

  factory RestrictedArea.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val.runtimeType.toString().contains('Timestamp')) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val.runtimeType.toString().contains('Timestamp')) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RestrictedArea(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      radius: (map['radius'] ?? 100).toDouble(),
      createdBy: map['created_by'] ?? map['createdBy'] ?? '',
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      status: map['status'] ?? 'approved',
      barangayId: map['barangay_id'],
      submittedByUid: map['submitted_by_uid'],
      remarks: map['remarks'],
      rejectionReason: map['rejection_reason'],
      approvedAt: parseDateNullable(map['approved_at']),
      approvedByUid: map['approved_by_uid'],
    );
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;

  @override
  String toString() =>
      'RestrictedArea(name: $name, lat: $latitude, lng: $longitude, radius: ${radius}m, status: $status)';
}

extension DoubleExtension on double {
  double toRadians() => this * 3.141592653589793 / 180;
  double sin() => _sin();
  double cos() => _cos();
  double asin() => _asin();
  double sqrt() => _sqrt();

  double _sin() {
    double x = this, result = x, term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _cos() {
    double x = this, result = 1, term = 1;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _asin() => 2 * (this / (1 + (1 - this * this).sqrt())).atan();

  double _sqrt() {
    if (this < 0) return double.nan;
    double x = this, guess = x / 2;
    for (int i = 0; i < 10; i++) guess = (guess + x / guess) / 2;
    return guess;
  }

  double atan() {
    double x = this, result = x, term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x * (2 * i - 1) / (2 * i + 1);
      result += term;
    }
    return result;
  }
}
