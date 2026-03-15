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

  // ─── Admin: Officials Management ─────────────────────────────

  Stream<List<AppUser>> streamOfficials() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'barangay_official')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<bool> createOfficialAccount({
    required String name,
    required String email,
    required String barangayId,
    required String barangayName,
    required String createdByUid,
  }) async {
    try {
      final newUser = AppUser(
        uid: email,
        name: name,
        email: email,
        role: 'barangay_official',
        barangayId: barangayId,
        barangayName: barangayName,
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: createdByUid,
      );
      await _db.collection('users').add(newUser.toMap());
      return true;
    } catch (e) {
      print('Error creating official: $e');
      return false;
    }
  }

  Future<bool> setOfficialActiveStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({'is_active': isActive});
      return true;
    } catch (e) {
      print('Error updating official status: $e');
      return false;
    }
  }

  // ─── Notifications ────────────────────────────────────────────

  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    String areaId = '',
  }) async {
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'area_id': areaId,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {...d.data(), 'doc_id': d.id}).toList(),
        );
  }

  Stream<int> streamUnreadNotificationCount(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({'is_read': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  // ─── Barangay Official ────────────────────────────────────────

  Future<bool> submitZoneRequest({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String barangayId,
    required String barangayName,
    required String submittedByUid,
    required String submittedByName, // ← added
    String remarks = '',
  }) async {
    try {
      await _db.collection('restricted_areas').add({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'status': 'pending',
        'barangay_id': barangayId,
        'barangay_name': barangayName,
        'submitted_by_uid': submittedByUid,
        'submitted_by_name': submittedByName, // ← added
        'remarks': remarks,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': submittedByUid,
      });
      return true;
    } catch (e) {
      print('Error submitting request: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> streamMyRequests(String uid) {
    return _db
        .collection('restricted_areas')
        .where('submitted_by_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {...d.data(), 'doc_id': d.id}).toList(),
        );
  }

  Stream<Map<String, int>> streamMyRequestStats(String uid) {
    return streamMyRequests(uid).map(
      (list) => {
        'total': list.length,
        'pending': list.where((a) => a['status'] == 'pending').length,
        'approved': list.where((a) => a['status'] == 'approved').length,
        'rejected': list.where((a) => a['status'] == 'rejected').length,
      },
    );
  }

  // ─── Admin: All Areas (Global Map) ───────────────────────────

  Stream<List<Map<String, dynamic>>> streamAllAreas() {
    return _db
        .collection('restricted_areas')
        .orderBy('created_at', descending: true)
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
      final doc = await _db.collection('restricted_areas').doc(docId).get();
      final data = doc.data() ?? {};
      await _db.collection('restricted_areas').doc(docId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by_uid': adminUid,
      });
      final submittedBy = data['submitted_by_uid'] ?? '';
      final name = data['name'] ?? 'Zone';
      if (submittedBy.isNotEmpty) {
        await createNotification(
          uid: submittedBy,
          title: 'Zone Approved ✅',
          body: '"$name" has been approved and is now active.',
          type: 'approved',
          areaId: docId,
        );
      }
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
      final doc = await _db.collection('restricted_areas').doc(docId).get();
      final data = doc.data() ?? {};
      await _db.collection('restricted_areas').doc(docId).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by_uid': adminUid,
      });
      final submittedBy = data['submitted_by_uid'] ?? '';
      final name = data['name'] ?? 'Zone';
      if (submittedBy.isNotEmpty) {
        await createNotification(
          uid: submittedBy,
          title: 'Zone Rejected ❌',
          body: '"$name" was rejected. Reason: $reason',
          type: 'rejected',
          areaId: docId,
        );
      }
      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }
}
