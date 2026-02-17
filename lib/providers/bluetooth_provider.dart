import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  String? _connectedDeviceId;
  int _signalStrength = 0;
  String? _errorMessage;
  BluetoothDevice? _connectedDevice;

  final List<Map<String, dynamic>> _availableDevices = [];
  final List<Map<String, dynamic>> _pairedDevices = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceId => _connectedDeviceId;
  int get signalStrength => _signalStrength;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get availableDevices => _availableDevices;
  List<Map<String, dynamic>> get pairedDevices => _pairedDevices;

  /// Connect to a real BLE device
  Future<bool> connectToDevice(String deviceId, String deviceName) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allDevices = [..._pairedDevices, ..._availableDevices];
      final match = allDevices.firstWhere(
        (d) => d['id'] == deviceId,
        orElse: () => {},
      );
      final device = match['device'] as BluetoothDevice?;

      if (device == null) throw Exception('Device not found');

      await device.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device;
      _isConnected = true;
      _connectedDeviceId = deviceId;
      _connectedDeviceName = deviceName;
      _signalStrength = 85;
      _isConnecting = false;

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _connectedDevice = null;
          _connectedDeviceId = null;
          _connectedDeviceName = null;
          _signalStrength = 0;
          notifyListeners();
        }
      });

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
      await _connectedDevice?.disconnect();
      _isConnected = false;
      _connectedDevice = null;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _signalStrength = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to disconnect: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Scan for real BLE devices
  Future<void> scanForDevices() async {
    try {
      _availableDevices.clear();
      _pairedDevices.clear();
      notifyListeners();

      // Get system bonded devices
      final systemDevices = FlutterBluePlus.connectedDevices;
      for (final d in systemDevices) {
        _pairedDevices.add({
          'id': d.remoteId.str,
          'name': d.platformName.isNotEmpty ? d.platformName : 'Unknown Device',
          'signalStrength': 85,
          'device': d,
        });
      }
      notifyListeners();

      // Scan for nearby devices
      // Stop any existing scan first
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      FlutterBluePlus.scanResults.listen((results) {
        _availableDevices.clear();
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : 'Unknown Device';
          final signal = (r.rssi + 100).clamp(0, 100);
          _availableDevices.add({
            'id': r.device.remoteId.str,
            'name': name,
            'signalStrength': signal,
            'device': r.device,
          });
        }
        notifyListeners();
      });

      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;
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
