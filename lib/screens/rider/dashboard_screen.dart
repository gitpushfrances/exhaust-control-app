import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/exhaust_provider.dart';
import '../../widgets/bluetooth_connection_modal.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BluetoothConnectionCard(),
            const SizedBox(height: 16),
            _ExhaustStatusCard(),
            const SizedBox(height: 16),
            _QuickActionsSection(),
            const SizedBox(height: 16),
            _LocationInfoCard(),
            const SizedBox(height: 16),
            // TODO: REMOVE BEFORE PRODUCTION — HC-05 hardware test
          ],
        ),
      ),
    );
  }
}

class _BluetoothConnectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bluetoothProvider.isConnected
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const BluetoothConnectionModal(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bluetoothProvider.isConnected
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    bluetoothProvider.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: bluetoothProvider.isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bluetoothProvider.isConnected
                            ? 'Connected'
                            : bluetoothProvider.isConnecting
                            ? 'Connecting...'
                            : 'Not Connected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bluetoothProvider.isConnected
                            ? bluetoothProvider.connectedDeviceName ??
                                  'Unknown Device'
                            : 'Tap to connect device',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (bluetoothProvider.isConnected)
                  Column(
                    children: [
                      Icon(
                        _getSignalIcon(bluetoothProvider.signalStrength),
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bluetoothProvider.signalStrength}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
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

class _ExhaustStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final color = _getStatusColor(exhaustProvider.currentState);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Compact horizontal status row
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(exhaustProvider.currentState),
                  size: 26,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXHAUST STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exhaustProvider.stateLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      exhaustProvider.stateDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // Auto mode toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    exhaustProvider.isAutoMode
                        ? Icons.autorenew
                        : Icons.pan_tool_outlined,
                    size: 18,
                    color: const Color(0xFF374151),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exhaustProvider.isAutoMode ? 'Auto Mode' : 'Manual Mode',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              Switch(
                value: exhaustProvider.isAutoMode,
                activeColor: const Color(0xFF3B82F6),
                onChanged: bluetoothProvider.isConnected
                    ? (value) => exhaustProvider.toggleAutoMode()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExhaustState state) {
    switch (state) {
      case ExhaustState.open:
        return const Color(0xFF10B981);
      case ExhaustState.closed:
        return const Color(0xFFEF4444);
      case ExhaustState.inactive:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(ExhaustState state) {
    switch (state) {
      case ExhaustState.open:
        return Icons.volume_up;
      case ExhaustState.closed:
        return Icons.volume_off;
      case ExhaustState.inactive:
        return Icons.power_settings_new;
    }
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final isEnabled =
        bluetoothProvider.isConnected && !exhaustProvider.isAutoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Open Exhaust',
                icon: Icons.volume_up,
                color: const Color(0xFF10B981),
                onPressed: isEnabled
                    ? () => exhaustProvider.openExhaust()
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Close Exhaust',
                icon: Icons.volume_off,
                color: const Color(0xFFEF4444),
                onPressed: isEnabled
                    ? () => exhaustProvider.closeExhaust()
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null ? color : const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: onPressed != null
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exhaustProvider.currentLocation ?? 'Location unavailable',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (exhaustProvider.isInRestrictedArea)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'RESTRICTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
