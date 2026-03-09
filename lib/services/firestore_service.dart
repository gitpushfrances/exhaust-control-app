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

  Future<String?> addRestrictedArea(RestrictedArea area) async {
    try {
      final ref = await _db.collection('restricted_areas').add(area.toMap());
      return ref.id;
    } catch (e) {
      print('Error adding restricted area: $e');
      return null;
    }
  }

  Future<bool> deleteRestrictedArea(String docId) async {
    try {
      await _db.collection('restricted_areas').doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting restricted area: $e');
      return false;
    }
  }

  // ─── Admin Stats ──────────────────────────────────────────────

  Stream<int> streamPendingRequestsCount() {
    return _db
        .collection('restricted_areas')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> streamApprovedAreasCount() {
    return _db
        .collection('restricted_areas')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> streamOfficialsCount() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'barangay_official')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> streamRidersCount() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<Map<String, dynamic>>> streamRecentActivity() {
    return _db
        .collection('restricted_areas')
        .where('status', whereIn: ['approved', 'rejected'])
        .orderBy('approved_at', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {...d.data(), 'doc_id': d.id}).toList(),
        );
  }

  // ─── Admin: Request Management ────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamPendingRequests() {
    return _db
        .collection('restricted_areas')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {...d.data(), 'doc_id': d.id}).toList(),
        );
  }

  Future<bool> approveRequest({
    required String docId,
    required String adminUid,
  }) async {
    try {
      await _db.collection('restricted_areas').doc(docId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by_uid': adminUid,
      });
      return true;
    } catch (e) {
      print('Error approving request: $e');
      return false;
    }
  }

  Future<bool> rejectRequest({
    required String docId,
    required String adminUid,
    required String reason,
  }) async {
    try {
      await _db.collection('restricted_areas').doc(docId).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by_uid': adminUid,
      });
      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }
}
