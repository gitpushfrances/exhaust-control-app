import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// HC-05 Classic Bluetooth service.
/// Singleton — one connection to the exhaust controller hardware at all times.
/// Registered as a ChangeNotifier provider in main.dart.
class ClassicBluetoothService extends ChangeNotifier {
  ClassicBluetoothService._();
  static final ClassicBluetoothService instance = ClassicBluetoothService._();

  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;

  /// Returns all phones paired Classic BT devices.
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Connect to the given HC-05 device.
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting || _isConnected) return false;
    _isConnecting = true;
    notifyListeners();

    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      _connection = conn;
      _isConnected = true;
      _isConnecting = false;
      _connectedDeviceName = device.name;

      conn.input!.listen(
        (_) {},
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );

      notifyListeners();
      return true;
    } catch (_) {
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from HC-05.
  Future<void> disconnect() async {
    await _connection?.close();
    _handleDisconnect();
  }

  /// Send a command string to the Arduino.
  /// Returns true if the command was actually written to the connection,
  /// false if not connected or the write failed. Callers MUST check this
  /// before treating a command as having reached the hardware.
  Future<bool> send(String command) async {
    if (!_isConnected || _connection == null) return false;
    try {
      _connection!.output.add(utf8.encode('$command\r\n'));
      await _connection!.output.allSent;
      return true;
    } catch (_) {
      _handleDisconnect();
      return false;
    }
  }

  void _handleDisconnect() {
    _connection = null;
    _isConnected = false;
    _isConnecting = false;
    _connectedDeviceName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
