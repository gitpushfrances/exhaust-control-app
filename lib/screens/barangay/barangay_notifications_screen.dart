import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class BarangayNotificationsScreen extends StatelessWidget {
  const BarangayNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => fs.markAllNotificationsRead(uid),
            child: const Text(
              'Mark all read',
              style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.streamNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotifCard(data: item, fs: fs);
            },
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final FirestoreService fs;
  const _NotifCard({required this.data, required this.fs});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'approved';
    final title = data['title'] ?? '';
    final body = data['body'] ?? '';
    final isRead = data['is_read'] ?? false;
    final docId = data['doc_id'] ?? '';

    const colors = {
      'approved': Color(0xFF10B981),
      'rejected': Color(0xFFEF4444),
      'submitted': Color(0xFF3B82F6),
    };
    const icons = {
      'approved': Icons.check_circle_outline,
      'rejected': Icons.cancel_outlined,
      'submitted': Icons.upload_outlined,
    };

    final color = colors[type] ?? const Color(0xFF3B82F6);
    final icon = icons[type] ?? Icons.notifications_outlined;

    return GestureDetector(
      onTap: () {
        if (!isRead && docId.isNotEmpty) {
          fs.markNotificationRead(docId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? const Color(0xFFE5E7EB)
                : color.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
