import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/ride_session.dart';

class BarangayRideLogsScreen extends StatelessWidget {
  const BarangayRideLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final official = context.watch<AuthProvider>().appUser;
    final barangayId = official?.primaryBarangayId ?? '';
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ride Logs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: StreamBuilder<List<RideSession>>(
        stream: fs.streamRideSessions(barangayId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snap.data ?? [];
          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speed_outlined,
                    size: 48,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No ride logs yet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Logs appear when riders pass through your zones.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final RideSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final reduced = session.decibelReduced;
    final hasReduction = reduced > 0;

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
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  session.zoneName.isEmpty ? 'Unknown Zone' : session.zoneName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                _formatTime(session.startedAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _Stat(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: '${session.avgSpeedKph.toStringAsFixed(1)} km/h',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _Stat(
                icon: Icons.graphic_eq,
                label: 'dB Before',
                value: session.decibelBefore > 0
                    ? '${session.decibelBefore.toStringAsFixed(1)} dB'
                    : '— dB',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _Stat(
                icon: Icons.volume_down_outlined,
                label: 'dB After',
                value: session.decibelAfter > 0
                    ? '${session.decibelAfter.toStringAsFixed(1)} dB'
                    : '— dB',
                color: const Color(0xFF10B981),
              ),
            ],
          ),

          if (hasReduction) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_down,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reduced by ${reduced.toStringAsFixed(1)} dB',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Snapshots
          if (session.snapshots.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),
            ...session.snapshots.map((s) => _SnapshotRow(snap: s)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final RideSnapshot snap;
  const _SnapshotRow({required this.snap});

  @override
  Widget build(BuildContext context) {
    final labels = {
      SnapshotType.approach: ('Approach', const Color(0xFF6366F1)),
      SnapshotType.entry: ('Entry', const Color(0xFFEF4444)),
      SnapshotType.exit: ('Exit', const Color(0xFF10B981)),
    };
    final record = labels[snap.type]!;
    final label = record.$1;
    final color = record.$2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${snap.speedKph.toStringAsFixed(1)} km/h',
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Text(
            snap.decibelDb > 0
                ? '${snap.decibelDb.toStringAsFixed(1)} dB'
                : '— dB',
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
          const Spacer(),
          Text(
            '${snap.timestamp.hour.toString().padLeft(2, '0')}:${snap.timestamp.minute.toString().padLeft(2, '0')}:${snap.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
