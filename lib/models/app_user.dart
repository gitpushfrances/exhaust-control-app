class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'superadmin' | 'barangay_official' | 'rider'
  final String? barangayId;
  final String? barangayName;
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
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isBarangayOfficial => role == 'barangay_official';
  bool get isRider => role == 'rider';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'rider',
      barangayId: map['barangay_id'],
      barangayName: map['barangay_name'],
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
      'is_active': isActive,
      'created_at': createdAt,
      'created_by': createdBy,
    };
  }
}
