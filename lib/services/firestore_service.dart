import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/restricted_area.dart';
import '../models/app_user.dart';
import '../models/ride_session.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Docs ────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data()!);
    } catch (e) {
      debugPrint('Error fetching user: $e');
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
      debugPrint('Error adding restricted area: $e');
      return null;
    }
  }

  Future<bool> deleteRestrictedArea(String docId) async {
    try {
      await _db.collection('restricted_areas').doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting restricted area: $e');
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

  // ─── Admin: Officials Management ──────────────────────────────

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

  /// Original method — kept for backward compat
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
      debugPrint('Error creating official: $e');
      return false;
    }
  }

  /// Used by the updated create official screen.
  /// Writes user doc AND syncs official_uid back to the barangay doc.
  Future<bool> createOfficialAccountWithSync({
    required String uid,
    required String name,
    required String email,
    required String barangayId,
    required String barangayName,
    required String createdByUid,
  }) async {
    try {
      final newUser = AppUser(
        uid: uid,
        name: name,
        email: email,
        role: 'barangay_official',
        barangayId: barangayId,
        barangayName: barangayName,
        barangayIds: [barangayId],
        barangayNames: [barangayName],
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: createdByUid,
      );
      await _db.collection('users').doc(uid).set(newUser.toMap());
      await _syncBarangayOfficialUid(barangayId: barangayId, officialUid: uid);
      return true;
    } catch (e) {
      debugPrint('Error creating official with sync: $e');
      return false;
    }
  }

  Future<bool> setOfficialActiveStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({'is_active': isActive});
      return true;
    } catch (e) {
      debugPrint('Error updating official status: $e');
      return false;
    }
  }

  // ─── Barangay Assignment ──────────────────────────────────────

  Future<void> _syncBarangayOfficialUid({
    required String barangayId,
    required String? officialUid,
  }) async {
    try {
      await _db.collection('barangays').doc(barangayId).update({
        'official_uid': officialUid,
      });
    } catch (e) {
      debugPrint('Error syncing barangay official_uid: $e');
    }
  }

  Future<bool> assignBarangayToOfficial({
    required String officialUid,
    required String barangayId,
    required String barangayName,
  }) async {
    try {
      await _db.collection('users').doc(officialUid).update({
        'barangay_ids': FieldValue.arrayUnion([barangayId]),
        'barangay_names': FieldValue.arrayUnion([barangayName]),
        'barangay_id': barangayId,
        'barangay_name': barangayName,
      });
      await _syncBarangayOfficialUid(
        barangayId: barangayId,
        officialUid: officialUid,
      );
      return true;
    } catch (e) {
      debugPrint('Error assigning barangay: $e');
      return false;
    }
  }

  Future<bool> removeBarangayFromOfficial({
    required String officialUid,
    required String barangayId,
    required String barangayName,
  }) async {
    try {
      await _db.collection('users').doc(officialUid).update({
        'barangay_ids': FieldValue.arrayRemove([barangayId]),
        'barangay_names': FieldValue.arrayRemove([barangayName]),
      });
      await _syncBarangayOfficialUid(barangayId: barangayId, officialUid: null);
      return true;
    } catch (e) {
      debugPrint('Error removing barangay: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBarangaysForOfficial(
    String officialUid,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(officialUid).get();
      if (!userDoc.exists) return [];
      final data = userDoc.data()!;
      final ids =
          (data['barangay_ids'] as List?)?.map((e) => e.toString()).toList() ??
          [];
      if (ids.isEmpty) return [];
      final results = <Map<String, dynamic>>[];
      for (final id in ids) {
        final doc = await _db.collection('barangays').doc(id).get();
        if (doc.exists) {
          results.add({...doc.data()!, 'doc_id': doc.id});
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching barangays for official: $e');
      return [];
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

  /// Mark specific notifications as read by their doc IDs.
  Future<void> markNotificationsRead(List<String> docIds) async {
    if (docIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in docIds) {
      batch.update(_db.collection('notifications').doc(id), {'is_read': true});
    }
    await batch.commit();
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Batch delete multiple notifications by doc IDs.
  Future<void> deleteNotifications(List<String> docIds) async {
    if (docIds.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in docIds) {
        batch.delete(_db.collection('notifications').doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch deleting notifications: $e');
    }
  }

  /// Delete ALL notifications for a user.
  Future<void> deleteAllNotifications(String uid) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
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
    required String submittedByName,
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
        'submitted_by_name': submittedByName,
        'remarks': remarks,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': submittedByUid,
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting request: $e');
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

  // ─── Barangay Management ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBarangaysByMunicipality(
    String municipality,
  ) async {
    try {
      final snap = await _db
          .collection('barangays')
          .where('municipality_name', isEqualTo: municipality)
          .get();
      return snap.docs.map((d) => {...d.data(), 'doc_id': d.id}).toList();
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
      return [];
    }
  }

  Future<List<String>> getMunicipalities() async {
    try {
      final snap = await _db.collection('barangays').get();
      final municipalities =
          snap.docs
              .map((d) => d.data()['municipality_name'] as String? ?? '')
              .where((m) => m.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return municipalities;
    } catch (e) {
      debugPrint('Error fetching municipalities: $e');
      return [];
    }
  }

  Future<AppUser?> getOfficialByBarangayId(String barangayId) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'barangay_official')
          .where('barangay_id', isEqualTo: barangayId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return AppUser.fromMap(doc.id, doc.data());
    } catch (e) {
      debugPrint('Error fetching official by barangay: $e');
      return null;
    }
  }

  Future<bool> updateOfficialBarangay({
    required String officialUid,
    required String barangayId,
    required String barangayName,
  }) async {
    try {
      await _db.collection('users').doc(officialUid).update({
        'barangay_id': barangayId,
        'barangay_name': barangayName,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating official barangay: $e');
      return false;
    }
  }

  // ─── Ride Sessions ────────────────────────────────────────────

  /// Create a new ride session doc, returns the doc ID
  Future<String?> createRideSession(RideSession session) async {
    try {
      final ref = await _db.collection('ride_sessions').add(session.toMap());
      return ref.id;
    } catch (e) {
      debugPrint('Error creating ride session: $e');
      return null;
    }
  }

  /// Update session with final stats (avg speed, dB reduction, end time)
  Future<void> closeRideSession({
    required String sessionId,
    required double avgSpeedKph,
    required double decibelBefore,
    required double decibelAfter,
    required List<Map<String, dynamic>> snapshots,
  }) async {
    try {
      await _db.collection('ride_sessions').doc(sessionId).update({
        'ended_at': DateTime.now().toIso8601String(),
        'avg_speed_kph': avgSpeedKph,
        'decibel_before': decibelBefore,
        'decibel_after': decibelAfter,
        'decibel_reduced': (decibelBefore - decibelAfter).clamp(0.0, 200.0),
        'snapshots': snapshots,
      });
    } catch (e) {
      debugPrint('Error closing ride session: $e');
    }
  }

  /// Stream all sessions for a barangay (for official logs screen)
  Stream<List<RideSession>> streamRideSessions(String barangayId) {
    return _db
        .collection('ride_sessions')
        .where('barangay_id', isEqualTo: barangayId)
        .orderBy('started_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RideSession.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Stream all sessions for a specific rider
  Stream<List<RideSession>> streamRiderSessions(String riderUid) {
    return _db
        .collection('ride_sessions')
        .where('rider_uid', isEqualTo: riderUid)
        .orderBy('started_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RideSession.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Barangay Boundary ────────────────────────────────────────

  Future<Map<String, dynamic>?> getBarangayBoundary(String barangayId) async {
    try {
      final doc = await _db.collection('barangays').doc(barangayId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching barangay boundary: $e');
      return null;
    }
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
          title: 'Zone Approved',
          body: '"$name" has been approved and is now active.',
          type: 'approved',
          areaId: docId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error approving request: $e');
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
          title: 'Zone Rejected',
          body: '"$name" was rejected. Reason: $reason',
          type: 'rejected',
          areaId: docId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }
}
