import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class BarangaySubmitRequestScreen extends StatefulWidget {
  const BarangaySubmitRequestScreen({super.key});

  @override
  State<BarangaySubmitRequestScreen> createState() =>
      _BarangaySubmitRequestScreenState();
}

class _BarangaySubmitRequestScreenState
    extends State<BarangaySubmitRequestScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  LatLng? _selectedPoint;
  double _radius = 100;
  String _resolvedAddress = '';
  bool _isGeocoding = false;
  bool _isSaving = false;

  static const List<double> _radiusOptions = [50, 100, 200, 300, 500];

  StreamSubscription<Position>? _positionStream;
  double _currentLat = 10.3157;
  double _currentLng = 123.8854;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  void _startLocationStream() {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 4),
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!mounted) return;
            setState(() {
              _currentLat = position.latitude;
              _currentLng = position.longitude;
            });
            _mapController.move(LatLng(_currentLat, _currentLng), 16);
          },
          onError: (e) {},
        );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _nameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _isGeocoding = true;
      _resolvedAddress = '';
    });
    _geocodePoint(point);
  }

  Future<void> _geocodePoint(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.thoroughfare ?? p.street ?? '',
          p.subLocality ?? '',
          p.locality ?? '',
          p.administrativeArea ?? '',
        ].where((s) => s.isNotEmpty).toList();
        setState(() {
          _resolvedAddress = parts.isNotEmpty
              ? parts.join(', ')
              : 'Unknown location';
          _isGeocoding = false;
        });
        if (_nameController.text.isEmpty) {
          final nameParts = [
            p.subLocality ?? '',
            p.locality ?? '',
          ].where((s) => s.isNotEmpty).toList();
          if (nameParts.isNotEmpty) {
            _nameController.text = nameParts.join(', ');
          }
        }
      } else {
        _fallbackCoords(point);
      }
    } catch (_) {
      _fallbackCoords(point);
    }
  }

  void _fallbackCoords(LatLng point) {
    if (!mounted) return;
    setState(() {
      _resolvedAddress =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _isGeocoding = false;
    });
  }

  Future<void> _submitRequest() async {
    if (_selectedPoint == null) {
      _showError('Tap on the map to select a location first.');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a name for this area.');
      return;
    }

    setState(() => _isSaving = true);

    final official = context.read<AuthProvider>().appUser;
    final fs = FirestoreService();

    final success = await fs.submitZoneRequest(
      name: name,
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
      radius: _radius,
      barangayId: official?.barangayId ?? '',
      barangayName: official?.barangayName ?? '',
      submittedByUid: official?.uid ?? '',
      remarks: _remarksController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _nameController.clear();
      _remarksController.clear();
      setState(() => _selectedPoint = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted — awaiting admin approval'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      _showError('Failed to submit. Check your connection and try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Submit Zone Request',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Color(0xFF3B82F6), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap map to pin location • Request goes to admin for approval',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_currentLat, _currentLng),
                    initialZoom: 14.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.exhaust_controller_app',
                    ),
                    // Selected zone circle + pin
                    if (_selectedPoint != null) ...[
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedPoint!,
                            radius: _radius,
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.2),
                            borderColor: const Color(0xFFF59E0B),
                            borderStrokeWidth: 2,
                            useRadiusInMeter: true,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 40,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFFF59E0B),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Current location blue dot
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_currentLat, _currentLng),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3B82F6),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Recenter button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_barangay',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () => _mapController.move(
                      LatLng(_currentLat, _currentLng),
                      16,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPoint != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isGeocoding
                                ? const Text(
                                    'Resolving address...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  )
                                : Text(
                                    _resolvedAddress,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _label('Zone Name'),
                  const SizedBox(height: 6),
                  _textField(
                    _nameController,
                    'e.g. Barangay Hall, School Zone',
                  ),
                  const SizedBox(height: 12),
                  _label('Remarks (optional)'),
                  const SizedBox(height: 6),
                  _textField(
                    _remarksController,
                    'Any notes for the admin...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _label('Radius'),
                  const SizedBox(height: 6),
                  Row(
                    children: _radiusOptions.map((r) {
                      final selected = _radius == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _radius = r),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${r.toInt()}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  'm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected
                                        ? Colors.white70
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _selectedPoint == null)
                          ? null
                          : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedPoint == null
                                  ? 'Tap map to select location'
                                  : 'Submit for Approval',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
