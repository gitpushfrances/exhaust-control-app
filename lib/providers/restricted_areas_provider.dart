import 'package:flutter/material.dart';
import '../models/restricted_area.dart';
import '../services/firestore_service.dart';

class RestrictedAreasProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<RestrictedArea> _areas = [];
  bool _isLoading = false;

  List<RestrictedArea> get areas => _areas;
  bool get isLoading => _isLoading;

  /// Call once after login — starts real-time stream of approved areas
  void initialize() {
    _firestoreService.streamApprovedAreas().listen((areas) {
      _areas = areas;
      notifyListeners();
    });
  }

  /// Check if a point is inside any restricted area
  bool isPointInRestrictedArea(double lat, double lng) {
    return _areas.any((area) => area.containsPoint(lat, lng));
  }

  /// Get the restricted area at a point (if any)
  RestrictedArea? getRestrictedAreaAtPoint(double lat, double lng) {
    try {
      return _areas.firstWhere((area) => area.containsPoint(lat, lng));
    } catch (_) {
      return null;
    }
  }

  /// Add area (used by rider for now, will be scoped per role later)
  Future<bool> addRestrictedArea(RestrictedArea area) async {
    return await _firestoreService.addRestrictedArea(area) != null;
  }

  /// Delete area by Firestore doc ID
  Future<bool> deleteRestrictedArea(String docId) async {
    return await _firestoreService.deleteRestrictedArea(docId);
  }

  void clear() {
    _areas = [];
    notifyListeners();
  }
}
