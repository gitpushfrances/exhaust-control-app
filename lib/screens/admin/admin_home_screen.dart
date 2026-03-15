import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().appUser;
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            Text(
              admin?.name ?? 'Super Admin',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Color(0xFF6366F1)),
                SizedBox(width: 4),
                Text('Super Admin', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
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
                  colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${admin?.name ?? 'Admin'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Manage zone requests, officials, and restricted areas.',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('System Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StreamBuilder<int>(
                  stream: fs.streamPendingRequestsCount(),
                  builder: (context, snap) => _StatCard(
                    label: 'Pending Requests', value: snap.data ?? 0,
                    color: const Color(0xFFF59E0B), icon: Icons.hourglass_empty_outlined,
                    hasBadge: (snap.data ?? 0) > 0,
                  ),
                ),
                StreamBuilder<int>(
                  stream: fs.streamApprovedAreasCount(),
                  builder: (context, snap) => _StatCard(
                    label: 'Approved Zones', value: snap.data ?? 0,
                    color: const Color(0xFF10B981), icon: Icons.check_circle_outline,
                  ),
                ),
                StreamBuilder<int>(
                  stream: fs.streamOfficialsCount(),
                  builder: (context, snap) => _StatCard(
                    label: 'Officials', value: snap.data ?? 0,
                    color: const Color(0xFF3B82F6), icon: Icons.badge_outlined,
                  ),
                ),
                StreamBuilder<int>(
                  stream: fs.streamRidersCount(),
                  builder: (context, snap) => _StatCard(
                    label: 'Riders', value: snap.data ?? 0,
                    color: const Color(0xFF8B5CF6), icon: Icons.two_wheeler_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Recent Zone Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.streamAllAreas(),
              builder: (context, snap) {
                final items = (snap.data ?? []).take(5).toList();
                if (items.isEmpty) {
                  return _EmptyCard(message: 'No restricted areas yet.');
                }
                return Column(children: items.map((item) => _AreaItem(data: item)).toList());
              },
            ),

            const SizedBox(height: 24),
            const Text('Officials Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 12),

            StreamBuilder<List<dynamic>>(
              stream: fs.streamOfficials(),
              builder: (context, snap) {
                final officials = (snap.data ?? []).take(3).toList();
                if (officials.isEmpty) {
                  return _EmptyCard(message: 'No officials created yet.');
                }
                return Column(children: officials.map((o) => _OfficialItem(official: o)).toList());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Card ───────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool hasBadge;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBadge ? color.withValues(alpha: 0.4) : const Color(0xFFE5E7EB),
          width: hasBadge ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (hasBadge)
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Area Item — with local reverse geocoding ─────────────────

class _AreaItem extends StatefulWidget {
  final Map<String, dynamic> data;
  const _AreaItem({required this.data});

  @override
  State<_AreaItem> createState() => _AreaItemState();
}

class _AreaItemState extends State<_AreaItem> {
  String _address = '';
  bool _loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    final lat = (widget.data['latitude'] ?? 0.0).toDouble();
    final lng = (widget.data['longitude'] ?? 0.0).toDouble();

    if (lat == 0.0 && lng == 0.0) {
      if (mounted) setState(() { _address = 'Unknown location'; _loadingAddress = false; });
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.thoroughfare ?? p.street ?? '',
          p.subLocality ?? '',
          p.locality ?? '',
        ].where((s) => s.isNotEmpty).toList();

        final resolved = parts.isNotEmpty ? parts.join(', ') : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        if (mounted) setState(() { _address = resolved; _loadingAddress = false; });
      } else {
        if (mounted) setState(() { _address = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'; _loadingAddress = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _address = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'; _loadingAddress = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final status = data['status'] ?? 'pending';
    final name = data['name'] ?? 'Unnamed';
    final submittedByName = data['submitted_by_name'] ?? '';
    final radius = (data['radius'] ?? 0).toStringAsFixed(0);

    const colors = {
      'approved': Color(0xFF10B981),
      'pending': Color(0xFFF59E0B),
      'rejected': Color(0xFFEF4444),
    };
    final color = colors[status] ?? const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.location_on_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                // Resolved address
                _loadingAddress
                    ? Container(
                        width: 120,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        '$_address  •  ${radius}m',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                if (submittedByName.isNotEmpty)
                  Text('By $submittedByName',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Official Item ────────────────────────────────────────────

class _OfficialItem extends StatelessWidget {
  final dynamic official;
  const _OfficialItem({required this.official});

  @override
  Widget build(BuildContext context) {
    final name = official.name ?? '—';
    final barangayName = official.barangayName ?? official.barangayId ?? '—';
    final isActive = official.isActive ?? true;
    final email = official.email ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(barangayName, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFF9CA3AF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }
}