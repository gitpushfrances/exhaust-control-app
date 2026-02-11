import 'package:flutter/foundation.dart';

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
  }) {
    _latitude = lat;
    _longitude = lng;
    _currentLocation = locationName;

    // If restriction status is provided, use it
    if (isRestricted != null) {
      checkRestrictedAreaStatus(isRestricted);
    }

    notifyListeners();
  }

  /// Check if current location is in a restricted area
  /// This will be called by the location service when position updates
  void checkRestrictedAreaStatus(bool isInRestricted) {
    final oldValue = _isInRestrictedArea;
    _isInRestrictedArea = isInRestricted;

    // If restriction status changed and we're in auto mode
    if (_isInRestrictedArea != oldValue && _isAutoMode) {
      if (_isInRestrictedArea) {
        setExhaustState(ExhaustState.closed);
        _autoClosures++;
      } else {
        setExhaustState(ExhaustState.open);
      }
    }

    notifyListeners();
  }

  /// Manually open exhaust (override)
  void openExhaust() {
    if (_isAutoMode) {
      setAutoMode(false); // Disable auto mode when manual override
    }
    setExhaustState(ExhaustState.open);
  }

  /// Manually close exhaust (override)
  void closeExhaust() {
    if (_isAutoMode) {
      setAutoMode(false); // Disable auto mode when manual override
    }
    setExhaustState(ExhaustState.closed);
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
