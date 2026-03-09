import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restricted_areas_provider.dart';

class AdminGlobalMapScreen extends StatelessWidget {
  const AdminGlobalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestrictedAreasProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Global Map',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.areas.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.areas.length,
              itemBuilder: (context, index) {
                final area = provider.areas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      area.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Radius: ${area.radius.toInt()}m',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          'Lat: ${area.latitude.toStringAsFixed(4)}, Lng: ${area.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () =>
                          _showDeleteDialog(context, area.id, area.name),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add zone — coming soon')),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add),
        label: const Text('Add Zone'),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String areaId, String areaName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone?'),
        content: Text('Remove "$areaName" from restricted areas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<RestrictedAreasProvider>();
              await provider.deleteRestrictedArea(areaId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zone deleted'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Restricted Zones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add zones where exhaust should auto-close',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
