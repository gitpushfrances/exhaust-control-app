import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AdminRequestDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final adminUid = context.read<AuthProvider>().user?.uid ?? '';
    final docId = data['doc_id'] ?? '';
    final name = data['name'] ?? 'Unnamed Area';
    final lat = (data['latitude'] ?? 0.0).toDouble();
    final lng = (data['longitude'] ?? 0.0).toDouble();
    final radius = (data['radius'] ?? 100).toDouble();
    final barangayId = data['barangay_id'] ?? '—';
    final remarks = data['remarks'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Detail',
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
            // Map Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.exhaust_controller_app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(lat, lng),
                          radius: radius,
                          useRadiusInMeter: true,
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.25),
                          borderColor: const Color(0xFFEF4444),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFEF4444),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Area Name', value: name),
                  const Divider(height: 20),
                  _InfoRow(label: 'Barangay', value: barangayId),
                  const Divider(height: 20),
                  _InfoRow(
                    label: 'Coordinates',
                    value:
                        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  ),
                  const Divider(height: 20),
                  _InfoRow(label: 'Radius', value: '${radius.toInt()}m'),
                  if (remarks.isNotEmpty) ...[
                    const Divider(height: 20),
                    _InfoRow(label: 'Remarks', value: remarks),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showRejectDialog(context, fs, docId, adminUid),
                    icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context, fs, docId, adminUid),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    FirestoreService fs,
    String docId,
    String adminUid,
  ) async {
    final success = await fs.approveRequest(docId: docId, adminUid: adminUid);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zone approved — now live on all rider maps'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve. Try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    FirestoreService fs,
    String docId,
    String adminUid,
  ) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reject Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide a reason — the official will be notified.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);
                  final success = await fs.rejectRequest(
                    docId: docId,
                    adminUid: adminUid,
                    reason: reason,
                  );
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request rejected'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm Reject'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
