/// Snapshot types for zone events
enum SnapshotType { approach, entry, exit }

/// A single point-in-time reading at a zone event
class RideSnapshot {
  final SnapshotType type;
  final double speedKph;
  final double decibelDb; // 0.0 placeholder until IoT arrives
  final String exhaustState; // 'open' | 'closed'
  final String zoneId;
  final String zoneName;
  final DateTime timestamp;

  const RideSnapshot({
    required this.type,
    required this.speedKph,
    required this.decibelDb,
    required this.exhaustState,
    required this.zoneId,
    required this.zoneName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'speed_kph': speedKph,
    'decibel_db': decibelDb,
    'exhaust_state': exhaustState,
    'zone_id': zoneId,
    'zone_name': zoneName,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RideSnapshot.fromMap(Map<String, dynamic> m) => RideSnapshot(
    type: SnapshotType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => SnapshotType.entry,
    ),
    speedKph: (m['speed_kph'] ?? 0).toDouble(),
    decibelDb: (m['decibel_db'] ?? 0).toDouble(),
    exhaustState: m['exhaust_state'] ?? 'open',
    zoneId: m['zone_id'] ?? '',
    zoneName: m['zone_name'] ?? '',
    timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
  );
}

/// A ride session groups snapshots + speed logs for one zone pass
class RideSession {
  final String id;
  final String riderUid;
  final String zoneId;
  final String zoneName;
  final String barangayId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double avgSpeedKph;
  final double decibelBefore; // approach snapshot dB
  final double decibelAfter; // exit snapshot dB
  final double decibelReduced; // calculated: before - after

  // Phase-windowed averages — mean of every 200ms reading collected
  // during each phase, not a single instantaneous point read.
  final double decibelAvgApproach;
  final double decibelAvgInside;
  final double decibelAvgExiting;
  final double speedAvgApproach;
  final double speedAvgInside;
  final double speedAvgExiting;

  final List<RideSnapshot> snapshots;

  const RideSession({
    required this.id,
    required this.riderUid,
    required this.zoneId,
    required this.zoneName,
    required this.barangayId,
    required this.startedAt,
    this.endedAt,
    this.avgSpeedKph = 0.0,
    this.decibelBefore = 0.0,
    this.decibelAfter = 0.0,
    this.decibelReduced = 0.0,
    this.decibelAvgApproach = 0.0,
    this.decibelAvgInside = 0.0,
    this.decibelAvgExiting = 0.0,
    this.speedAvgApproach = 0.0,
    this.speedAvgInside = 0.0,
    this.speedAvgExiting = 0.0,
    this.snapshots = const [],
  });

  factory RideSession.fromMap(String id, Map<String, dynamic> m) {
    final rawSnaps = m['snapshots'] as List? ?? [];
    final snapshots = rawSnaps
        .map((s) => RideSnapshot.fromMap(Map<String, dynamic>.from(s)))
        .toList();

    return RideSession(
      id: id,
      riderUid: m['rider_uid'] ?? '',
      zoneId: m['zone_id'] ?? '',
      zoneName: m['zone_name'] ?? '',
      barangayId: m['barangay_id'] ?? '',
      startedAt: DateTime.tryParse(m['started_at'] ?? '') ?? DateTime.now(),
      endedAt: m['ended_at'] != null ? DateTime.tryParse(m['ended_at']) : null,
      avgSpeedKph: (m['avg_speed_kph'] ?? 0).toDouble(),
      decibelBefore: (m['decibel_before'] ?? 0).toDouble(),
      decibelAfter: (m['decibel_after'] ?? 0).toDouble(),
      decibelReduced: (m['decibel_reduced'] ?? 0).toDouble(),
      decibelAvgApproach: (m['decibel_avg_approach'] ?? 0).toDouble(),
      decibelAvgInside: (m['decibel_avg_inside'] ?? 0).toDouble(),
      decibelAvgExiting: (m['decibel_avg_exiting'] ?? 0).toDouble(),
      speedAvgApproach: (m['speed_avg_approach'] ?? 0).toDouble(),
      speedAvgInside: (m['speed_avg_inside'] ?? 0).toDouble(),
      speedAvgExiting: (m['speed_avg_exiting'] ?? 0).toDouble(),
      snapshots: snapshots,
    );
  }

  Map<String, dynamic> toMap() => {
    'rider_uid': riderUid,
    'zone_id': zoneId,
    'zone_name': zoneName,
    'barangay_id': barangayId,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'avg_speed_kph': avgSpeedKph,
    'decibel_before': decibelBefore,
    'decibel_after': decibelAfter,
    'decibel_reduced': decibelReduced,
    'decibel_avg_approach': decibelAvgApproach,
    'decibel_avg_inside': decibelAvgInside,
    'decibel_avg_exiting': decibelAvgExiting,
    'speed_avg_approach': speedAvgApproach,
    'speed_avg_inside': speedAvgInside,
    'speed_avg_exiting': speedAvgExiting,
    'snapshots': snapshots.map((s) => s.toMap()).toList(),
  };
}
