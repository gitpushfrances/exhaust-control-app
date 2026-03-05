import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/restricted_areas_provider.dart';
import '../models/restricted_area.dart';

class AddRestrictedAreaScreen extends StatefulWidget {
  const AddRestrictedAreaScreen({super.key});

  @override
  State<AddRestrictedAreaScreen> createState() =>
      _AddRestrictedAreaScreenState();
}

class _AddRestrictedAreaScreenState extends State<AddRestrictedAreaScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();

  LatLng? _selectedPoint;
  double _radius = 100;
  String _resolvedAddress = '';
  bool _isGeocoding = false;
  bool _isSaving = false;

  static const List<double> _radiusOptions = [50, 100, 200, 300, 500];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), _fetchInitialLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } catch (_) {
      // Stay at default coords
    }
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
        final street = p.thoroughfare ?? p.street ?? '';
        final barangay = p.subLocality ?? '';
        final municipality = p.locality ?? '';
        final province = p.administrativeArea ?? '';
        final region = p.subAdministrativeArea ?? '';

        final parts = [street, barangay, municipality, province, region]
            .where((s) => s.isNotEmpty)
            .toList();

        setState(() {
          _resolvedAddress =
              parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
          _isGeocoding = false;
        });

        if (_nameController.text.isEmpty) {
          final nameParts = [barangay, municipality]
              .where((s) => s.isNotEmpty)
              .toList();
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

  Future<void> _saveArea() async {
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

    final provider = context.read<RestrictedAreasProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;
    final area = RestrictedArea(
      id: '',
      name: name,
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
      radius: _radius,
      createdBy: currentUser?.email ?? currentUser?.uid ?? 'unknown',
      createdAt: DateTime.now(),
    );

    final success = await provider.addRestrictedArea(area);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Restricted area added'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      _showError('Failed to save. Check your connection and try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Restricted Area',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            child: Row(
              children: const [
                Icon(Icons.touch_app, color: Color(0xFF3B82F6), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap anywhere on the map to pin a restricted area',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(14.5995, 121.0084),
                initialZoom: 14.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.exhaust_controller_app',
                ),
                if (_selectedPoint != null) ...[
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _selectedPoint!,
                        radius: _radius,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderColor: const Color(0xFFEF4444),
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
                          color: Color(0xFFEF4444),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isGeocoding
                                ? Row(
                                    children: const [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Resolving address...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _resolvedAddress,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Area Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Barangay Hall, School Zone',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF3B82F6), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Radius',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: _radiusOptions.map((r) {
                      final selected = _radius == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _radius = r),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
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
                                    fontSize: 14,
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
                                        ? Colors.white.withValues(alpha: 0.8)
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isSaving || _selectedPoint == null)
                              ? null
                              : _saveArea,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                                  : 'Save Restricted Area',
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
}