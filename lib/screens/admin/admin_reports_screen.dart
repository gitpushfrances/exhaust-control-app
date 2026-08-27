import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/ride_session.dart';
import '../../models/restricted_area.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirestoreService _fs = FirestoreService();

  List<Map<String, dynamic>> _barangays = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBarangays();
  }

  Future<void> _loadBarangays() async {
    final list = await _fs.getBarangaysByMunicipality('Guiuan');
    debugPrint('🏘️ [ADMIN] Loaded ${list.length} barangays for Guiuan');
    if (mounted) {
      setState(() {
        _barangays = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
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
                  Icons.bar_chart_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 4),
                Text(
                  'Zone Data',
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : _barangays.isEmpty
          ? const Center(
              child: Text(
                'No barangays found.',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _barangays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final b = _barangays[index];
                return _BarangayListTile(
                  barangay: b,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _BarangayReportScreen(barangay: b),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Barangay List Tile ───────────────────────────────────────

class _BarangayListTile extends StatelessWidget {
  final Map<String, dynamic> barangay;
  final VoidCallback onTap;

  const _BarangayListTile({required this.barangay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = barangay['name'] ?? barangay['barangay_name'] ?? 'Unnamed';
    final municipality = barangay['municipality_name'] ?? '';
    final docId = barangay['doc_id'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_city_outlined,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    municipality.isNotEmpty ? municipality : docId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barangay Report Detail Screen ───────────────────────────
// Now shows the barangay's active zones as tabs (plus an "All Zones"
// combined tab), instead of one flat list mixing every zone together.

class _BarangayReportScreen extends StatefulWidget {
  final Map<String, dynamic> barangay;

  const _BarangayReportScreen({required this.barangay});

  @override
  State<_BarangayReportScreen> createState() => _BarangayReportScreenState();
}

class _BarangayReportScreenState extends State<_BarangayReportScreen> {
  final FirestoreService _fs = FirestoreService();
  String _filter = 'all'; // 'today' | 'month' | 'all'

  String get _barangayId => widget.barangay['doc_id'] ?? '';
  String get _barangayName =>
      widget.barangay['name'] ?? widget.barangay['barangay_name'] ?? 'Unnamed';
  String get _municipality => widget.barangay['municipality_name'] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _barangayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            if (_municipality.isNotEmpty)
              Text(
                _municipality,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OfficialInfoCard(
                  fs: _fs,
                  barangayId: _barangayId,
                  barangayName: _barangayName,
                  municipality: _municipality,
                ),
                const SizedBox(height: 16),
                _FilterChips(
                  selected: _filter,
                  onChanged: (val) => setState(() => _filter = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<RestrictedArea>>(
              stream: _fs.streamApprovedAreasForBarangay(_barangayId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  debugPrint(
                    '⏳ [ADMIN] Waiting for zones — barangayId="$_barangayId"',
                  );
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  );
                }
                final areas = snap.data ?? [];
                debugPrint(
                  '📍 [ADMIN] barangayId="$_barangayId" → ${areas.length} active zones: '
                  '${areas.map((a) => a.name).join(", ")}',
                );
                return _ZoneReportTabs(
                  barangayId: _barangayId,
                  areas: areas,
                  filter: _filter,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zone tab bar — "All Zones" + one tab per active zone ─────────────

class _ZoneReportTabs extends StatefulWidget {
  final String barangayId;
  final List<RestrictedArea> areas;
  final String filter;

  const _ZoneReportTabs({
    required this.barangayId,
    required this.areas,
    required this.filter,
  });

  @override
  State<_ZoneReportTabs> createState() => _ZoneReportTabsState();
}

class _ZoneReportTabsState extends State<_ZoneReportTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;

  int get _tabCount => widget.areas.length + 1; // +1 for "All Zones"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _ZoneReportTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Active zones stream is live — rebuild the controller if the zone
    // count changes so tabs stay in sync without crashing on length
    // mismatch.
    if (oldWidget.areas.length != widget.areas.length) {
      final keepIndex = _tabController.index < _tabCount
          ? _tabController.index
          : 0;
      _tabController.dispose();
      _tabController = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: keepIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor: const Color(0xFF3B82F6),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              const Tab(text: 'All Zones'),
              ...widget.areas.map(
                (a) => Tab(text: a.name.isEmpty ? 'Zone' : a.name),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ZoneReportView(
                zoneId: null,
                zoneName: 'All Zones',
                barangayId: widget.barangayId,
                filter: widget.filter,
              ),
              ...widget.areas.map(
                (a) => _ZoneReportView(
                  zoneId: a.id,
                  zoneName: a.name,
                  barangayId: widget.barangayId,
                  filter: widget.filter,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Per-zone (or all-zones) report content ────────────────────────────

class _ZoneReportView extends StatelessWidget {
  final String? zoneId; // null = "All Zones" combined view
  final String zoneName;
  final String barangayId;
  final String filter;

  const _ZoneReportView({
    required this.zoneId,
    required this.zoneName,
    required this.barangayId,
    required this.filter,
  });

  List<RideSession> _applyFilter(List<RideSession> sessions) {
    final now = DateTime.now();
    if (filter == 'today') {
      return sessions.where((s) {
        return s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day;
      }).toList();
    } else if (filter == 'month') {
      return sessions.where((s) {
        return s.startedAt.year == now.year && s.startedAt.month == now.month;
      }).toList();
    }
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final stream = zoneId == null
        ? fs.streamRideSessions(barangayId)
        : fs.streamRideSessionsForZone(zoneId!);

    return StreamBuilder<List<RideSession>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          debugPrint(
            '⏳ [ADMIN] Waiting for sessions — zone="$zoneName" '
            '(zoneId=${zoneId ?? "ALL"}, barangayId=$barangayId)',
          );
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (snap.hasError) {
          debugPrint(
            '❌ [ADMIN] Session stream error for "$zoneName": ${snap.error}',
          );
        }

        final all = snap.data ?? [];
        final filtered = _applyFilter(all);
        debugPrint(
          '📊 [ADMIN] zone="$zoneName" filter="$filter" → '
          '${all.length} total sessions, ${filtered.length} after filter',
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCards(sessions: filtered),
              const SizedBox(height: 20),
              const Text(
                'Zone Pass Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Text(
                      'No ride sessions for this period.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else
                ...filtered.map((s) => _SessionCard(session: s)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─── Official Info Card ───────────────────────────────────────

class _OfficialInfoCard extends StatefulWidget {
  final FirestoreService fs;
  final String barangayId;
  final String barangayName;
  final String municipality;

  const _OfficialInfoCard({
    required this.fs,
    required this.barangayId,
    required this.barangayName,
    required this.municipality,
  });

  @override
  State<_OfficialInfoCard> createState() => _OfficialInfoCardState();
}

class _OfficialInfoCardState extends State<_OfficialInfoCard> {
  String _officialName = '—';
  String _officialEmail = '—';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final official = await widget.fs.getOfficialByBarangayId(widget.barangayId);
    if (mounted) {
      setState(() {
        _officialName = official?.name ?? 'No official assigned';
        _officialEmail = official?.email ?? '—';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barangay Official',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _loading
              ? Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  _officialName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            _officialEmail,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.municipality.isNotEmpty
                      ? '${widget.barangayName}, ${widget.municipality}'
                      : widget.barangayName,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('today', 'Today'),
      ('month', 'This Month'),
      ('all', 'All Time'),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final List<RideSession> sessions;

  const _SummaryCards({required this.sessions});

  double _avg(Iterable<double> values) {
    final filtered = values.where((v) => v > 0).toList();
    if (filtered.isEmpty) return 0.0;
    return filtered.reduce((a, b) => a + b) / filtered.length;
  }

  @override
  Widget build(BuildContext context) {
    final count = sessions.length;

    final avgSpeedApproach = _avg(sessions.map((s) => s.speedAvgApproach));
    final avgSpeedInside = _avg(sessions.map((s) => s.speedAvgInside));
    final avgSpeedExiting = _avg(sessions.map((s) => s.speedAvgExiting));

    final avgDbApproach = _avg(sessions.map((s) => s.decibelAvgApproach));
    final avgDbInside = _avg(sessions.map((s) => s.decibelAvgInside));
    final avgDbExiting = _avg(sessions.map((s) => s.decibelAvgExiting));

    debugPrint(
      '🧮 [ADMIN] Summary — count=$count '
      'speed(app/ins/exit)=${avgSpeedApproach.toStringAsFixed(1)}/'
      '${avgSpeedInside.toStringAsFixed(1)}/${avgSpeedExiting.toStringAsFixed(1)} '
      'db(app/ins/exit)=${avgDbApproach.toStringAsFixed(1)}/'
      '${avgDbInside.toStringAsFixed(1)}/${avgDbExiting.toStringAsFixed(1)}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
              const Icon(
                Icons.two_wheeler_outlined,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Riders Passed',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
            Expanded(
              child: _PhaseSummaryCard(
                label: 'Approach',
                speed: avgSpeedApproach,
                db: avgDbApproach,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PhaseSummaryCard(
                label: 'Inside',
                speed: avgSpeedInside,
                db: avgDbInside,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PhaseSummaryCard(
                label: 'Exiting',
                speed: avgSpeedExiting,
                db: avgDbExiting,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhaseSummaryCard extends StatelessWidget {
  final String label;
  final double speed;
  final double db;
  final Color color;

  const _PhaseSummaryCard({
    required this.label,
    required this.speed,
    required this.db,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.speed_outlined,
                size: 13,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  speed > 0 ? '${speed.toStringAsFixed(1)} km/h' : '—',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.volume_up_outlined,
                size: 13,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  db > 0 ? '${db.toStringAsFixed(1)} dB' : '—',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final RideSession session;

  const _SessionCard({required this.session});

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final approach = session.snapshots
        .where((s) => s.type == SnapshotType.approach)
        .firstOrNull;
    final entry = session.snapshots
        .where((s) => s.type == SnapshotType.entry)
        .firstOrNull;
    final exit = session.snapshots
        .where((s) => s.type == SnapshotType.exit)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_outlined,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.zoneName.isNotEmpty
                            ? session.zoneName
                            : 'Unnamed Zone',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${_formatDate(session.startedAt)}  •  ${_formatTime(session.startedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${session.avgSpeedKph.toStringAsFixed(1)} km/h avg',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Snapshot rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _SnapshotRow(
                  label: 'Approach',
                  snapshot: approach,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 8),
                _SnapshotRow(
                  label: 'Entry',
                  snapshot: entry,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 8),
                _SnapshotRow(
                  label: 'Exit',
                  snapshot: exit,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                _PhaseComparisonRow(session: session),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Snapshot Row ─────────────────────────────────────────────

class _SnapshotRow extends StatelessWidget {
  final String label;
  final RideSnapshot? snapshot;
  final Color color;

  const _SnapshotRow({
    required this.label,
    required this.snapshot,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final speed = snapshot?.speedKph.toStringAsFixed(1) ?? '—';
    final db = snapshot?.decibelDb.toStringAsFixed(1) ?? '—';
    final exhaust = snapshot?.exhaustState ?? '—';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _DataChip(label: 'Speed', value: '$speed km/h'),
              const SizedBox(width: 6),
              _DataChip(label: 'dB', value: '$db dB'),
              const SizedBox(width: 6),
              _DataChip(
                label: 'Exhaust',
                value: exhaust,
                valueColor: exhaust == 'closed'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DataChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Comparison — proves dB drops inside the zone ───────

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
