import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/classic_bluetooth_service.dart';

class BluetoothConnectionModal extends StatefulWidget {
  const BluetoothConnectionModal({super.key});

  @override
  State<BluetoothConnectionModal> createState() =>
      _BluetoothConnectionModalState();
}

class _BluetoothConnectionModalState extends State<BluetoothConnectionModal> {
  List<BluetoothDevice> _pairedDevices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await ClassicBluetoothService.instance.getPairedDevices();
      if (mounted) {
        setState(() {
          _pairedDevices = devices;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_searching,
                    color: Color(0xFF3B82F6),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Connect HC-05',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paired Devices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _loadDevices,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_pairedDevices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'No paired devices found.\nPair your HC-05 from phone Bluetooth Settings first (PIN: 1234).',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      ..._pairedDevices.map(
                        (device) => _DeviceTile(
                          device: device,
                          onConnected: () => Navigator.pop(context),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onConnected;

  const _DeviceTile({required this.device, required this.onConnected});

  @override
  State<_DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<_DeviceTile> {
  bool _isConnecting = false;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final success = await ClassicBluetoothService.instance.connect(
      widget.device,
    );
    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ HC-05 connected'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
      widget.onConnected();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✕ Connection failed. Check HC-05 is powered on.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = context.watch<ClassicBluetoothService>();
    final isThisDeviceConnected =
        btService.isConnected &&
        btService.connectedDeviceName == widget.device.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isThisDeviceConnected
            ? const Color(0xFF10B981).withValues(alpha: 0.05)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisDeviceConnected
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
          width: isThisDeviceConnected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          widget.device.name ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          widget.device.address,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        trailing: isThisDeviceConnected
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CONNECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : _isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B82F6),
                ),
              )
            : ElevatedButton(
                onPressed: btService.isConnecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CONNECT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
