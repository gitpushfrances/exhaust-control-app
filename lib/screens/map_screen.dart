import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/exhaust_provider.dart';
import '../providers/restricted_areas_provider.dart';
import 'manage_restricted_areas_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _currentLat = 14.5995;
  double _currentLng = 121.0084;
  bool _locationReady = false;
  late final MapController _mapController;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchLocation();
    // Update every 8 seconds
    _locationTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _fetchLocation(),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      // Reverse geocode to human-readable address
      String address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // Fallback to raw coords if geocoding fails
      }

      final wasReady = _locationReady;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _locationReady = true;
      });

      // Update exhaust provider with real coords + address
      final exhaustProvider = context.read<ExhaustProvider>();
      final areasProvider = context.read<RestrictedAreasProvider>();
      final isRestricted = areasProvider.isPointInRestrictedArea(
        position.latitude,
        position.longitude,
      );
      exhaustProvider.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
        locationName: address,
        isRestricted: isRestricted,
      );

      // Auto-center map on first fix only
      if (!wasReady) {
        _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
      }
    } catch (e) {
      // Keep last known position on error
    }
  }

  void _centerOnUser() {
    _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();
    final areasProvider = context.watch<RestrictedAreasProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Map',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt, color: Color(0xFF3B82F6)),
            tooltip: 'Manage Areas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRestrictedAreasScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
            onPressed: _centerOnUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.exhaust_controller_app',
              ),
              CircleLayer(
                circles: areasProvider.areas.map((area) {
                  return CircleMarker(
                    point: LatLng(area.latitude, area.longitude),
                    radius: area.radius,
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    borderColor: const Color(0xFFEF4444),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentLat, _currentLng),
                    width: 48,
                    height: 48,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.motorcycle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Location Info Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _LocationInfoOverlay(
              latitude: _currentLat,
              longitude: _currentLng,
              locationReady: _locationReady,
            ),
          ),

          // Restricted Area Controls
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _RestrictedAreaControls(),
          ),
        ],
      ),
    );
  }
}

class _LocationInfoOverlay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool locationReady;

  const _LocationInfoOverlay({
    required this.latitude,
    required this.longitude,
    required this.locationReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: locationReady
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationReady ? 'Live Location' : 'Fetching location...',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationReady
                      ? 'Lat: ${latitude.toStringAsFixed(5)},  Lng: ${longitude.toStringAsFixed(5)}'
                      : 'Please wait',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // GPS update indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: locationReady
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              locationReady ? '8s' : '...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: locationReady
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictedAreaControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_searching,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Restricted Area Test',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: exhaustProvider.isInRestrictedArea
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exhaustProvider.isInRestrictedArea ? 'INSIDE' : 'OUTSIDE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: exhaustProvider.isInRestrictedArea
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    exhaustProvider.simulateRestrictedArea();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated: Entered restricted area'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.where_to_vote, size: 18),
                  label: const Text('Enter Zone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    exhaustProvider.simulateLeaveRestrictedArea();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated: Left restricted area'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  label: const Text('Leave Zone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
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
