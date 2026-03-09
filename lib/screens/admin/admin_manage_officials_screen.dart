import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import 'admin_create_official_screen.dart';

class AdminManageOfficialsScreen extends StatefulWidget {
  const AdminManageOfficialsScreen({super.key});

  @override
  State<AdminManageOfficialsScreen> createState() =>
      _AdminManageOfficialsScreenState();
}

class _AdminManageOfficialsScreenState
    extends State<AdminManageOfficialsScreen> {
  final FirestoreService _fs = FirestoreService();
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Officials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showActive = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _showActive
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _showActive
                            ? Colors.white
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showActive = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !_showActive
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_showActive
                            ? Colors.white
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _fs.streamOfficials(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          final filtered = all.where((u) => u.isActive == _showActive).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showActive
                        ? 'No active officials'
                        : 'No inactive officials',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final official = filtered[index];
              return _OfficialCard(
                official: official,
                onToggle: () async {
                  await _fs.setOfficialActiveStatus(
                    official.uid,
                    !official.isActive,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCreateOfficialScreen()),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Official'),
      ),
    );
  }
}

class _OfficialCard extends StatelessWidget {
  final AppUser official;
  final VoidCallback onToggle;

  const _OfficialCard({required this.official, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                official.name.isNotEmpty ? official.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  official.barangayName ?? official.barangayId ?? '—',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  official.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: official.isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  official.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: official.isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _confirmToggle(context),
                child: Text(
                  official.isActive ? 'Deactivate' : 'Reactivate',
                  style: TextStyle(
                    fontSize: 11,
                    color: official.isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          official.isActive ? 'Deactivate Official?' : 'Reactivate Official?',
        ),
        content: Text(
          official.isActive
              ? '${official.name} will no longer be able to log in.'
              : '${official.name} will be able to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onToggle();
            },
            style: TextButton.styleFrom(
              foregroundColor: official.isActive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
            child: Text(official.isActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
  }
}
