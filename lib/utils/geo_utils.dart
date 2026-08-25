/// Geofencing utilities — point-in-polygon + barangay boundary helpers
/// Used exclusively by barangay_submit_request_screen.dart
/// No external packages — pure Dart math only.

import 'package:latlong2/latlong.dart';
import 'dart:math';

/// Haversine distance in meters between two lat/lng points.
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return r * 2 * asin(sqrt(a));
}

// ─── Point in Polygon ─────────────────────────────────────────
/// Returns true if [lat, lng] is inside the given polygon.
/// Polygon is a List of {lat, lng} maps from Firestore.
/// Uses ray casting algorithm — O(n), pure Dart.
bool isPointInPolygon(double lat, double lng, List<dynamic> polygon) {
  int intersections = 0;
  final n = polygon.length;

  for (int i = 0; i < n; i++) {
    final p1 = polygon[i];
    final p2 = polygon[(i + 1) % n];

    final double y1 = (p1['lat'] as num).toDouble();
    final double y2 = (p2['lat'] as num).toDouble();
    final double x1 = (p1['lng'] as num).toDouble();
    final double x2 = (p2['lng'] as num).toDouble();

    if ((y1 > lat) != (y2 > lat)) {
      final double xIntersect = (lat - y1) * (x2 - x1) / (y2 - y1) + x1;
      if (lng < xIntersect) intersections++;
    }
  }
  return intersections % 2 == 1;
}

// ─── Resolve Barangay Name From a GPS Point ───────────────────
/// Checks [lat, lng] against every seeded barangay polygon and returns
/// the matching barangay_name. Returns '' if the point falls outside
/// all seeded boundaries (e.g. rider is outside Guiuan).
String getBarangayForPoint(
  double lat,
  double lng,
  List<Map<String, dynamic>> barangays,
) {
  for (final b in barangays) {
    final polygon = b['boundary_polygon'] as List<dynamic>? ?? [];
    if (polygon.isEmpty) continue;
    if (isPointInPolygon(lat, lng, polygon)) {
      return b['barangay_name'] as String? ?? '';
    }
  }
  return '';
}

// ─── Convert Firestore Polygon → LatLng List ──────────────────
/// Converts Firestore [{lat, lng}] array to flutter_map LatLng list
/// Used to draw the boundary polygon on the map
List<LatLng> firestorePolygonToLatLng(List<dynamic> polygon) {
  return polygon.map((point) {
    final lat = (point['lat'] as num).toDouble();
    final lng = (point['lng'] as num).toDouble();
    return LatLng(lat, lng);
  }).toList();
}
