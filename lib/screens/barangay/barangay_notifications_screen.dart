import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class BarangayNotificationsScreen extends StatefulWidget {
  const BarangayNotificationsScreen({super.key});

  @override
  State<BarangayNotificationsScreen> createState() =>
      _BarangayNotificationsScreenState();
}

class _BarangayNotificationsScreenState
    extends State<BarangayNotificationsScreen> {
  final FirestoreService _fs = FirestoreService();

  // Multi-select state
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  // Cached list so actions can reference it without re-fetching
  List<Map<String, dynamic>> _items = [];

  void _enterSelectionMode(String docId) {
    setState(() {
      _isSelecting = true;
      _selectedIds.add(docId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
        if (_selectedIds.isEmpty) _isSelecting = false;
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _items.length) {
        // All already selected — deselect all and exit
        _exitSelectionMode();
      } else {
        _selectedIds.clear();
        for (final item in _items) {
          final id = item['doc_id'] as String? ?? '';
          if (id.isNotEmpty) _selectedIds.add(id);
        }
      }
    });
  }

  Future<void> _markSelectedRead() async {
    final ids = _selectedIds.toList();
    _exitSelectionMode();
    await _fs.markNotificationsRead(ids);
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await _showDeleteConfirmDialog(count);
    if (!confirmed) return;
    final ids = _selectedIds.toList();
    _exitSelectionMode();
    await _fs.deleteNotifications(ids);
  }

  Future<void> _deleteAll() async {
    final confirmed = await _showDeleteConfirmDialog(_items.length, all: true);
    if (!confirmed) return;
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';
    _exitSelectionMode();
    await _fs.deleteAllNotifications(uid);
  }

  Future<bool> _showDeleteConfirmDialog(int count, {bool all = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          all
              ? 'Clear All Notifications?'
              : 'Delete $count Notification${count > 1 ? 's' : ''}?',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        content: Text(
          all
              ? 'All notifications will be permanently deleted.'
              : 'The selected notification${count > 1 ? 's' : ''} will be permanently deleted.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _markAllRead() async {
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';
    await _fs.markAllNotificationsRead(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _isSelecting ? _selectionAppBar() : _normalAppBar(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.streamNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          _items = snap.data ?? [];

          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final docId = item['doc_id'] as String? ?? '';
              final isSelected = _selectedIds.contains(docId);

              return _NotifCard(
                data: item,
                isSelecting: _isSelecting,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelecting) {
                    _toggleSelection(docId);
                  } else {
                    final isRead = item['is_read'] ?? false;
                    if (!isRead && docId.isNotEmpty) {
                      _fs.markNotificationRead(docId);
                    }
                  }
                },
                onLongPress: () {
                  if (!_isSelecting) {
                    _enterSelectionMode(docId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─── Normal App Bar ────────────────────────────────────────────

  AppBar _normalAppBar() {
    return AppBar(
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
        // Mark all read
        TextButton(
          onPressed: _items.isEmpty ? null : _markAllRead,
          child: const Text(
            'Mark all read',
            style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
          ),
        ),
        // Clear all
        if (_items.isNotEmpty)
          IconButton(
            onPressed: _deleteAll,
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Color(0xFF9CA3AF),
            ),
            tooltip: 'Clear all',
          ),
      ],
    );
  }

  // ─── Selection App Bar ─────────────────────────────────────────

  AppBar _selectionAppBar() {
    final allSelected = _selectedIds.length == _items.length;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Color(0xFF111827)),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedIds.length} selected',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      actions: [
        // Select all / deselect all
        IconButton(
          onPressed: _selectAll,
          icon: Icon(
            allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
            color: const Color(0xFF3B82F6),
          ),
          tooltip: allSelected ? 'Deselect all' : 'Select all',
        ),
        // Mark read
        IconButton(
          onPressed: _selectedIds.isEmpty ? null : _markSelectedRead,
          icon: const Icon(Icons.done_all_rounded, color: Color(0xFF10B981)),
          tooltip: 'Mark read',
        ),
        // Delete selected
        IconButton(
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFEF4444),
          ),
          tooltip: 'Delete',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notification Card
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotifCard({
    required this.data,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  // ─── Timestamp formatter ───────────────────────────────────────
  String _formatTimestamp(dynamic rawTs) {
    if (rawTs == null) return '';
    DateTime dt;
    try {
      dt = (rawTs as dynamic).toDate() as DateTime;
    } catch (_) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(notifDay).inDays;

    if (diff == 0) {
      // Today — show time only: "2:45 PM"
      final hour = dt.hour == 0
          ? 12
          : dt.hour > 12
          ? dt.hour - 12
          : dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $period';
    } else if (diff == 1) {
      return 'Yesterday';
    } else {
      // Older — show date: "Mar 20"
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
      return '${months[dt.month - 1]} ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'approved';
    final title = data['title'] ?? '';
    final body = data['body'] ?? '';
    final isRead = data['is_read'] ?? false;
    final timestamp = _formatTimestamp(data['created_at']);

    const colorMap = {
      'approved': Color(0xFF10B981),
      'rejected': Color(0xFFEF4444),
      'submitted': Color(0xFF3B82F6),
      'barangay_assigned': Color(0xFF8B5CF6),
    };
    const iconMap = {
      'approved': Icons.check_circle_outline_rounded,
      'rejected': Icons.cancel_outlined,
      'submitted': Icons.upload_outlined,
      'barangay_assigned': Icons.holiday_village_outlined,
    };

    final color = colorMap[type] ?? const Color(0xFF3B82F6);
    final icon = iconMap[type] ?? Icons.notifications_outlined;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
              : isRead
              ? Colors.white
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : isRead
                ? const Color(0xFFE5E7EB)
                : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
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
            // Icon or checkbox
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isSelecting
                  ? Container(
                      key: const ValueKey('checkbox'),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    )
                  : Container(
                      key: const ValueKey('icon'),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 8),
                      // Timestamp
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Body
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
            // Unread dot (only in normal mode)
            if (!isSelecting && !isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
