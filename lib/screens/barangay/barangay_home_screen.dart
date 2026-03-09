import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class BarangayHomeScreen extends StatelessWidget {
  const BarangayHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final official = context.watch<AuthProvider>().appUser;
    final fs = FirestoreService();
    final uid = official?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barangay Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              official?.barangayName ?? official?.barangayId ?? '—',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 4),
                Text(
                  'Official',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${official?.name ?? 'Official'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Submit zone requests for admin approval.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'My Request Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<Map<String, int>>(
              stream: fs.streamMyRequestStats(uid),
              builder: (context, snap) {
                final stats =
                    snap.data ??
                    {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'Total Submitted',
                      value: stats['total']!,
                      color: const Color(0xFF3B82F6),
                      icon: Icons.inbox_outlined,
                    ),
                    _StatCard(
                      label: 'Pending',
                      value: stats['pending']!,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.hourglass_empty_outlined,
                    ),
                    _StatCard(
                      label: 'Approved',
                      value: stats['approved']!,
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_outline,
                    ),
                    _StatCard(
                      label: 'Rejected',
                      value: stats['rejected']!,
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Recent Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.streamMyRequests(uid),
              builder: (context, snap) {
                final items = (snap.data ?? []).take(3).toList();
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text(
                        'No requests yet. Submit your first zone!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items
                      .map((item) => _RequestItem(data: item))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RequestItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final name = data['name'] ?? 'Unnamed';
    const colors = {
      'approved': Color(0xFF10B981),
      'pending': Color(0xFFF59E0B),
      'rejected': Color(0xFFEF4444),
    };
    final color = colors[status] ?? const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
