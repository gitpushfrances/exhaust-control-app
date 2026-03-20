class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? barangayId;
  final String? barangayName;
  final List<String> barangayIds;
  final List<String> barangayNames;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.barangayId,
    this.barangayName,
    this.barangayIds = const [],
    this.barangayNames = const [],
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isBarangayOfficial => role == 'barangay_official';
  bool get isRider => role == 'rider';

  /// Primary barangay — first in list, falls back to legacy single field
  String? get primaryBarangayId =>
      barangayIds.isNotEmpty ? barangayIds.first : barangayId;

  String? get primaryBarangayName =>
      barangayNames.isNotEmpty ? barangayNames.first : barangayName;

  /// Display label for the list card
  String get barangayDisplay {
    if (barangayNames.isNotEmpty) {
      if (barangayNames.length == 1) return barangayNames.first;
      if (barangayNames.length == 2) {
        return '${barangayNames[0]}, ${barangayNames[1]}';
      }
      return '${barangayNames[0]} +${barangayNames.length - 1} more';
    }
    return barangayName ?? barangayId ?? 'Unassigned';
  }

  int get barangayCount => barangayIds.isNotEmpty
      ? barangayIds.length
      : (barangayId != null ? 1 : 0);

  bool get hasReachedMaxBarangays => barangayCount >= 3;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    // Support both new list fields and old single fields
    List<String> ids = [];
    List<String> names = [];

    final rawIds = map['barangay_ids'];
    final rawNames = map['barangay_names'];

    if (rawIds is List) {
      ids = rawIds.map((e) => e.toString()).toList();
    } else if (map['barangay_id'] != null) {
      // Migrate legacy single field into list
      ids = [map['barangay_id'].toString()];
    }

    if (rawNames is List) {
      names = rawNames.map((e) => e.toString()).toList();
    } else if (map['barangay_name'] != null) {
      names = [map['barangay_name'].toString()];
    }

    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'rider',
      barangayId: map['barangay_id'],
      barangayName: map['barangay_name'],
      barangayIds: ids,
      barangayNames: names,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? (map['created_at'] as dynamic).toDate()
          : DateTime.now(),
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'barangay_id': barangayId,
      'barangay_name': barangayName,
      'barangay_ids': barangayIds,
      'barangay_names': barangayNames,
      'is_active': isActive,
      'created_at': createdAt,
      'created_by': createdBy,
    };
  }
}
