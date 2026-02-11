import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exhaust_provider.dart';
import '../providers/restricted_areas_provider.dart';
import 'manage_restricted_areas_screen.dart';

/// Map Screen - Shows user location and restricted areas
/// Using OpenStreetMap (free alternative to Google Maps)
///
/// To use: Add flutter_map and latlong2 packages to pubspec.yaml
/// ```
/// flutter pub add flutter_map latlong2
/// ```
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Simulated location (will be replaced with actual GPS)
  double _currentLat = 14.5995; // Philippines (Antipolo area)
  double _currentLng = 121.0084;

  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();

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
          // Manage Areas button
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
          // Center on user location button
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
            onPressed: () {
              // TODO: Center map on user location
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centering on your location...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Container (placeholder until flutter_map is installed)
          Expanded(
            child: Stack(
              children: [
                // Map Placeholder
                _MapPlaceholder(
                  currentLat: _currentLat,
                  currentLng: _currentLng,
                ),

                // Location Info Card (overlay)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _LocationInfoOverlay(
                    latitude: _currentLat,
                    longitude: _currentLng,
                    locationName: exhaustProvider.currentLocation,
                  ),
                ),

                // Restricted Area Toggle (overlay)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _RestrictedAreaControls(),
                ),
              ],
            ),
          ),

          // Bottom Info Panel
          _BottomInfoPanel(),
        ],
      ),
    );
  }
}

/// Map Placeholder - Shows simple map interface
/// Replace this with actual flutter_map implementation
class _MapPlaceholder extends StatelessWidget {
  final double currentLat;
  final double currentLng;

  const _MapPlaceholder({required this.currentLat, required this.currentLng});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F3F8),
      child: Stack(
        children: [
          // Grid pattern to simulate map
          CustomPaint(size: Size.infinite, painter: _GridPainter()),

          // Center location marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.motorcycle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Your Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions overlay
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Map Preview Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Install flutter_map for live map',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Show installation instructions
                        showDialog(
                          context: context,
                          builder: (context) => _MapSetupDialog(),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Setup Instructions',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid Painter - Creates map-like grid pattern
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8D4E0).withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Location Info Overlay Card
class _LocationInfoOverlay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const _LocationInfoOverlay({
    required this.latitude,
    required this.longitude,
    this.locationName,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locationName ?? 'Antipolo, Calabarzon, PH',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Restricted Area Controls
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
              // Status Badge
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

/// Bottom Info Panel
class _BottomInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          _InfoItem(
            icon: Icons.location_on,
            label: 'Tracking',
            value: 'Active',
            color: const Color(0xFF10B981),
          ),
          const Spacer(),
          _InfoItem(
            icon: Icons.speed,
            label: 'Speed',
            value: '0 km/h',
            color: const Color(0xFF3B82F6),
          ),
          const Spacer(),
          _InfoItem(
            icon: Icons.timer_outlined,
            label: 'Trip Time',
            value: '0:00',
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}

/// Map Setup Instructions Dialog
class _MapSetupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup OpenStreetMap'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable live map with OpenStreetMap:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('1. Install packages:'),
            SizedBox(height: 4),
            SelectableText(
              'flutter pub add flutter_map latlong2',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                backgroundColor: Color(0xFFF3F4F6),
              ),
            ),
            SizedBox(height: 12),
            Text('2. Replace _MapPlaceholder with:'),
            SizedBox(height: 4),
            Text(
              'FlutterMap widget from flutter_map package',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('3. Add GPS permissions to:'),
            SizedBox(height: 4),
            Text(
              '• Android: AndroidManifest.xml\n• iOS: Info.plist',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
