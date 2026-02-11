import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/exhaust_provider.dart';
import '../widgets/bluetooth_connection_modal.dart';

/// Dashboard Screen - Main screen showing exhaust status and controls
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Gray 50
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
        actions: [
          // Notification Icon
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF6B7280),
            ),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bluetooth Connection Card
            _BluetoothConnectionCard(),
            const SizedBox(height: 16),

            // Exhaust Status Card
            _ExhaustStatusCard(),
            const SizedBox(height: 16),

            // Quick Actions
            _QuickActionsSection(),
            const SizedBox(height: 16),

            // Location Info Card
            _LocationInfoCard(),
            const SizedBox(height: 16),

            // Statistics Summary
            _StatisticsSummaryCard(),
          ],
        ),
      ),
    );
  }
}

/// Bluetooth Connection Status Card
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
              ? const Color(0xFF10B981) // Success Green
              : const Color(0xFFEF4444), // Alert Red
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                // Bluetooth Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bluetoothProvider.isConnected
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
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

                // Status Text
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

                // Signal Strength or Arrow
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

/// Exhaust Status Card - Main status display
class _ExhaustStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status Label
          Text(
            'EXHAUST STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Large Status Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _getStatusColor(
                exhaustProvider.currentState,
              ).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(exhaustProvider.currentState),
              size: 64,
              color: _getStatusColor(exhaustProvider.currentState),
            ),
          ),
          const SizedBox(height: 24),

          // Status Text
          Text(
            exhaustProvider.stateLabel,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(exhaustProvider.currentState),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exhaustProvider.stateDescription,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          // Auto Mode Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      exhaustProvider.isAutoMode
                          ? Icons.autorenew
                          : Icons.pan_tool_outlined,
                      size: 20,
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
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExhaustState state) {
    switch (state) {
      case ExhaustState.open:
        return const Color(0xFF10B981); // Success Green
      case ExhaustState.closed:
        return const Color(0xFFEF4444); // Alert Red
      case ExhaustState.inactive:
        return const Color(0xFF9CA3AF); // Gray 400
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

/// Quick Actions Section
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

/// Location Info Card
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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                color: const Color(0xFFEF4444).withOpacity(0.1),
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

/// Statistics Summary Card
class _StatisticsSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Trips',
                  value: '${exhaustProvider.totalTrips}',
                  icon: Icons.route,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Auto Closures',
                  value: '${exhaustProvider.autoClosures}',
                  icon: Icons.auto_awesome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF3B82F6)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
