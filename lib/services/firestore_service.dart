import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restricted_area.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Docs ────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data()!);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> createUserDoc(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // ─── Restricted Areas ─────────────────────────────────────────

  /// Riders: stream only approved areas
  Stream<List<RestrictedArea>> streamApprovedAreas() {
    return _db
        .collection('restricted_areas')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RestrictedArea.fromMap(d.data())).toList(),
        );
  }

  /// Add a new restricted area, returns the doc ID
  Future<String?> addRestrictedArea(RestrictedArea area) async {
    try {
      final ref = await _db.collection('restricted_areas').add(area.toMap());
      return ref.id;
    } catch (e) {
      print('Error adding restricted area: $e');
      return null;
    }
  }

  /// Delete a restricted area by doc ID
  Future<bool> deleteRestrictedArea(String docId) async {
    try {
      await _db.collection('restricted_areas').doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting restricted area: $e');
      return false;
    }
  }
}
