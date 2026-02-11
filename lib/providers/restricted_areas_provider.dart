import 'package:flutter/material.dart';
import '../models/restricted_area.dart';
import '../services/firestore_service.dart';

/// Restricted Areas Provider - Manages state for restricted areas
class RestrictedAreasProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<RestrictedArea> _areas = [];
  bool _isLoading = false;
  String? _userEmail;

  List<RestrictedArea> get areas => _areas;
  bool get isLoading => _isLoading;

  /// Initialize with user email
  void initialize(String userEmail) {
    _userEmail = userEmail;
    loadRestrictedAreas();
  }

  /// Load all restricted areas from Firestore
  Future<void> loadRestrictedAreas() async {
    if (_userEmail == null) return;

    _isLoading = true;
    notifyListeners();

    _areas = await _firestoreService.getRestrictedAreas(_userEmail!);

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new restricted area
  Future<bool> addRestrictedArea(RestrictedArea area) async {
    final id = await _firestoreService.addRestrictedArea(area);
    if (id != null) {
      await loadRestrictedAreas(); // Reload to get updated list
      return true;
    }
    return false;
  }

  /// Delete a restricted area
  Future<bool> deleteRestrictedArea(String areaId) async {
    if (_userEmail == null) return false;

    final success = await _firestoreService.deleteRestrictedArea(
      areaId,
      _userEmail!,
    );
    if (success) {
      _areas.removeWhere((area) => area.id == areaId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Check if a point is in any restricted area
  bool isPointInRestrictedArea(double lat, double lng) {
    for (var area in _areas) {
      if (area.containsPoint(lat, lng)) {
        return true;
      }
    }
    return false;
  }

  /// Get the restricted area containing a point (if any)
  RestrictedArea? getRestrictedAreaAtPoint(double lat, double lng) {
    for (var area in _areas) {
      if (area.containsPoint(lat, lng)) {
        return area;
      }
    }
    return null;
  }

  /// Clear all areas (on logout)
  void clear() {
    _areas = [];
    _userEmail = null;
    notifyListeners();
  }
}
