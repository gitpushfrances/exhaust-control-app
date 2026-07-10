import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/speed_service.dart';

class SpeedMonitorScreen extends StatefulWidget {
  const SpeedMonitorScreen({super.key});

  @override
  State<SpeedMonitorScreen> createState() => _SpeedMonitorScreenState();
}

class _SpeedMonitorScreenState extends State<SpeedMonitorScreen> {
  final SpeedService _speed = SpeedService.instance;
  final List<SpeedReading> _log = [];
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _speed.startTracking();
    // Refresh UI every second and capture reading into local log
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final latest = _speed.latest;
      if (latest != null && mounted) {
        setState(() {
          _log.insert(0, latest);
          if (_log.length > 20) _log.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    // Do NOT stop SpeedService here — it may be needed by ExhaustProvider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _speed.currentKph;
    final avg = _speed.averageKph;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Speed Monitor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _speed.clearBuffer();
              setState(() => _log.clear());
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Live Speed Card ──────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'CURRENT SPEED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  current.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: 'Avg',
                      value: '${avg.toStringAsFixed(1)} km/h',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Source',
                      value: (_speed.latest?.usedFallback == true)
                          ? 'Fallback'
                          : 'GPS',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Readings',
                      value: '${_speed.buffer.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Log header ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: const [
                Text(
                  'RECENT READINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // ── Log list ─────────────────────────────────────
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for GPS signal…',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _log.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _LogRow(reading: _log[i]),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final SpeedReading reading;
  const _LogRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final isFallback = reading.usedFallback;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFallback
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isFallback ? 'FALLBACK' : 'GPS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isFallback
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${reading.kph.toStringAsFixed(1)} km/h',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          Text(
            '${reading.timestamp.hour.toString().padLeft(2, '0')}:'
            '${reading.timestamp.minute.toString().padLeft(2, '0')}:'
            '${reading.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
