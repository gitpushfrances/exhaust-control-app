import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ClassicBluetoothService extends ChangeNotifier {
  ClassicBluetoothService._();
  static final ClassicBluetoothService instance = ClassicBluetoothService._();

  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  String? _lastDeviceAddress;

  String _rxBuffer = '';

  double? _latestDb;
  double? get latestDb => _latestDb;

  Completer<bool>? _pendingAck;
  String? _pendingAckCommand;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) return false;

    if (_isConnected || _connection != null) {
      await _forceCloseConnection();
    }

    _isConnecting = true;
    notifyListeners();

    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final conn = await BluetoothConnection.toAddress(
          device.address,
        ).timeout(const Duration(seconds: 8));

        _connection = conn;
        _isConnected = true;
        _isConnecting = false;
        _connectedDeviceName = device.name;
        _lastDeviceAddress = device.address;

        conn.input!.listen(
          _handleIncomingData,
          onDone: _handleDisconnect,
          onError: (_) => _handleDisconnect(),
          cancelOnError: true,
        );
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('BT connect attempt $attempt failed: $e');
        if (attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    }

    _isConnecting = false;
    notifyListeners();
    return false;
  }

  Future<void> _forceCloseConnection() async {
    try {
      await _connection?.finish();
    } catch (_) {}
    try {
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
    _isConnected = false;
    _connectedDeviceName = null;
  }

  /// Finds a paired device whose name contains [nameContains] (case-insensitive)
  /// and connects to it. Returns false if no matching device is paired.
  Future<bool> autoConnect({String nameContains = 'HC-05'}) async {
    final devices = await getPairedDevices();
    BluetoothDevice? match;
    for (final d in devices) {
      if ((d.name ?? '').toUpperCase().contains(nameContains.toUpperCase())) {
        match = d;
        break;
      }
    }
    if (match == null) {
      debugPrint('autoConnect: no paired device matching "$nameContains"');
      return false;
    }
    return connect(match);
  }

  /// Retries connecting to the last successfully connected device address.
  /// Use this after an unexpected drop, e.g. from a UI "Retry" button.
  Future<bool> reconnectToLast() async {
    if (_lastDeviceAddress == null) return false;
    final devices = await getPairedDevices();
    final match = devices
        .where((d) => d.address == _lastDeviceAddress)
        .firstOrNull;
    if (match == null) return false;
    return connect(match);
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _handleDisconnect();
  }

  /// Sends a command and waits for the matching ACK from the Arduino.
  /// Returns true ONLY if the ACK was actually received — not just that
  /// the write succeeded. Fixes the previous silent-false-positive bug.
  Future<bool> send(
    String command, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!_isConnected || _connection == null) return false;

    try {
      _pendingAckCommand = command;
      _pendingAck = Completer<bool>();

      _connection!.output.add(utf8.encode('$command\r\n'));
      await _connection!.output.allSent;

      return await _pendingAck!.future.timeout(timeout, onTimeout: () => false);
    } catch (_) {
      _handleDisconnect();
      return false;
    } finally {
      _pendingAck = null;
      _pendingAckCommand = null;
    }
  }

  void _handleIncomingData(Uint8List data) {
    _rxBuffer += utf8.decode(data, allowMalformed: true);
    while (_rxBuffer.contains('\n')) {
      final idx = _rxBuffer.indexOf('\n');
      final line = _rxBuffer.substring(0, idx).trim();
      _rxBuffer = _rxBuffer.substring(idx + 1);
      if (line.isEmpty) continue;
      _routeLine(line);
    }
  }

  void _routeLine(String line) {
    if (line.startsWith('DB:')) {
      final value = double.tryParse(line.substring(3));
      if (value != null) {
        _latestDb = value;
        notifyListeners();
      }
      return;
    }
    if (line.startsWith('ACK:')) {
      final acked = line.substring(4);
      if (_pendingAck != null &&
          !_pendingAck!.isCompleted &&
          _pendingAckCommand == acked) {
        _pendingAck!.complete(true);
      }
      return;
    }
  }

  void _handleDisconnect() {
    try {
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
    _isConnected = false;
    _isConnecting = false;
    _connectedDeviceName = null;
    if (_pendingAck != null && !_pendingAck!.isCompleted) {
      _pendingAck!.complete(false);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
