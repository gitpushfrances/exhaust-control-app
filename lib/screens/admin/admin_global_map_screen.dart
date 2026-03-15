import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firestore_service.dart';

class AdminGlobalMapScreen extends StatefulWidget {
  const AdminGlobalMapScreen({super.key});

  @override
  State<AdminGlobalMapScreen> createState() => _AdminGlobalMapScreenState();
}

class _AdminGlobalMapScreenState extends State<AdminGlobalMapScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  final MapController _mapController = MapController();
  String _filter = 'all';

  double _currentLat = 10.3157;
  double _currentLng = 123.8854;
  bool _locationReady = false;
  StreamSubscription<Position>? _positionStream;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLocationStream() {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 8),
      distanceFilter: 5,
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!mounted) return;
            setState(() {
              _currentLat = position.latitude;
              _currentLng = position.longitude;
              if (!_locationReady) {
                _locationReady = true;
                _mapController.move(LatLng(_currentLat, _currentLng), 14);
              }
            });
          },
          onError: (e) {},
        );
  }

  static const _colors = {
    'approved': Color(0xFF10B981),
    'pending': Color(0xFFF59E0B),
    'rejected': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fs.streamAllAreas(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final filtered = _filter == 'all'
              ? all
              : all.where((a) => a['status'] == _filter).toList();

          final circles = filtered.map((area) {
            final status = area['status'] ?? 'approved';
            final color = _colors[status] ?? const Color(0xFF10B981);
            final lat = (area['latitude'] ?? 0.0).toDouble();
            final lng = (area['longitude'] ?? 0.0).toDouble();
            final radius = (area['radius'] ?? 100).toDouble();
            return CircleMarker(
              point: LatLng(lat, lng),
              radius: radius,
              useRadiusInMeter: true,
              color: color.withValues(alpha: 0.15),
              borderColor: color,
              borderStrokeWidth: 1.5,
            );
          }).toList();

          final markers = filtered.map((area) {
            final status = area['status'] ?? 'approved';
            final color = _colors[status] ?? const Color(0xFF10B981);
            final lat = (area['latitude'] ?? 0.0).toDouble();
            final lng = (area['longitude'] ?? 0.0).toDouble();
            return Marker(
              point: LatLng(lat, lng),
              width: 28,
              height: 36,
              child: GestureDetector(
                onTap: () => _showAreaSheet(context, area),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                    ),
                    // Pin tail
                    Container(
                      width: 2,
                      height: 6,
                      color: color,
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          // Current location marker — same pulsing dot as rider map
          final locationMarker = _locationReady
              ? Marker(
                  point: LatLng(_currentLat, _currentLng),
                  width: 40,
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B82F6).withValues(
                                alpha: (1 - _pulseAnimation.value) * 0.3,
                              ),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B82F6),
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : null;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_currentLat, _currentLng),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.exhaust_controller_app',
                  ),
                  CircleLayer(circles: circles),
                  MarkerLayer(
                    markers: [
                      ...markers,
                      if (locationMarker != null) locationMarker,
                    ],
                  ),
                ],
              ),

              // AppBar overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, size: 18, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Text(
                            'Global Map  •  ${filtered.length} zone${filtered.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Filter chips
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All', count: all.length,
                          selected: _filter == 'all', color: const Color(0xFF3B82F6),
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Approved',
                          count: all.where((a) => a['status'] == 'approved').length,
                          selected: _filter == 'approved', color: const Color(0xFF10B981),
                          onTap: () => setState(() => _filter = 'approved'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Pending',
                          count: all.where((a) => a['status'] == 'pending').length,
                          selected: _filter == 'pending', color: const Color(0xFFF59E0B),
                          onTap: () => setState(() => _filter = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Rejected',
                          count: all.where((a) => a['status'] == 'rejected').length,
                          selected: _filter == 'rejected', color: const Color(0xFFEF4444),
                          onTap: () => setState(() => _filter = 'rejected'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Recenter FAB — top right, below filter chips
              Positioned(
                top: 140,
                right: 16,
                child: SafeArea(
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_admin',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () =>
                        _mapController.move(LatLng(_currentLat, _currentLng), 14),
                    child: const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 20),
                  ),
                ),
              ),

              // Legend — below recenter with gap
              Positioned(
                top: 200,
                right: 16,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: const Color(0xFF10B981), label: 'Approved'),
                        const SizedBox(height: 6),
                        _LegendItem(color: const Color(0xFFF59E0B), label: 'Pending'),
                        const SizedBox(height: 6),
                        _LegendItem(color: const Color(0xFFEF4444), label: 'Rejected'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAreaSheet(BuildContext context, Map<String, dynamic> area) {
    final status = area['status'] ?? 'approved';
    final color = _colors[status] ?? const Color(0xFF10B981);
    final name = area['name'] ?? 'Unnamed';
    final radius = (area['radius'] ?? 0).toInt();
    final barangayName = area['barangay_name'] ?? area['barangay_id'] ?? '—';
    final submittedByName = area['submitted_by_name'] ?? '';
    final docId = area['doc_id'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Barangay: $barangayName',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            Text('Radius: ${radius}m',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            if (submittedByName.isNotEmpty)
              Text('Submitted by: $submittedByName',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            if (docId.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, docId, name);
                  },
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  label: const Text('Delete Zone', style: TextStyle(color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Zone?'),
        content: Text('Remove "$name" from restricted areas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fs.deleteRestrictedArea(docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zone deleted'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.count, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}