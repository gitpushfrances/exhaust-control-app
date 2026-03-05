import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restricted_area.dart';

/// Firestore Service - Handles all database operations for restricted areas
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'restricted_areas';

  /// Add a new restricted area
  Future<String?> addRestrictedArea(RestrictedArea area) async {
    try {
      final docRef = await _firestore.collection(_collection).add(area.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding restricted area: $e');
      return null;
    }
  }

  /// Get all restricted areas for a user
  Future<List<RestrictedArea>> getRestrictedAreas(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: userEmail)
          .get();

      return snapshot.docs
          .map((doc) => RestrictedArea.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching restricted areas: $e');
      return [];
    }
  }

  /// Delete a restricted area
  Future<bool> deleteRestrictedArea(String areaId, String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: areaId)
          .where('createdBy', isEqualTo: userEmail)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      print('Error deleting restricted area: $e');
      return false;
    }
  }

  /// Update a restricted area
  Future<bool> updateRestrictedArea(RestrictedArea area) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: area.id)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update(area.toMap());
      }
      return true;
    } catch (e) {
      print('Error updating restricted area: $e');
      return false;
    }
  }

  /// Stream of restricted areas (real-time updates)
  Stream<List<RestrictedArea>> streamRestrictedAreas(String userEmail) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: userEmail)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RestrictedArea.fromMap(doc.data()))
              .toList(),
        );
  }
}
