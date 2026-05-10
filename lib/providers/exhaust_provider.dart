import 'package:flutter/foundation.dart';
import '../services/classic_bluetooth_service.dart';
import '../services/speed_service.dart';
import '../services/firestore_service.dart';
import '../models/ride_session.dart';
import '../models/restricted_area.dart';

/// Exhaust State enum
enum ExhaustState {
  open, // Normal mode - loud exhaust
  closed, // Quiet mode - restricted area
  inactive, // Not connected or manual override
}

/// Exhaust Provider - Manages exhaust valve state
/// This is a mock implementation for UI development
class ExhaustProvider with ChangeNotifier {
  ExhaustState _currentState = ExhaustState.inactive;
  bool _isAutoMode = true;
  bool _isInRestrictedArea = false;
  String? _currentLocation;
  double? _latitude;
  double? _longitude;

  // Statistics
  int _totalTrips = 0;
  int _autoClosures = 0;
  int _manualOverrides = 0;
  double _totalDistance = 0.0; // in kilometers

  // Speed & session tracking
  final FirestoreService _fs = FirestoreService();
  String? _activeSessionId;
  String? _activeZoneId;
  String? _activeZoneName;
  String? _activeZoneBarangayId;
  String? _riderUid;
  final List<RideSnapshot> _sessionSnapshots = [];
  bool _approachSnapshotTaken = false;
  static const double _approachRadiusBuffer = 50.0; // meters before zone edge

  // Getters
  ExhaustState get currentState => _currentState;
  bool get isAutoMode => _isAutoMode;
  bool get isInRestrictedArea => _isInRestrictedArea;
  String? get currentLocation => _currentLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  // Statistics getters
  int get totalTrips => _totalTrips;
  int get autoClosures => _autoClosures;
  int get manualOverrides => _manualOverrides;
  double get totalDistance => _totalDistance;

  // Speed
  double get currentSpeedKph => SpeedService.instance.currentKph;

  /// Call after login with the rider's UID
  void setRiderUid(String uid) => _riderUid = uid;

  // Computed properties
  bool get isOpen => _currentState == ExhaustState.open;
  bool get isClosed => _currentState == ExhaustState.closed;
  bool get isInactive => _currentState == ExhaustState.inactive;

  String get stateLabel {
    switch (_currentState) {
      case ExhaustState.open:
        return 'OPEN';
      case ExhaustState.closed:
        return 'CLOSED';
      case ExhaustState.inactive:
        return 'INACTIVE';
    }
  }

  String get stateDescription {
    switch (_currentState) {
      case ExhaustState.open:
        return 'Normal exhaust mode';
      case ExhaustState.closed:
        return 'Quiet mode active';
      case ExhaustState.inactive:
        return 'Connect to device';
    }
  }

  /// Set exhaust state (called by hardware or manual override)
  void setExhaustState(ExhaustState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      notifyListeners();
    }
  }

  /// Toggle between auto and manual mode
  void toggleAutoMode() {
    _isAutoMode = !_isAutoMode;
    if (!_isAutoMode) {
      _manualOverrides++;
    }
    notifyListeners();
  }

  /// Set auto mode explicitly
  void setAutoMode(bool enabled) {
    if (_isAutoMode != enabled) {
      _isAutoMode = enabled;
      if (!enabled) {
        _manualOverrides++;
      }
      notifyListeners();
    }
  }

  /// Update location and check for restricted areas
  /// This should be called by location service with RestrictedAreasProvider
  void updateLocation({
    required double lat,
    required double lng,
    String? locationName,
    bool? isRestricted,
    RestrictedArea? nearestZone,
    double? distanceToZone,
  }) {
    _latitude = lat;
    _longitude = lng;
    _currentLocation = locationName;

    // Start speed tracking on first location fix
    SpeedService.instance.startTracking();

    // Approach detection — 50m outside zone radius
    if (!_isInRestrictedArea &&
        !_approachSnapshotTaken &&
        nearestZone != null &&
        distanceToZone != null &&
        distanceToZone <= nearestZone.radius + _approachRadiusBuffer) {
      _approachSnapshotTaken = true;
      _activeZoneId = nearestZone.id;
      _activeZoneName = nearestZone.name;
      _activeZoneBarangayId = nearestZone.barangayId;
      _takeSnapshot(SnapshotType.approach, nearestZone.id, nearestZone.name);
    }

    if (isRestricted != null) {
      checkRestrictedAreaStatus(isRestricted, zone: nearestZone);
    }

    notifyListeners();
  }

  /// Check if current location is in a restricted area
  /// This will be called by the location service when position updates
  void checkRestrictedAreaStatus(bool isInRestricted, {RestrictedArea? zone}) {
    final oldValue = _isInRestrictedArea;
    _isInRestrictedArea = isInRestricted;

    if (_isInRestrictedArea != oldValue && _isAutoMode) {
      if (_isInRestrictedArea) {
        // Zone entry
        setExhaustState(ExhaustState.closed);
        _autoClosures++;
        ClassicBluetoothService.instance.send('CLOSE');
        SpeedService.instance.clearBuffer();

        final z = zone;
        if (z != null) {
          _activeZoneId = z.id;
          _activeZoneName = z.name;
          _activeZoneBarangayId = z.barangayId;
        }
        _takeSnapshot(
          SnapshotType.entry,
          _activeZoneId ?? '',
          _activeZoneName ?? '',
        );
        _startSession();
      } else {
        // Zone exit
        _takeSnapshot(
          SnapshotType.exit,
          _activeZoneId ?? '',
          _activeZoneName ?? '',
        );
        _closeSession();
        setExhaustState(ExhaustState.open);
        ClassicBluetoothService.instance.send('OPEN');
        _approachSnapshotTaken = false;
      }
    }

    notifyListeners();
  }

  void _takeSnapshot(SnapshotType type, String zoneId, String zoneName) {
    final snap = RideSnapshot(
      type: type,
      speedKph: SpeedService.instance.currentKph,
      decibelDb: 0.0, // placeholder — IoT will fill this via BT
      exhaustState: stateLabel.toLowerCase(),
      zoneId: zoneId,
      zoneName: zoneName,
      timestamp: DateTime.now(),
    );
    _sessionSnapshots.add(snap);
  }

  Future<void> _startSession() async {
    if (_riderUid == null) return;
    _sessionSnapshots.clear();
    final session = RideSession(
      id: '',
      riderUid: _riderUid!,
      zoneId: _activeZoneId ?? '',
      zoneName: _activeZoneName ?? '',
      barangayId: _activeZoneBarangayId ?? '',
      startedAt: DateTime.now(),
    );
    _activeSessionId = await _fs.createRideSession(session);
  }

  Future<void> _closeSession() async {
    final sid = _activeSessionId;
    if (sid == null) return;

    final approach = _sessionSnapshots
        .where((s) => s.type == SnapshotType.approach)
        .firstOrNull;
    final exit = _sessionSnapshots
        .where((s) => s.type == SnapshotType.exit)
        .firstOrNull;

    await _fs.closeRideSession(
      sessionId: sid,
      avgSpeedKph: SpeedService.instance.averageKph,
      decibelBefore: approach?.decibelDb ?? 0.0,
      decibelAfter: exit?.decibelDb ?? 0.0,
      snapshots: _sessionSnapshots.map((s) => s.toMap()).toList(),
    );
    _activeSessionId = null;
    _sessionSnapshots.clear();
    SpeedService.instance.stopTracking();
  }

  /// Manually open exhaust (override)
  void openExhaust() {
    if (_isAutoMode) setAutoMode(false);
    setExhaustState(ExhaustState.open);
    ClassicBluetoothService.instance.send('OPEN');
  }

  /// Manually close exhaust (override)
  void closeExhaust() {
    if (_isAutoMode) setAutoMode(false);
    setExhaustState(ExhaustState.closed);
    ClassicBluetoothService.instance.send('CLOSE');
  }

  /// Start a new trip
  void startTrip() {
    _totalTrips++;
    if (_isAutoMode) {
      setExhaustState(ExhaustState.open);
    } else {
      setExhaustState(ExhaustState.inactive);
    }
    notifyListeners();
  }

  /// End current trip
  void endTrip(double distanceKm) {
    _totalDistance += distanceKm;
    setExhaustState(ExhaustState.inactive);
    notifyListeners();
  }

  /// Reset statistics
  void resetStatistics() {
    _totalTrips = 0;
    _autoClosures = 0;
    _manualOverrides = 0;
    _totalDistance = 0.0;
    notifyListeners();
  }

  /// Simulate entering a restricted area (for testing)
  void simulateRestrictedArea() {
    _isInRestrictedArea = true;
    if (_isAutoMode) {
      setExhaustState(ExhaustState.closed);
      _autoClosures++;
    }
    notifyListeners();
  }

  /// Simulate leaving a restricted area (for testing)
  void simulateLeaveRestrictedArea() {
    _isInRestrictedArea = false;
    if (_isAutoMode) {
      setExhaustState(ExhaustState.open);
    }
    notifyListeners();
  }
}
