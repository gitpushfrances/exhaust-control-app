import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Isolated HC-05 Classic Bluetooth test screen.
/// Not wired to any provider — standalone test only.
/// Remove or hide this screen after hardware validation is complete.
class BtClassicTestScreen extends StatefulWidget {
  const BtClassicTestScreen({super.key});

  @override
  State<BtClassicTestScreen> createState() => _BtClassicTestScreenState();
}

class _BtClassicTestScreenState extends State<BtClassicTestScreen> {
  BluetoothConnection? _connection;
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnecting = false;
  bool _isConnected = false;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _loadPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() => _pairedDevices = devices);
    } catch (e) {
      _appendLog('Error loading devices: $e');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      final conn = await BluetoothConnection.toAddress(device.address);

      setState(() {
        _connection = conn;
        _isConnecting = false;
        _isConnected = true;
      });

      _appendLog('Connected to ${device.name}');

      conn.input!.listen(
        (data) {
          final response = utf8.decode(data).trim();
          if (response.isNotEmpty) _appendLog('Arduino → $response');
        },
        onDone: () {
          setState(() => _isConnected = false);
          _appendLog('Disconnected');
        },
        onError: (e) {
          _appendLog('Stream error: $e');
        },
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _selectedDevice = null;
      });
      _appendLog('Connection failed: $e');
    }
  }

  Future<void> _disconnect() async {
    await _connection?.close();
    setState(() {
      _connection = null;
      _isConnected = false;
      _selectedDevice = null;
    });
    _appendLog('Disconnected');
  }

  Future<void> _send(String command) async {
    if (_connection == null || !_isConnected) {
      _appendLog('Not connected');
      return;
    }
    try {
      _connection!.output.add(utf8.encode('$command\r\n'));
      await _connection!.output.allSent;
      _appendLog('Flutter → $command');
    } catch (e) {
      _appendLog('Send error: $e');
    }
  }

  void _appendLog(String message) {
    setState(() => _log.insert(0, message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'HC-05 BT Test',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          if (_isConnected)
            TextButton(
              onPressed: _disconnect,
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            color: _isConnected
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _isConnected
                  ? '● Connected — ${_selectedDevice?.name ?? ''}'
                  : _isConnecting
                  ? '● Connecting...'
                  : '● Not Connected',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device list — only shown when not connected
                  if (!_isConnected) ...[
                    const Text(
                      'Paired Devices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_pairedDevices.isEmpty)
                      _InfoBanner(
                        message:
                            'No paired devices found.\nPair your HC-05 from phone Bluetooth Settings first (PIN: 1234).',
                        color: const Color(0xFFFEF3C7),
                        borderColor: const Color(0xFFF59E0B),
                        textColor: const Color(0xFF92400E),
                      )
                    else
                      ..._pairedDevices.map(
                        (device) => _DeviceTile(
                          device: device,
                          isConnecting:
                              _isConnecting &&
                              _selectedDevice?.address == device.address,
                          onTap: _isConnecting ? null : () => _connect(device),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loadPairedDevices,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Command buttons — only shown when connected
                  if (_isConnected) ...[
                    const Text(
                      'Send Command',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CommandButton(
                            label: 'HELLO',
                            color: const Color(0xFF3B82F6),
                            onPressed: () => _send('HELLO'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CommandButton(
                            label: 'OPEN',
                            color: const Color(0xFF10B981),
                            onPressed: () => _send('OPEN'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CommandButton(
                            label: 'CLOSE',
                            color: const Color(0xFFEF4444),
                            onPressed: () => _send('CLOSE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Serial Log',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_log.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _log.clear()),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _log.isEmpty
                        ? const Text(
                            'Log will appear here...',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _log
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      entry,
                                      style: TextStyle(
                                        color: entry.startsWith('Arduino')
                                            ? const Color(0xFF34D399)
                                            : entry.startsWith('Flutter')
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF9CA3AF),
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _DeviceTile({
    required this.device,
    required this.isConnecting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bluetooth,
            color: Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        title: Text(
          device.name ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          device.address,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B82F6),
                ),
              )
            : const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        onTap: onTap,
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CommandButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;
  final Color borderColor;
  final Color textColor;

  const _InfoBanner({
    required this.message,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
      ),
    );
  }
}
