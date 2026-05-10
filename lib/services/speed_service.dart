import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// One speed reading with timestamp and source info
class SpeedReading {
  final double kph;
  final bool usedFallback;
  final DateTime timestamp;

  const SpeedReading({
    required this.kph,
    required this.usedFallback,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'kph': kph,
    'used_fallback': usedFallback,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Handles GPS speed every second with position-diff fallback
class SpeedService extends ChangeNotifier {
  static final SpeedService instance = SpeedService._();
  SpeedService._();

  SpeedReading? _latest;
  final List<SpeedReading> _buffer =
      []; // rolling buffer for current zone session
  Timer? _timer;

  double? _prevLat;
  double? _prevLng;
  DateTime? _prevTime;
  Position? _lastPosition;

  SpeedReading? get latest => _latest;
  List<SpeedReading> get buffer => List.unmodifiable(_buffer);

  double get averageKph {
    if (_buffer.isEmpty) return 0.0;
    final sum = _buffer.fold(0.0, (a, b) => a + b.kph);
    return sum / _buffer.length;
  }

  double get currentKph => _latest?.kph ?? 0.0;

  /// Call this every time geolocator gives a new position (from map_screen)
  void onPositionUpdate(Position position) {
    _lastPosition = position;
  }

  /// Start 1-second polling — call on app start / zone approach
  void startTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Stop polling and clear buffer — call on zone exit
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clear buffer for a new zone session
  void clearBuffer() {
    _buffer.clear();
  }

  void _tick() {
    final pos = _lastPosition;
    if (pos == null) return;

    double kph;
    bool usedFallback = false;

    // Geolocator gives speed in m/s, -1 means unavailable
    if (pos.speed >= 0) {
      kph = pos.speed * 3.6;
    } else {
      // Fallback: distance / time between last two positions
      kph = _calcFallbackKph(pos);
      usedFallback = true;
    }

    // Clamp negatives (GPS noise)
    kph = kph.clamp(0.0, 200.0);

    final reading = SpeedReading(
      kph: double.parse(kph.toStringAsFixed(1)),
      usedFallback: usedFallback,
      timestamp: DateTime.now(),
    );

    _latest = reading;
    _buffer.add(reading);
    _updatePrev(pos);
    notifyListeners();
  }

  double _calcFallbackKph(Position current) {
    if (_prevLat == null || _prevLng == null || _prevTime == null) {
      _updatePrev(current);
      return 0.0;
    }
    final distM = _haversineMeters(
      _prevLat!,
      _prevLng!,
      current.latitude,
      current.longitude,
    );
    final elapsedSec =
        DateTime.now().difference(_prevTime!).inMilliseconds / 1000.0;
    if (elapsedSec <= 0) return 0.0;
    return (distM / elapsedSec) * 3.6;
  }

  void _updatePrev(Position pos) {
    _prevLat = pos.latitude;
    _prevLng = pos.longitude;
    _prevTime = DateTime.now();
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * asin(sqrt(a));
  }

  double _rad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
