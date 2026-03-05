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
  String _displayAddress = '';

  late final MapController _mapController;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationStream() {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 8),
      distanceFilter: 5,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: 'Exhaust Controller is monitoring your location',
        notificationTitle: 'Location Active',
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate, onError: (e) {});
  }

  Future<void> _onPositionUpdate(Position position) async {
    if (!mounted) return;

    String address = '';
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 6));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.thoroughfare ?? p.street ?? '';
        final barangay = p.subLocality ?? '';
        final municipality = p.locality ?? '';
        final province = p.administrativeArea ?? '';
        final region = p.subAdministrativeArea ?? '';

        final parts = [
          street,
          barangay,
          municipality,
          province,
          region,
        ].where((s) => s.isNotEmpty).toList();
        address = parts.isNotEmpty ? parts.join(', ') : '';
      }
    } catch (_) {}

    if (address.isEmpty) {
      address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    }

    final wasReady = _locationReady;

    if (!mounted) return;
    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _locationReady = true;
      _displayAddress = address;
    });

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

    if (!wasReady) {
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
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
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.4),
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
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _LocationInfoOverlay(
              address: _displayAddress,
              locationReady: _locationReady,
              isRestricted: exhaustProvider.isInRestrictedArea,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationInfoOverlay extends StatelessWidget {
  final String address;
  final bool locationReady;
  final bool isRestricted;

  const _LocationInfoOverlay({
    required this.address,
    required this.locationReady,
    required this.isRestricted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.location_on,
              color: locationReady
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationReady ? 'Live Location' : 'Fetching location...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationReady && address.isNotEmpty
                      ? address
                      : locationReady
                      ? 'Resolving address...'
                      : 'Please wait',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: !locationReady
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : isRestricted
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              !locationReady
                  ? '...'
                  : isRestricted
                  ? 'RESTRICTED'
                  : 'CLEAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: !locationReady
                    ? const Color(0xFFF59E0B)
                    : isRestricted
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
