import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/classic_bluetooth_service.dart';
import '../services/speed_service.dart';
import '../services/firestore_service.dart';
import '../models/ride_session.dart';
import '../models/restricted_area.dart';
import '../utils/geo_utils.dart';

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

  // Exit trailing window — mirrors the approach buffer on the way out,
  // so "exiting" is a real phase with a start and end, not an instant.
  RestrictedArea? _exitingZone;
  bool _awaitingExitWindow = false;
  String? _pendingCloseSessionId;
  Timer? _exitWindowTimeoutTimer;
  static const Duration _exitWindowMaxWait = Duration(seconds: 20);

  // Debounce GPS boundary jitter before committing a restricted-area state.
  bool? _pendingRestrictedState;
  Timer? _restrictedDwellTimer;

  // State must remain stable for 1.5 seconds before it is committed.
  static const Duration _restrictedDwellTime = Duration(milliseconds: 1500);

  // Phase-windowed averages — captured then buffer-cleared at each
  // zone-event boundary (entry / exit-trigger / exit-window-cleared).
  double _avgDbApproach = 0.0;
  double _avgDbInside = 0.0;
  double _avgDbExiting = 0.0;
  double _avgSpeedApproach = 0.0;
  double _avgSpeedInside = 0.0;
  double _avgSpeedExiting = 0.0;

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

  // Valve command failure tracking
  bool _valveError = false;
  bool get valveError => _valveError;

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

    SpeedService.instance.startTracking();

    // Exit trailing window — keep accumulating speed/dB for the zone
    // just exited until the rider clears the same buffer distance used
    // for approach, then finalize the "exiting" averages and actually
    // close the Firestore session.
    if (_awaitingExitWindow && _exitingZone != null) {
      final distFromExitedZone = haversineMeters(
        lat,
        lng,
        _exitingZone!.latitude,
        _exitingZone!.longitude,
      );
      if (distFromExitedZone >= _exitingZone!.radius + _approachRadiusBuffer) {
        _finalizeExitWindow();
      }
    }

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
  /// This will be called by the location service when position updates.
  /// A raw flip only acts after it holds for [_restrictedDwellTime] —
  /// GPS jitter right at the zone edge can't fire ZENTER/ZEXIT back-to-back.
  void checkRestrictedAreaStatus(bool isInRestricted, {RestrictedArea? zone}) {
    debugPrint(
      '📍 checkRestrictedAreaStatus — isInRestricted: $isInRestricted, oldValue: $_isInRestrictedArea, autoMode: $_isAutoMode, riderUid: $_riderUid',
    );

    if (isInRestricted == _isInRestrictedArea) {
      // Matches the already-committed state — any opposite-direction
      // flip that was mid-dwell was noise. Cancel it.
      _restrictedDwellTimer?.cancel();
      _restrictedDwellTimer = null;
      _pendingRestrictedState = null;
      return;
    }

    if (_pendingRestrictedState == isInRestricted) {
      return; // same candidate still holding, timer already running
    }

    _pendingRestrictedState = isInRestricted;
    _restrictedDwellTimer?.cancel();
    final pendingState = isInRestricted;
    final pendingZone = zone;

    _restrictedDwellTimer = Timer(_restrictedDwellTime, () {
      if (_pendingRestrictedState != pendingState) {
        return;
      }

      _applyRestrictedAreaChange(pendingState, zone: pendingZone);

      _pendingRestrictedState = null;
      _restrictedDwellTimer = null;
    });
  }

  /// Fires ZENTER/ZEXIT and does the actual state/session bookkeeping.
  /// Only reached once a raw flip has survived the dwell window.
  Future<void> _applyRestrictedAreaChange(
    bool isInRestricted, {
    RestrictedArea? zone,
  }) async {
    _isInRestrictedArea = isInRestricted;

    if (_isAutoMode) {
      if (isInRestricted) {
        // Zone entry — capture the approach-phase averages before
        // clearing both buffers so the "inside" phase starts clean.
        _avgDbApproach = ClassicBluetoothService.instance.averageDb;
        ClassicBluetoothService.instance.clearDbBuffer();
        _avgSpeedApproach = SpeedService.instance.captureAndClear();

        // Tell Arduino the rider is now INSIDE the restricted area, and
        // wait for DONE:CLOSE — confirms the valve actually finished its
        // 45° swing, not just that the write went through.
        final sent = await ClassicBluetoothService.instance.send('INSIDE');
        _valveError = !sent;

        if (sent) {
          setExhaustState(ExhaustState.closed);
          _autoClosures++;
          // Heartbeat is continuous at the ClassicBluetoothService level
          // now — no longer zone-scoped here.
        } else {
          debugPrint(
            '⚠️ ZENTER failed — BT not connected. Valve state NOT updated.',
          );
        }

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
        // Log the session regardless of BT status — speed/zone data is
        // still valid even if the valve command failed to reach hardware.
        _startSession();
      } else {
        // Zone exit — capture the "inside" averages, then start the
        // exit trailing window instead of closing the session right away.
        _avgDbInside = ClassicBluetoothService.instance.averageDb;
        ClassicBluetoothService.instance.clearDbBuffer();
        _avgSpeedInside = SpeedService.instance.captureAndClear();

        // Tell Arduino the rider is leaving the restricted area, and wait
        // for DONE:OPEN — confirms the valve actually finished returning,
        // not just that the write went through.
        final sent = await ClassicBluetoothService.instance.send('OUTSIDE');
        _valveError = !sent;

        _takeSnapshot(
          SnapshotType.exit,
          _activeZoneId ?? '',
          _activeZoneName ?? '',
        );

        if (sent) {
          setExhaustState(ExhaustState.open);
        } else {
          debugPrint(
            '⚠️ ZEXIT failed — BT not connected. Valve state NOT updated.',
          );
        }

        _approachSnapshotTaken = false;

        // Capture which session to close now — not _activeSessionId
        // later — so a fast re-entry into a new zone before this
        // window finishes can't cause the wrong session to be closed.
        _exitingZone = zone;
        _awaitingExitWindow = true;
        _pendingCloseSessionId = _activeSessionId;
        _activeSessionId = null;
        _exitWindowTimeoutTimer?.cancel();
        _exitWindowTimeoutTimer = Timer(_exitWindowMaxWait, () {
          if (_awaitingExitWindow) {
            debugPrint('⏱️ Exit window timed out — finalizing anyway');
            _finalizeExitWindow();
          }
        });
      }
    }

    notifyListeners();
  }

  void _takeSnapshot(SnapshotType type, String zoneId, String zoneName) {
    final snap = RideSnapshot(
      type: type,
      speedKph: SpeedService.instance.currentKph,
      decibelDb: ClassicBluetoothService.instance.latestDb ?? 0.0,
      exhaustState: stateLabel.toLowerCase(),
      zoneId: zoneId,
      zoneName: zoneName,
      timestamp: DateTime.now(),
    );
    _sessionSnapshots.add(snap);
  }

  Future<void> _startSession() async {
    debugPrint(
      '🔥 _startSession called — riderUid: $_riderUid, zoneId: $_activeZoneId',
    );
    if (_riderUid == null) {
      debugPrint('❌ _startSession aborted — riderUid is null');
      return;
    }
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

  void _finalizeExitWindow() {
    _exitWindowTimeoutTimer?.cancel();
    _exitWindowTimeoutTimer = null;
    _avgDbExiting = ClassicBluetoothService.instance.averageDb;
    ClassicBluetoothService.instance.clearDbBuffer();
    _avgSpeedExiting = SpeedService.instance.captureAndClear();
    _awaitingExitWindow = false;
    _exitingZone = null;

    final sid = _pendingCloseSessionId;
    _pendingCloseSessionId = null;
    _closeSession(sid);
  }

  Future<void> _closeSession(String? sessionId) async {
    if (sessionId == null) {
      _resetPhaseAverages();
      _sessionSnapshots.clear();
      SpeedService.instance.stopTracking();
      return;
    }

    final approach = _sessionSnapshots
        .where((s) => s.type == SnapshotType.approach)
        .firstOrNull;
    final exit = _sessionSnapshots
        .where((s) => s.type == SnapshotType.exit)
        .firstOrNull;

    final phaseSpeeds = [
      _avgSpeedApproach,
      _avgSpeedInside,
      _avgSpeedExiting,
    ].where((v) => v > 0).toList();
    final overallAvgSpeed = phaseSpeeds.isEmpty
        ? 0.0
        : phaseSpeeds.reduce((a, b) => a + b) / phaseSpeeds.length;

    await _fs.closeRideSession(
      sessionId: sessionId,
      avgSpeedKph: overallAvgSpeed,
      decibelBefore: approach?.decibelDb ?? 0.0,
      decibelAfter: exit?.decibelDb ?? 0.0,
      decibelAvgApproach: _avgDbApproach,
      decibelAvgInside: _avgDbInside,
      decibelAvgExiting: _avgDbExiting,
      speedAvgApproach: _avgSpeedApproach,
      speedAvgInside: _avgSpeedInside,
      speedAvgExiting: _avgSpeedExiting,
      snapshots: _sessionSnapshots.map((s) => s.toMap()).toList(),
    );
    _sessionSnapshots.clear();
    _resetPhaseAverages();
    SpeedService.instance.stopTracking();
  }

  void _resetPhaseAverages() {
    _avgDbApproach = 0.0;
    _avgDbInside = 0.0;
    _avgDbExiting = 0.0;
    _avgSpeedApproach = 0.0;
    _avgSpeedInside = 0.0;
    _avgSpeedExiting = 0.0;
  }

  @override
  void dispose() {
    _exitWindowTimeoutTimer?.cancel();
    _restrictedDwellTimer?.cancel();
    super.dispose();
  }

  /// Manually open exhaust (override)
  Future<void> openExhaust() async {
    if (_isAutoMode) setAutoMode(false);
    final sent = await ClassicBluetoothService.instance.send('OPEN');
    _valveError = !sent;
    if (sent) {
      setExhaustState(ExhaustState.open);
    } else {
      debugPrint(
        '⚠️ Manual OPEN failed — BT not connected. Valve state NOT updated.',
      );
    }
    notifyListeners();
  }

  /// Manually close exhaust (override)
  Future<void> closeExhaust() async {
    if (_isAutoMode) setAutoMode(false);
    final sent = await ClassicBluetoothService.instance.send('CLOSE');
    _valveError = !sent;
    if (sent) {
      setExhaustState(ExhaustState.closed);
    } else {
      debugPrint(
        '⚠️ Manual CLOSE failed — BT not connected. Valve state NOT updated.',
      );
    }
    notifyListeners();
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
