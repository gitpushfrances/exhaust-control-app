import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/restricted_area.dart';
import '../../models/ride_session.dart';

class BarangayRideLogsScreen extends StatelessWidget {
  const BarangayRideLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final official = context.watch<AuthProvider>().appUser;
    final barangayId = official?.primaryBarangayId ?? '';
    final fs = FirestoreService();
    debugPrint(
      '🚦 [OFFICIAL-LOGS] rebuild — uid=${official?.uid} barangayId="$barangayId"',
    );

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
      body: StreamBuilder<List<RestrictedArea>>(
        stream: fs.streamApprovedAreasForBarangay(barangayId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final areas = snap.data ?? [];
          debugPrint(
            '🚦 [OFFICIAL-LOGS] barangayId="$barangayId" → ${areas.length} approved zones: '
            '${areas.map((a) => a.name).join(", ")}',
          );
          if (areas.isEmpty) {
            return const _EmptyZonesState();
          }
          return _ZoneCardList(areas: areas);
        },
      ),
    );
  }
}

class _EmptyZonesState extends StatelessWidget {
  const _EmptyZonesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 12),
            Text(
              'No approved zones yet',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Submit a zone request and once approved, it will appear here as a tab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Zone card list — one card per approved restricted area ───────────
// Tapping a card pushes a detail screen scoped to that zone.

class _ZoneCardList extends StatelessWidget {
  final List<RestrictedArea> areas;
  const _ZoneCardList({required this.areas});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: areas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final area = areas[index];
        return _ZoneCard(
          area: area,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ZoneDetailScreen(area: area)),
          ),
        );
      },
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final RestrictedArea area;
  final VoidCallback onTap;
  const _ZoneCard({required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.name.isEmpty ? 'Zone' : area.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<List<RideSession>>(
                    stream: fs.streamRideSessionsForZone(area.id),
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return Text(
                        '$count ride${count == 1 ? '' : 's'} logged',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Zone detail screen — pushed when a card is tapped ────────────────

class _ZoneDetailScreen extends StatelessWidget {
  final RestrictedArea area;
  const _ZoneDetailScreen({required this.area});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          area.name.isEmpty ? 'Zone' : area.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: _ZoneLogView(area: area),
    );
  }
}

// ─── Per-zone content: summary + latest + previous records ────────────

class _ZoneLogView extends StatelessWidget {
  final RestrictedArea area;
  const _ZoneLogView({required this.area});

  double _avg(List<double> list) {
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return StreamBuilder<List<RideSession>>(
      stream: fs.streamRideSessionsForZone(area.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snap.data ?? [];

        if (sessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
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
                    'Logs appear when riders pass through this zone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            ),
          );
        }

        // Query already orders started_at descending.
        final latest = sessions.first;
        final previous = sessions.skip(1).toList();

        final ridersPassed = sessions.length;
        final avgSpeed = _avg(sessions.map((s) => s.avgSpeedKph).toList());
        final avgDbLevel = _avg(
          sessions.map((s) => s.decibelAvgInside).where((v) => v > 0).toList(),
        );
        final avgDbReduced = _avg(
          sessions.map((s) => s.decibelReduced).where((v) => v > 0).toList(),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ZoneSummaryGrid(
              ridersPassed: ridersPassed,
              avgSpeed: avgSpeed,
              avgDbLevel: avgDbLevel,
              avgDbReduced: avgDbReduced,
            ),
            const SizedBox(height: 20),
            const Text(
              'Latest Record',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            _SessionCard(session: latest, highlight: true),
            if (previous.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Previous Records (${previous.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              ...previous.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SessionCard(session: s),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Zone summary grid (2x2, matches admin summary card style) ────────

class _ZoneSummaryGrid extends StatelessWidget {
  final int ridersPassed;
  final double avgSpeed;
  final double avgDbLevel;
  final double avgDbReduced;

  const _ZoneSummaryGrid({
    required this.ridersPassed,
    required this.avgSpeed,
    required this.avgDbLevel,
    required this.avgDbReduced,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.two_wheeler,
                label: 'Riders Passed',
                value: '$ridersPassed',
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: '${avgSpeed.toStringAsFixed(1)} km/h',
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.volume_up,
                label: 'Avg dB Level',
                value: avgDbLevel > 0
                    ? '${avgDbLevel.toStringAsFixed(1)} dB'
                    : '— dB',
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                icon: Icons.volume_down,
                label: 'Avg dB Reduced',
                value: avgDbReduced > 0
                    ? '${avgDbReduced.toStringAsFixed(1)} dB'
                    : '— dB',
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ─── Session card (unchanged design, now takes a highlight flag) ──────

class _SessionCard extends StatelessWidget {
  final RideSession session;
  final bool highlight;
  const _SessionCard({required this.session, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final reduced = session.decibelReduced;
    final hasReduction = reduced > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
          width: highlight ? 1.5 : 1,
        ),
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _PhaseComparisonRow(session: session),
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

// ─── Phase Comparison — proves dB drops inside the zone ────────────────

class _PhaseComparisonRow extends StatelessWidget {
  final RideSession session;
  const _PhaseComparisonRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final reducedVsApproach =
        session.decibelAvgApproach - session.decibelAvgInside;
    final proved =
        session.decibelAvgApproach > 0 &&
        session.decibelAvgInside > 0 &&
        reducedVsApproach > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phase Averages',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PhaseChip(
              label: 'Approach',
              db: session.decibelAvgApproach,
              speed: session.speedAvgApproach,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            _PhaseChip(
              label: 'Inside',
              db: session.decibelAvgInside,
              speed: session.speedAvgInside,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            _PhaseChip(
              label: 'Exiting',
              db: session.decibelAvgExiting,
              speed: session.speedAvgExiting,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
        if (proved) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                'Confirmed ${reducedVsApproach.toStringAsFixed(1)} dB reduction inside zone',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final double db;
  final double speed;
  final Color color;

  const _PhaseChip({
    required this.label,
    required this.db,
    required this.speed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              db > 0 ? '${db.toStringAsFixed(1)} dB' : '— dB',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              speed > 0 ? '${speed.toStringAsFixed(1)} km/h' : '— km/h',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
