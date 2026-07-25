import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exhaust_provider.dart';
import '../../services/classic_bluetooth_service.dart';
import '../../services/speed_service.dart';
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
          ],
        ),
      ),
    );
  }
}

class _BluetoothConnectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final btService = context.watch<ClassicBluetoothService>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: btService.isConnected
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
          onTap: btService.isConnected
              ? null
              : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BluetoothConnectionModal(),
                ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: btService.isConnected
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    btService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: btService.isConnected
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
                        btService.isConnected
                            ? 'Connected'
                            : btService.isConnecting
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
                        btService.isConnected
                            ? btService.connectedDeviceName ?? 'HC-05'
                            : 'Tap to connect HC-05',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (btService.isConnected)
                  IconButton(
                    icon: const Icon(
                      Icons.bluetooth_disabled,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Disconnect',
                    onPressed: () =>
                        context.read<ClassicBluetoothService>().disconnect(),
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
}

class _ExhaustStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final exhaustProvider = context.watch<ExhaustProvider>();
    final btService = context.watch<ClassicBluetoothService>();
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
                activeThumbColor: const Color(0xFF3B82F6),
                onChanged: btService.isConnected
                    ? (_) => exhaustProvider.toggleAutoMode()
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
    final btService = context.watch<ClassicBluetoothService>();
    final isEnabled = btService.isConnected && !exhaustProvider.isAutoMode;

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
                isActive: exhaustProvider.isOpen,
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
                isActive: exhaustProvider.isClosed,
                onPressed: isEnabled
                    ? () => exhaustProvider.closeExhaust()
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _LiveTelemetryCard(),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    // Lit when this is the button matching the real exhaust state; dimmed
    // otherwise. Disabled (no BT / auto mode on) always shows the flat
    // grey regardless of state.
    final bg = disabled
        ? const Color(0xFFE5E7EB)
        : widget.isActive
        ? widget.color
        : widget.color.withValues(alpha: 0.12);
    final fg = disabled
        ? const Color(0xFF9CA3AF)
        : widget.isActive
        ? Colors.white
        : widget.color;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(widget.icon, color: fg, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveTelemetryCard extends StatelessWidget {
  const _LiveTelemetryCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SpeedService.instance,
      builder: (context, _) {
        final speed = SpeedService.instance.currentKph;
        final db = SpeedService.instance.currentDb;
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
              Expanded(
                child: _TelemetryStat(
                  icon: Icons.speed,
                  label: 'SPEED',
                  value: speed.toStringAsFixed(0),
                  unit: 'km/h',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFF3F4F6)),
              Expanded(
                child: _TelemetryStat(
                  icon: Icons.graphic_eq,
                  label: 'NOISE',
                  value: db.toStringAsFixed(0),
                  unit: 'dB',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TelemetryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _TelemetryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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
