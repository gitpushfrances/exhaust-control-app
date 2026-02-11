import 'package:flutter/foundation.dart';

/// Bluetooth Provider - Manages Bluetooth connection state
/// This is a mock implementation for UI development
/// Replace with actual flutter_blue_plus integration when hardware is ready
class BluetoothProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  String? _connectedDeviceId;
  int _signalStrength = 0; // 0-100
  String? _errorMessage;

  // Simulated device list for UI testing
  final List<Map<String, dynamic>> _availableDevices = [];
  final List<Map<String, dynamic>> _pairedDevices = [
    {
      'id': 'device_001',
      'name': 'Exhaust Controller',
      'signalStrength': 85,
      'isAvailable': true,
    },
  ];

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceId => _connectedDeviceId;
  int get signalStrength => _signalStrength;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get availableDevices => _availableDevices;
  List<Map<String, dynamic>> get pairedDevices => _pairedDevices;

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(String deviceId, String deviceName) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual Bluetooth connection
      // Example: await FlutterBluePlus.instance.connect(deviceId);

      _isConnected = true;
      _connectedDeviceId = deviceId;
      _connectedDeviceName = deviceName;
      _signalStrength = 85;
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to connect: ${e.toString()}';
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      // TODO: Replace with actual Bluetooth disconnection
      // Example: await FlutterBluePlus.instance.disconnect();

      _isConnected = false;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _signalStrength = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to disconnect: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Scan for available Bluetooth devices
  Future<void> scanForDevices() async {
    try {
      _availableDevices.clear();
      notifyListeners();

      // TODO: Replace with actual Bluetooth scanning
      // Example: FlutterBluePlus.instance.scan();

      // Simulate scanning
      await Future.delayed(const Duration(seconds: 2));

      // Mock devices for testing
      _availableDevices.addAll([
        {
          'id': 'device_002',
          'name': 'Exhaust Ctrl #2',
          'signalStrength': 72,
          'isAvailable': true,
        },
        {
          'id': 'device_003',
          'name': 'Exhaust Ctrl #3',
          'signalStrength': 55,
          'isAvailable': true,
        },
      ]);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Scan failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Update signal strength (called periodically when connected)
  void updateSignalStrength(int strength) {
    if (_isConnected) {
      _signalStrength = strength.clamp(0, 100);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if a specific device is paired
  bool isDevicePaired(String deviceId) {
    return _pairedDevices.any((device) => device['id'] == deviceId);
  }

  /// Get device by ID
  Map<String, dynamic>? getDevice(String deviceId) {
    try {
      return _pairedDevices.firstWhere((device) => device['id'] == deviceId);
    } catch (e) {
      try {
        return _availableDevices.firstWhere(
          (device) => device['id'] == deviceId,
        );
      } catch (e) {
        return null;
      }
    }
  }
}
