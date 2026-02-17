import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

/// Bluetooth Connection Modal - Shows device list and connection options
class BluetoothConnectionModal extends StatefulWidget {
  const BluetoothConnectionModal({super.key});

  @override
  State<BluetoothConnectionModal> createState() =>
      _BluetoothConnectionModalState();
}

class _BluetoothConnectionModalState extends State<BluetoothConnectionModal> {
  bool _isScanning = false;

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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth,
                    color: Color(0xFF3B82F6),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Connect Device',
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

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PairedDevicesSection(
                      onScanPressed: () {
                        setState(() => _isScanning = true);
                        context.read<BluetoothProvider>().scanForDevices().then(
                          (_) => setState(() => _isScanning = false),
                        );
                      },
                      isScanning: _isScanning,
                    ),
                    const SizedBox(height: 24),
                    _AvailableDevicesSection(isScanning: _isScanning),
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

/// Paired Devices Section
class _PairedDevicesSection extends StatelessWidget {
  final VoidCallback onScanPressed;
  final bool isScanning;

  const _PairedDevicesSection({
    required this.onScanPressed,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Previously Paired',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            TextButton.icon(
              onPressed: isScanning ? null : onScanPressed,
              icon: Icon(
                isScanning ? Icons.refresh : Icons.bluetooth_searching,
                size: 18,
              ),
              label: Text(isScanning ? 'Scanning...' : 'Scan'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bluetoothProvider.pairedDevices.isEmpty)
          _EmptyState(
            icon: Icons.bluetooth_disabled,
            message: 'No paired devices',
          )
        else
          ...bluetoothProvider.pairedDevices.map(
            (device) => _DeviceListItem(device: device, isPaired: true),
          ),
      ],
    );
  }
}

/// Available Devices Section
class _AvailableDevicesSection extends StatelessWidget {
  final bool isScanning;

  const _AvailableDevicesSection({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Devices',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (isScanning)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Scanning for devices...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          )
        else if (bluetoothProvider.availableDevices.isEmpty)
          _EmptyState(
            icon: Icons.search_off,
            message: 'No devices found',
            subtitle: 'Tap "Scan" to search',
          )
        else
          ...bluetoothProvider.availableDevices.map(
            (device) => _DeviceListItem(device: device, isPaired: false),
          ),
      ],
    );
  }
}

/// Device List Item
class _DeviceListItem extends StatelessWidget {
  final Map<String, dynamic> device;
  final bool isPaired;

  const _DeviceListItem({required this.device, required this.isPaired});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final isCurrentDevice = bluetoothProvider.connectedDeviceId == device['id'];
    final isConnecting = bluetoothProvider.isConnecting;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentDevice
            ? const Color(0xFF10B981).withOpacity(0.05)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentDevice
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
          width: isCurrentDevice ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isConnecting
              ? null
              : () async {
                  final success = await bluetoothProvider.connectToDevice(
                    device['id'],
                    device['name'],
                  );

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Connected successfully'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✕ Connection failed. Try again.'),
                          backgroundColor: Color(0xFFEF4444),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Device Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_remote,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name'] ?? 'Unknown Device',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isPaired)
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                          if (isPaired) const SizedBox(width: 4),
                          Text(
                            isPaired ? 'Paired' : device['id'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Signal Strength
                Column(
                  children: [
                    Icon(
                      _getSignalIcon(device['signalStrength'] ?? 0),
                      size: 18,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device['signalStrength'] ?? 0}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Connect Button
                if (isCurrentDevice && bluetoothProvider.isConnected)
                  Container(
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
                else
                  ElevatedButton(
                    onPressed: isConnecting
                        ? null
                        : () async {
                            final success = await bluetoothProvider
                                .connectToDevice(device['id'], device['name']);
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Connected successfully'),
                                    backgroundColor: Color(0xFF10B981),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '✕ Connection failed. Try again.',
                                    ),
                                    backgroundColor: Color(0xFFEF4444),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
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
                    child: Text(
                      isPaired ? 'RECONNECT' : 'CONNECT',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSignalIcon(int strength) {
    if (strength >= 75) return Icons.signal_cellular_alt;
    if (strength >= 50) return Icons.signal_cellular_alt_2_bar;
    if (strength >= 25) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_cellular_connected_no_internet_0_bar;
  }
}

/// Empty State Widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ],
      ),
    );
  }
}
