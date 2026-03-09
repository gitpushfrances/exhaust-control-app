import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class BarangayMyRequestsScreen extends StatefulWidget {
  const BarangayMyRequestsScreen({super.key});

  @override
  State<BarangayMyRequestsScreen> createState() =>
      _BarangayMyRequestsScreenState();
}

class _BarangayMyRequestsScreenState extends State<BarangayMyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF3B82F6),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.streamMyRequests(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          final pending = all.where((a) => a['status'] == 'pending').toList();
          final approved = all.where((a) => a['status'] == 'approved').toList();
          final rejected = all.where((a) => a['status'] == 'rejected').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _RequestList(items: pending, emptyMsg: 'No pending requests'),
              _RequestList(items: approved, emptyMsg: 'No approved zones yet'),
              _RequestList(items: rejected, emptyMsg: 'No rejected requests'),
            ],
          );
        },
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyMsg;

  const _RequestList({required this.items, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _RequestCard(data: items[index]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RequestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final name = data['name'] ?? 'Unnamed';
    final radius = (data['radius'] ?? 0).toInt();
    final rejectionReason = data['rejection_reason'] ?? '';

    const colors = {
      'approved': Color(0xFF10B981),
      'pending': Color(0xFFF59E0B),
      'rejected': Color(0xFFEF4444),
    };
    final color = colors[status] ?? const Color(0xFFF59E0B);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          const SizedBox(height: 6),
          Text(
            'Radius: ${radius}m',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
