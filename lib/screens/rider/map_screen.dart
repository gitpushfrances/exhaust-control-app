import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/map_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/exhaust_provider.dart';
import '../../providers/restricted_areas_provider.dart';
import '../../services/speed_service.dart';
import '../../models/restricted_area.dart';
import '../../services/firestore_service.dart';
import '../../utils/geo_utils.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  double _currentLat = 14.5995;
  double _currentLng = 121.0084;
  bool _locationReady = false;
  String _displayAddress = '';

  // Map rotation — drives the compass indicator
  double _rotationDeg = 0.0;

  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<MapEvent>? _mapEventSub;
  List<Map<String, dynamic>> _allBarangays = [];

  // The last position we actually accepted as "real" movement — used to
  // filter out GPS scatter so the marker/address don't drift while the
  // rider is genuinely stationary.
  double? _lastAcceptedLat;
  double? _lastAcceptedLng;
  static const double _stationaryRadiusMeters = 6.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Show a cached last-known fix immediately so the map centers near the
    // rider right away instead of sitting on the default coordinates while
    // the first live GPS fix (and reverse geocode) are still in flight —
    // this matters most on slow/unstable connections.
    _loadLastKnownPosition();
    _startLocationStream();
    _loadBarangays();

    _mapEventSub = _mapController.mapEventStream.listen((event) {
      final rotation = event.camera.rotation;
      if (rotation != _rotationDeg) {
        setState(() => _rotationDeg = rotation);
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapEventSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null || !mounted || _locationReady) return;
      setState(() {
        _currentLat = last.latitude;
        _currentLng = last.longitude;
      });
      _mapController.move(LatLng(last.latitude, last.longitude), 15.0);
    } catch (_) {
      // No cached fix available — the live stream will populate the map
      // shortly, so this is safe to ignore.
    }
  }

  /// Loads all seeded barangay polygons once so live GPS fixes can be
  /// resolved to a barangay locally, instead of depending on OSM's
  /// reverse-geocode (which often leaves subLocality empty for rural
  /// barangays here in Guiuan).
  Future<void> _loadBarangays() async {
    final barangays = await FirestoreService().getAllBarangays();
    if (!mounted) return;
    setState(() => _allBarangays = barangays);
  }

  static const double _defaultZoom = 15.0;

  /// Smoothly animates rotation back to true north — and zooms back in
  /// to the default level if the user had zoomed out further than that.
  /// Mirrors Google Maps' compass-tap behavior.
  void _resetNorth() {
    final camera = _mapController.camera;
    final startCenter = camera.center;
    final targetCenter = LatLng(_currentLat, _currentLng);
    final startRotation = camera.rotation;
    final startZoom = camera.zoom;
    final targetZoom = startZoom < _defaultZoom ? _defaultZoom : startZoom;

    // Nothing to animate — already north-up, zoomed in enough, and
    // centered on the live position.
    if (startRotation == 0 &&
        targetZoom == startZoom &&
        startCenter == targetCenter) {
      return;
    }

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: targetCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: targetCenter.longitude,
    );
    final rotationTween = Tween<double>(begin: startRotation, end: 0);
    final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    animation.addListener(() {
      _mapController.moveAndRotate(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        rotationTween.evaluate(animation),
      );
    });
    controller.forward().whenComplete(controller.dispose);
  }

  void _startLocationStream() {
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: Duration(milliseconds: 250),
      distanceFilter: 0,
      foregroundNotificationConfig: ForegroundNotificationConfig(
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
    SpeedService.instance.onPositionUpdate(position);

    // Let the very first fix through unconditionally so the UI updates
    // right away instead of sitting on "Fetching location..." — the
    // first GPS fix after a cold start is often low-accuracy and would
    // otherwise get filtered out, adding a real delay before anything
    // shows on screen. Once we have one fix, apply the stricter filters.
    if (_locationReady) {
      // Reject poor-accuracy fixes outright — these come from weak/
      // obstructed sky view (indoors, roof cover, tall nearby structures)
      // and will drag the marker around no matter how good our distance
      // filtering is. 20m is generous; tighten to ~12-15m once field-
      // tested outdoors.
      const maxTrustedAccuracyMeters = 20.0;
      if (position.accuracy > maxTrustedAccuracyMeters) {
        return;
      }
    }

    // If this fix is within normal GPS scatter of the last accepted
    // position, treat it as noise: skip moving the marker, re-geocoding,
    // and re-running zone checks entirely. Prevents the "calibrating"
    // wander when the device isn't actually moving.
    if (_lastAcceptedLat != null && _lastAcceptedLng != null) {
      final movedMeters = _haversineMeters(
        _lastAcceptedLat!,
        _lastAcceptedLng!,
        position.latitude,
        position.longitude,
      );
      if (movedMeters < _stationaryRadiusMeters) {
        return;
      }
    }

    String address = '';
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 6));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.thoroughfare ?? p.street ?? '';
        final resolvedBarangay = getBarangayForPoint(
          position.latitude,
          position.longitude,
          _allBarangays,
        );
        final barangay = resolvedBarangay.isNotEmpty
            ? resolvedBarangay
            : (p.subLocality ?? '');
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
    } catch (e, st) {
      debugPrint('[Geocode ERROR] $e');
      debugPrint('$st');
    }

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
    _lastAcceptedLat = position.latitude;
    _lastAcceptedLng = position.longitude;

    final exhaustProvider = context.read<ExhaustProvider>();
    final areasProvider = context.read<RestrictedAreasProvider>();
    final isRestricted = areasProvider.isPointInRestrictedArea(
      position.latitude,
      position.longitude,
    );

    // Find nearest zone + distance for approach detection
    RestrictedArea? nearestZone;
    double? distanceToNearest;
    for (final area in areasProvider.areas) {
      final d = _haversineMeters(
        position.latitude,
        position.longitude,
        area.latitude,
        area.longitude,
      );
      if (distanceToNearest == null || d < distanceToNearest) {
        distanceToNearest = d;
        nearestZone = area;
      }
    }

    // If the rider is actually inside a zone's radius, that zone must
    // win over whichever zone's center merely happens to be closest —
    // otherwise a ride can get logged under the wrong zone_id when two
    // zones sit near each other.
    final containingZone = areasProvider.getRestrictedAreaAtPoint(
      position.latitude,
      position.longitude,
    );

    exhaustProvider.updateLocation(
      lat: position.latitude,
      lng: position.longitude,
      locationName: address,
      isRestricted: isRestricted,
      nearestZone: containingZone ?? nearestZone,
      distanceToZone: distanceToNearest,
    );

    if (!wasReady) {
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    }
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * asin(sqrt(a));
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
              minZoom: MapConfig.minZoom,
              maxZoom: MapConfig.maxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
                tileProvider: NetworkTileProvider(
                  // flutter_map's built-in disk cache (8.2+). Tiles already
                  // seen render instantly from disk instead of waiting on
                  // the network — the main win on weak/unstable connections.
                  // Keep serving a cached tile for a full day even if the
                  // server would normally expire it sooner — avoids
                  // re-fetch attempts (and blank tiles) on a spotty signal.
                  cachingProvider:
                      BuiltInMapCachingProvider.getOrCreateInstance(
                        maxCacheSize: 300 * 1000 * 1000, // 300 MB soft limit
                        overrideFreshAge: const Duration(days: 1),
                      ),
                ),
              ),
              MapConfig.attribution(),
              CircleLayer(
                circles: areasProvider.areas.map((area) {
                  return CircleMarker(
                    point: LatLng(area.latitude, area.longitude),
                    radius: area.radius,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderColor: const Color(0xFFEF4444),
                    borderStrokeWidth: 1.5,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentLat, _currentLng),
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
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
                            // Inner solid dot
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B82F6),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.4),
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
                  ),
                ],
              ),
            ],
          ),

          // Location overlay — no badge when CLEAR, only shows RESTRICTED
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

          // Speed overlay
          Positioned(
            bottom: 24,
            left: 16,
            child: Consumer<ExhaustProvider>(
              builder: (context, exhaust, _) {
                final speed = SpeedService.instance.currentKph;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        speed.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text(
                          'km/h',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Compass — always visible, like Google Maps. Needle rotates
          // opposite the map so it always points true north; tap resets
          // rotation to north-up. Sits where the old recenter FAB used
          // to be, since recenter now lives in the AppBar action up top.
          Positioned(
            bottom: 24,
            right: 16,
            child: GestureDetector(
              onTap: _resetNorth,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -_rotationDeg * pi / 180,
                  child: const Icon(
                    Icons.navigation,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
              ),
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
          // Only show badge when inside a restricted area
          if (isRestricted) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'RESTRICTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
