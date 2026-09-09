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

  // Continuous keep-alive — runs any time we're connected, not just
  // inside a restricted zone. Some OEM Bluetooth stacks tear down an
  // SPP socket they judge "idle" from the phone's side even while the
  // Arduino is still streaming data the other way.
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 3);

  // Set by disconnect() so _handleDisconnect() knows not to
  // auto-reconnect after a deliberate user-initiated disconnect.
  bool _manualDisconnect = false;

  // Bounded, backed-off auto-reconnect after an unexpected drop.
  static const int _maxAutoReconnectAttempts = 4;

  // Serializes concurrent send() calls so two overlapping commands
  // (fast double-tap, or a manual command racing an automatic zone
  // command) can't stomp on the single _pendingAck/_pendingAckCommand
  // pair below.
  Future<void> _sendChain = Future.value();

  bool _isSending = false;
  bool get isSending => _isSending;

  double? _latestDb;
  double? get latestDb => _latestDb;

  // Rolling dB buffer for the current phase (approach/inside/exiting).
  // Captured via averageDb then cleared at each zone-event boundary —
  // mirrors SpeedService's buffer/averageKph pattern.
  final List<double> _dbBuffer = [];

  double get averageDb {
    if (_dbBuffer.isEmpty) return 0.0;
    return _dbBuffer.reduce((a, b) => a + b) / _dbBuffer.length;
  }

  void clearDbBuffer() => _dbBuffer.clear();

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
        _manualDisconnect = false;
        _startHeartbeat();

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
    _manualDisconnect = true;
    await _connection?.close();
    _handleDisconnect();
  }

  /// Fire-and-forget send — no reply expected or awaited. Only appropriate
  /// for signals the Arduino never confirms (currently: the ZPING
  /// heartbeat). Returns true if the write was attempted while connected —
  /// NOT delivery or execution confirmation, just "we were connected and
  /// the write didn't throw."
  Future<bool> sendRaw(String command) async {
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

  /// Maps an outgoing command to the exact line Arduino sends back once
  /// it's actually done — not the immediate ACK:<direction> that fires
  /// the instant the motor starts moving. INSIDE/OUTSIDE/OPEN/CLOSE all
  /// route through the same timed 45-degree rotation on the Arduino now,
  /// so their real completion signal is DONE:<direction>. STOP has no
  /// rotation to wait for, so its immediate ACK is already correct.
  String _expectedReplyFor(String command) {
    switch (command) {
      case 'INSIDE':
      case 'CLOSE':
        return 'DONE:CLOSE';
      case 'OUTSIDE':
      case 'OPEN':
        return 'DONE:OPEN';
      case 'STOP':
        return 'ACK:STOP';
      default:
        return 'ACK:$command';
    }
  }

  /// Sends a command and waits for its matching confirmation line (see
  /// _expectedReplyFor). Returns true ONLY if that exact line arrived
  /// before [timeout] — not just that the write succeeded.
  /// Public entry point — chains calls through [_sendChain] so two
  /// overlapping commands can't share/clobber the single
  /// _pendingAck/_pendingAckCommand pair below.
  Future<bool> send(
    String command, {
    Duration timeout = const Duration(milliseconds: 1800),
  }) {
    final result = _sendChain.then((_) => _sendInternal(command, timeout));
    _sendChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _sendInternal(String command, Duration timeout) async {
    if (!_isConnected || _connection == null) return false;

    _isSending = true;
    notifyListeners();
    try {
      _pendingAckCommand = _expectedReplyFor(command);
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
      _isSending = false;
      notifyListeners();
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
        _dbBuffer.add(value);
        notifyListeners();
      }
      return;
    }
    if (line.startsWith('ACK:') || line.startsWith('DONE:')) {
      // Tolerant match: endsWith instead of exact equality. A single
      // corrupted/dropped leading byte on this link (confirmed in field
      // testing) used to make an otherwise-valid "DONE:OPEN" line
      // silently fail the old `==` check and eat the full timeout.
      if (_pendingAck != null &&
          !_pendingAck!.isCompleted &&
          _pendingAckCommand != null &&
          line.endsWith(_pendingAckCommand!)) {
        _pendingAck!.complete(true);
      }
      return;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      sendRaw('ZPING');
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handleDisconnect() {
    _stopHeartbeat();
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

    final wasManual = _manualDisconnect;
    _manualDisconnect = false;
    if (!wasManual) {
      _attemptAutoReconnect();
    }
  }

  /// Bounded, backed-off reconnect loop after an unexpected drop.
  /// No-ops if the user explicitly disconnected, or if a connect is
  /// already underway / already succeeded by the time a step runs.
  Future<void> _attemptAutoReconnect() async {
    if (_lastDeviceAddress == null) return;
    for (int attempt = 1; attempt <= _maxAutoReconnectAttempts; attempt++) {
      if (_isConnected || _isConnecting) return;
      final delay = Duration(seconds: 2 * attempt);
      debugPrint(
        'Auto-reconnect attempt $attempt/$_maxAutoReconnectAttempts in ${delay.inSeconds}s',
      );
      await Future.delayed(delay);
      if (_isConnected || _isConnecting) return;
      final ok = await reconnectToLast();
      if (ok) {
        debugPrint('Auto-reconnect succeeded on attempt $attempt');
        return;
      }
    }
    debugPrint(
      'Auto-reconnect: giving up after $_maxAutoReconnectAttempts attempts',
    );
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _connection?.dispose();
    super.dispose();
  }
}
