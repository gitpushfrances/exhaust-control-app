import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import 'admin_create_official_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Manage Officials Screen
// ─────────────────────────────────────────────────────────────────────────────

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
                _ToggleChip(
                  label: 'Active',
                  selected: _showActive,
                  isLeft: true,
                  onTap: () => setState(() => _showActive = true),
                ),
                _ToggleChip(
                  label: 'Inactive',
                  selected: !_showActive,
                  isLeft: false,
                  onTap: () => setState(() => _showActive = false),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminOfficialDetailScreen(official: official),
                  ),
                ),
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

// ─── Toggle Chip ───────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(8) : Radius.zero,
            right: !isLeft ? const Radius.circular(8) : Radius.zero,
          ),
          border: Border.all(color: const Color(0xFF3B82F6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }
}

// ─── Official Card ─────────────────────────────────────────────

class _OfficialCard extends StatelessWidget {
  final AppUser official;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _OfficialCard({
    required this.official,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final barangayCount = official.barangayCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  official.name.isNotEmpty
                      ? official.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
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
                  // Barangay display
                  Row(
                    children: [
                      const Icon(
                        Icons.holiday_village_outlined,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          barangayCount == 0
                              ? 'No barangay assigned'
                              : official.barangayDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: barangayCount == 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                // Barangay count badge
                if (barangayCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$barangayCount brgy',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Admin Official Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminOfficialDetailScreen extends StatefulWidget {
  final AppUser official;

  const AdminOfficialDetailScreen({super.key, required this.official});

  @override
  State<AdminOfficialDetailScreen> createState() =>
      _AdminOfficialDetailScreenState();
}

class _AdminOfficialDetailScreenState extends State<AdminOfficialDetailScreen> {
  final FirestoreService _fs = FirestoreService();

  late AppUser _official;
  List<Map<String, dynamic>> _assignedBarangays = [];
  bool _loadingBarangays = true;

  @override
  void initState() {
    super.initState();
    _official = widget.official;
    _loadAssignedBarangays();
  }

  Future<void> _loadAssignedBarangays() async {
    setState(() => _loadingBarangays = true);
    final list = await _fs.getBarangaysForOfficial(_official.uid);
    if (!mounted) return;
    setState(() {
      _assignedBarangays = list;
      _loadingBarangays = false;
    });
  }

  Future<void> _removeBarangay(Map<String, dynamic> barangay) async {
    final confirmed = await _showRemoveDialog(barangay['barangay_name']);
    if (!confirmed) return;

    final ok = await _fs.removeBarangayFromOfficial(
      officialUid: _official.uid,
      barangayId: barangay['doc_id'],
      barangayName: barangay['barangay_name'],
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${barangay['barangay_name']} removed from ${_official.name}',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadAssignedBarangays();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove barangay. Try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<bool> _showRemoveDialog(String barangayName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Barangay?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        content: Text(
          'Remove $barangayName from ${_official.name}\'s assigned barangays?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openAssignBottomSheet() {
    if (_official.hasReachedMaxBarangays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum of 3 barangays per official. Remove one first.',
          ),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignBarangaySheet(
        official: _official,
        alreadyAssignedIds: _assignedBarangays
            .map((b) => b['doc_id'] as String)
            .toList(),
        onAssigned: () {
          _loadAssignedBarangays();
          // Refresh official data from Firestore
          _fs.getUser(_official.uid).then((updated) {
            if (updated != null && mounted) {
              setState(() => _official = updated);
            }
          });
        },
      ),
    );
  }

  Future<void> _toggleActive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _official.isActive ? 'Deactivate Official?' : 'Reactivate Official?',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        content: Text(
          _official.isActive
              ? '${_official.name} will no longer be able to log in.'
              : '${_official.name} will be able to log in again.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _official.isActive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_official.isActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _fs.setOfficialActiveStatus(_official.uid, !_official.isActive);
    if (!mounted) return;
    final updated = await _fs.getUser(_official.uid);
    if (updated != null && mounted) setState(() => _official = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Official Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ───────────────────────────────────
            _ProfileCard(official: _official, onToggle: _toggleActive),

            const SizedBox(height: 20),

            // ── Assigned Barangays ─────────────────────────────
            Row(
              children: [
                const Text(
                  'Assigned Barangays',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _official.barangayCount >= 3
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_official.barangayCount}/3',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _official.barangayCount >= 3
                          ? const Color(0xFFB45309)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barangay list
            if (_loadingBarangays)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_assignedBarangays.isEmpty)
              _EmptyBarangayCard()
            else
              ..._assignedBarangays.map(
                (b) => _BarangayRow(
                  barangay: b,
                  onRemove: () => _removeBarangay(b),
                ),
              ),

            const SizedBox(height: 16),

            // Assign button
            if (!_official.hasReachedMaxBarangays)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAssignBottomSheet,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                  label: const Text(
                    'Assign Barangay',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB45309),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Maximum of 3 barangays reached',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Card ──────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppUser official;
  final VoidCallback onToggle;

  const _ProfileCard({required this.official, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Row(
            children: [
              // Large avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    official.name.isNotEmpty
                        ? official.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      official.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      official.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: official.isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        official.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: official.isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          // Deactivate / Reactivate
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToggle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: official.isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                official.isActive ? 'Deactivate Account' : 'Reactivate Account',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: official.isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barangay Row ──────────────────────────────────────────────

class _BarangayRow extends StatelessWidget {
  final Map<String, dynamic> barangay;
  final VoidCallback onRemove;

  const _BarangayRow({required this.barangay, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.holiday_village_outlined,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barangay['barangay_name'] ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  barangay['municipality_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Barangay Card ───────────────────────────────────────

class _EmptyBarangayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.holiday_village_outlined,
            size: 32,
            color: Color(0xFFEF4444),
          ),
          SizedBox(height: 8),
          Text(
            'No barangay assigned',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Assign at least one barangay below.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Assign Barangay Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AssignBarangaySheet extends StatefulWidget {
  final AppUser official;
  final List<String> alreadyAssignedIds;
  final VoidCallback onAssigned;

  const _AssignBarangaySheet({
    required this.official,
    required this.alreadyAssignedIds,
    required this.onAssigned,
  });

  @override
  State<_AssignBarangaySheet> createState() => _AssignBarangaySheetState();
}

class _AssignBarangaySheetState extends State<_AssignBarangaySheet> {
  final FirestoreService _fs = FirestoreService();

  List<String> _municipalities = [];
  String? _selectedMunicipality;
  List<Map<String, dynamic>> _barangays = [];
  Map<String, dynamic>? _selectedBarangay;
  bool _loadingMunicipalities = true;
  bool _loadingBarangays = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadMunicipalities();
  }

  Future<void> _loadMunicipalities() async {
    final list = await _fs.getMunicipalities();
    if (!mounted) return;
    setState(() {
      _municipalities = list;
      _loadingMunicipalities = false;
    });
  }

  Future<void> _onMunicipalityChanged(String? value) async {
    if (value == null) return;
    setState(() {
      _selectedMunicipality = value;
      _selectedBarangay = null;
      _barangays = [];
      _loadingBarangays = true;
    });
    final list = await _fs.getBarangaysByMunicipality(value);
    if (!mounted) return;
    setState(() {
      _barangays = list;
      _loadingBarangays = false;
    });
  }

  Future<void> _assign() async {
    if (_selectedBarangay == null) return;

    final barangayId = _selectedBarangay!['doc_id'] as String;
    final barangayName = _selectedBarangay!['barangay_name'] as String;

    // Already assigned
    if (widget.alreadyAssignedIds.contains(barangayId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This barangay is already assigned to this official.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    final ok = await _fs.assignBarangayToOfficial(
      officialUid: widget.official.uid,
      barangayId: barangayId,
      barangayName: barangayName,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign barangay. Try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    // Send notification to official
    await _fs.createNotification(
      uid: widget.official.uid,
      title: 'New Barangay Assigned',
      body:
          'You have been assigned to manage $barangayName. Please check your assignments.',
      type: 'barangay_assigned',
      areaId: barangayId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$barangayName assigned to ${widget.official.name}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      widget.onAssigned();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Assign Barangay to ${widget.official.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.alreadyAssignedIds.length}/3 barangays assigned',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 20),

          // Municipality dropdown
          if (_loadingMunicipalities)
            const Center(child: CircularProgressIndicator())
          else
            _SheetDropdown(
              label: 'Municipality',
              hint: 'Select municipality',
              value: _selectedMunicipality,
              items: _municipalities
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _onMunicipalityChanged,
            ),

          if (_selectedMunicipality != null) ...[
            const SizedBox(height: 12),
            if (_loadingBarangays)
              const Center(child: CircularProgressIndicator())
            else
              _SheetBarangayDropdown(
                barangays: _barangays,
                selected: _selectedBarangay,
                alreadyAssignedIds: widget.alreadyAssignedIds,
                onChanged: (v) => setState(() => _selectedBarangay = v),
              ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedBarangay == null || _isAssigning)
                  ? null
                  : _assign,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAssigning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm Assignment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet Dropdown ────────────────────────────────────────────

class _SheetDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;

  const _SheetDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

// ─── Sheet Barangay Dropdown ───────────────────────────────────

class _SheetBarangayDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> barangays;
  final Map<String, dynamic>? selected;
  final List<String> alreadyAssignedIds;
  final void Function(Map<String, dynamic>?) onChanged;

  const _SheetBarangayDropdown({
    required this.barangays,
    required this.selected,
    required this.alreadyAssignedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (barangays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'No barangays found.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: selected,
      hint: const Text(
        'Select barangay',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),
      decoration: const InputDecoration(
        labelText: 'Barangay',
        filled: true,
        fillColor: Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      items: barangays.map((b) {
        final isOccupied = b['official_uid'] != null && b['official_uid'] != '';
        final isAlreadyAssigned = alreadyAssignedIds.contains(
          b['doc_id'] as String,
        );

        Color dotColor = const Color(0xFF10B981); // vacant
        String label = 'Vacant';
        if (isAlreadyAssigned) {
          dotColor = const Color(0xFF3B82F6);
          label = 'Assigned';
        } else if (isOccupied) {
          dotColor = const Color(0xFFEF4444);
          label = 'Occupied';
        }

        return DropdownMenuItem<Map<String, dynamic>>(
          value: b,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b['barangay_name'] ?? '',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: dotColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}
