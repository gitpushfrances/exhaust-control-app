# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.4 patch 2] - Admin Reports Screen + GPS Smoothing + Speed Overlay

**Status:** ✅ COMPLETED — Jun 11, 2026

### 🎯 What This Phase Achieved:
Added a Reports tab to the Super Admin navigation with a barangay list screen and a detailed per-barangay report screen showing the assigned official, summary stats (riders passed, avg speed, avg dB, avg dB reduced), and per-session zone pass records with approach/entry/exit snapshot breakdown. Improved GPS update rate from 8 seconds to 250ms for smoother map movement. Added a live speed overlay (km/h) on the Rider map screen. Updated SpeedService polling to 250ms to match GPS rate.

### ✅ New Files

| File | Purpose |
|------|---------|
| `lib/screens/admin/admin_reports_screen.dart` | Reports tab — barangay list → detail with official info, summary cards, session records |

### ✅ Modified Files

#### `lib/screens/rider/map_screen.dart`
- **Updated:** `_startLocationStream()` — interval changed from 8s to 250ms, accuracy upgraded to `bestForNavigation`, `distanceFilter` set to 0
- **Added:** Speed overlay widget — live km/h display bottom-left of map, reads from `SpeedService.instance.currentKph`

#### `lib/services/speed_service.dart`
- **Updated:** Timer interval changed from 1 second to 250ms to match GPS update rate

#### `lib/screens/admin/admin_navigation_screen.dart`
- **Added import:** `admin_reports_screen.dart`
- **Added:** Reports `_NavItem` (bar chart icon) between Map and Profile tabs
- **Added:** `AdminReportsScreen()` to screens list

### 📝 Pending — Code Hygiene (tracked, not yet applied)
- `withOpacity` → `withValues()` — 8 instances across login, signup, splash, permission_handler, custom_button, custom_text_field
- `value` → `initialValue` — 4 instances in admin_create_official, admin_manage_officials
- `use_build_context_synchronously` — admin_create_official, barangay_notifications
- `curly_braces_in_flow_control_structures` — restricted_area.dart, admin_create_official
- `dangling_library_doc_comment` — geo_utils.dart
- `prefer_final_fields` — restricted_areas_provider
- `use_null_aware_elements` — admin_global_map_screen

---

## [0.7.4 patch 1] - Speed Tracking, Ride Session Logging & Speed Monitor

**Status:** ✅ COMPLETED — May 10, 2026

### 🎯 What This Phase Achieved:
Implemented a full speed tracking and ride session logging system. GPS speed is captured every second with a position-diff fallback when GPS speed is unavailable. Zone pass-throughs are recorded as ride sessions with 3 snapshots per zone (approach, entry, exit). Barangay Officials now have a Logs tab to view session data including average speed, decibel reduction (placeholder until IoT hardware arrives), and per-snapshot breakdowns. A live Speed Monitor screen was added to Super Admin Developer Tools for Lockito mock testing and real GPS speed validation.

### ✅ New Files

| File | Purpose |
|------|---------|
| `lib/services/speed_service.dart` | Singleton — GPS speed every second, position-diff fallback, rolling buffer, average calculator |
| `lib/models/ride_session.dart` | `RideSnapshot`, `RideSession` data models with `toMap()`/`fromMap()` |
| `lib/screens/barangay/barangay_ride_logs_screen.dart` | Logs tab for Barangay Official — streams sessions, shows speed/dB stats, snapshot breakdown |
| `lib/screens/test/speed_monitor_screen.dart` | Super Admin Dev Tools — live speed gauge, GPS vs fallback tag, last 20 readings log, clear button |

### ✅ Modified Files

#### `lib/services/firestore_service.dart`
- **Added import:** `ride_session.dart`
- **Added:** `createRideSession()` — creates a new `ride_sessions` doc, returns doc ID
- **Added:** `closeRideSession()` — updates session with avg speed, dB reduction, snapshots, end time
- **Added:** `streamRideSessions(barangayId)` — streams last 50 sessions for a barangay official
- **Added:** `streamRiderSessions(riderUid)` — streams last 50 sessions for a specific rider

#### `lib/providers/exhaust_provider.dart`
- **Added imports:** `SpeedService`, `FirestoreService`, `RideSession`, `RestrictedArea`
- **Added fields:** `_activeSessionId`, `_activeZoneId`, `_activeZoneName`, `_activeZoneBarangayId`, `_riderUid`, `_sessionSnapshots`, `_approachSnapshotTaken`, `_approachRadiusBuffer` (50m)
- **Added getter:** `currentSpeedKph` — reads from `SpeedService.instance`
- **Added:** `setRiderUid(uid)` — call after login to attach rider UID to session tracking
- **Modified:** `updateLocation()` — now accepts `nearestZone` + `distanceToZone`, starts speed tracking on first fix, fires approach snapshot at 50m buffer before zone edge
- **Modified:** `checkRestrictedAreaStatus()` — now accepts optional `zone` parameter; fires entry/exit snapshots, starts/closes Firestore session, clears speed buffer on entry
- **Added:** `_takeSnapshot()` — creates `RideSnapshot` at approach/entry/exit with current speed and dB placeholder
- **Added:** `_startSession()` — creates Firestore `ride_sessions` doc on zone entry
- **Added:** `_closeSession()` — closes session doc with avg speed, dB values, all snapshots on zone exit

#### `lib/screens/rider/map_screen.dart`
- **Added imports:** `SpeedService`, `RestrictedArea`, `dart:math`
- **Added:** `_haversineMeters()` helper — calculates distance between two GPS coordinates
- **Modified:** `_onPositionUpdate()` — feeds each position to `SpeedService.instance.onPositionUpdate()`
- **Modified:** `updateLocation()` call — now computes nearest zone + distance across all areas and passes them to `ExhaustProvider`

#### `lib/screens/barangay/barangay_navigation_screen.dart`
- **Added import:** `barangay_ride_logs_screen.dart`
- **Added:** Logs `_NavItem` (bar chart icon) between Alerts and Profile tabs
- **Added:** `BarangayRideLogsScreen()` to the screens list

#### `lib/screens/shared/shared_profile_screen.dart`
- **Added import:** `speed_monitor_screen.dart`
- **Added:** `_Divider()` + Speed Monitor `_ActionRow` under HC-05 row in Developer Tools section

#### `lib/main.dart`
- **Added import:** `speed_service.dart`
- **Added:** `ChangeNotifierProvider.value(value: SpeedService.instance)` to provider list

### ✅ Firestore

#### New Collection: `ride_sessions`
```
ride_sessions/{session_id}
├── rider_uid         string
├── zone_id           string
├── zone_name         string
├── barangay_id       string
├── started_at        string (ISO 8601)
├── ended_at          string (ISO 8601)
├── avg_speed_kph     number
├── decibel_before    number   ← 0.0 placeholder until IoT arrives
├── decibel_after     number   ← 0.0 placeholder until IoT arrives
├── decibel_reduced   number   ← calculated: before - after
└── snapshots         array
    └── { type, speed_kph, decibel_db, exhaust_state, zone_id, zone_name, timestamp }
```

#### New Composite Indexes
| Collection | Field 1 | Field 2 | Scope |
|---|---|---|---|
| `ride_sessions` | `barangay_id` ASC | `started_at` DESC | Collection |
| `ride_sessions` | `rider_uid` ASC | `started_at` DESC | Collection |

### 📝 Logging Strategy
| Trigger | What Is Logged |
|---------|----------------|
| 50m before zone edge | Approach snapshot — speed + dB + exhaust state |
| Zone entry | Entry snapshot — speed + dB + exhaust state; session doc created |
| Zone exit | Exit snapshot — speed + dB + exhaust state; session doc closed with averages |
| Every second always | Speed reading stored in `SpeedService` buffer (not written to Firestore per tick) |

### 📝 Notes
- Decibel readings are `0.0` placeholders throughout — IoT noise sensor hardware has not arrived yet. When it does, only `decibelDb: 0.0` in `exhaust_provider.dart → _takeSnapshot()` needs to be replaced with the live BT reading.
- `SpeedService` uses `geolocator` GPS speed (`m/s → km/h`). Falls back to Haversine position-diff calculation when GPS returns `-1`.
- Speed Monitor screen is Super Admin only — not visible to Rider or Barangay Official roles.
- `flutter analyze` — zero new errors. 21 pre-existing `info`-level warnings remain (tracked in tech debt — unchanged).

### 🗂️ Folder Impact
```
lib/
├── main.dart                                              ✅ UPDATED — SpeedService provider
├── models/
│   └── ride_session.dart                                  ✅ NEW
├── services/
│   ├── firestore_service.dart                             ✅ UPDATED — ride session methods
│   └── speed_service.dart                                 ✅ NEW
├── providers/
│   └── exhaust_provider.dart                              ✅ UPDATED — speed + snapshot wiring
├── screens/
│   ├── rider/
│   │   └── map_screen.dart                                ✅ UPDATED — SpeedService feed + zone distance
│   ├── barangay/
│   │   ├── barangay_navigation_screen.dart                ✅ UPDATED — Logs tab added
│   │   └── barangay_ride_logs_screen.dart                 ✅ NEW
│   ├── shared/
│   │   └── shared_profile_screen.dart                     ✅ UPDATED — Speed Monitor in Dev Tools
│   └── test/
│       └── speed_monitor_screen.dart                      ✅ NEW
```

---

## [0.7.3 patch 1] - Barangay Polygon Expansion

**Status:** ✅ COMPLETED — March 23, 2026

### 🎯 What This Phase Achieved:
Expanded the `/barangays` Firestore collection from 2 entries to 16 by seeding 14 Poblacion ward polygons for Guiuan, Eastern Samar. All polygon boundaries were manually created. Uploaded via the existing `add_barangay.js` Node.js seeding script.

### ✅ Barangays Seeded

| Document ID | Barangay | Points | Result |
|-------------|----------|--------|--------|
| guiuan-lupok | Lupok | 51 | Overwritten (re-upload) |
| guiuan-salug | Salug | 23 | Overwritten (re-upload) |
| guiuan-poblacion-ward-1 | Poblacion Ward 1 | 16 | New |
| guiuan-poblacion-ward-2 | Poblacion Ward 2 | 8 | New |
| guiuan-poblacion-ward-3 | Poblacion Ward 3 | 19 | New |
| guiuan-poblacion-ward-4 | Poblacion Ward 4 | 25 | Overwritten (was seeded earlier) |
| guiuan-poblacion-ward-4a | Poblacion Ward 4-A | 10 | New |
| guiuan-poblacion-ward-5 | Poblacion Ward 5 | 25 | New |
| guiuan-poblacion-ward-6 | Poblacion Ward 6 | 36 | New |
| guiuan-poblacion-ward-7 | Poblacion Ward 7 | 20 | New |
| guiuan-poblacion-ward-8 | Poblacion Ward 8 | 20 | New |
| guiuan-poblacion-ward-9 | Poblacion Ward 9 | 12 | New |
| guiuan-poblacion-ward-9a | Poblacion Ward 9-A | 16 | New |
| guiuan-poblacion-ward-10 | Poblacion Ward 10 | 30 | New |
| guiuan-poblacion-ward-11 | Poblacion Ward 11 | 35 | New |
| guiuan-poblacion-ward-12 | Poblacion Ward 12 | 19 | New |

### 🗂️ Folder Impact
> No Flutter code changes. All work was Firestore data seeding via Node.js script.

### 📝 Notes
- Polygon coordinates hand-crafted per barangay — no third-party GeoJSON source
- Script (`add_barangay.js`) overwrites existing documents safely — safe to re-run
- More barangays to be added incrementally as needed

---

## [0.7.3] - Phase 7.3: DC Motor Hardware Test + Relay Wiring Validation

**Status:** ✅ COMPLETED — March 21, 2026

### 🎯 What This Phase Achieved:
Validated DC motor spin control via single 5V relay module using a dedicated 9V battery as the motor power supply. Confirmed that the existing Arduino sketch (no code changes needed) can spin and stop a DC motor salvaged from an Epson printer using OPEN/CLOSE commands from the Flutter app over HC-05. This serves as the physical prototype foundation for the exhaust valve mechanism.

### ✅ Validation Results
- ✅ CLOSE command → relay energizes → motor spins confirmed
- ✅ OPEN command → relay de-energizes → motor stops confirmed
- ✅ Dedicated 9V battery successfully powers motor without affecting Arduino
- ✅ Shared ground between 9V battery and Arduino confirmed working
- ⚠️ Single relay = spin/stop only — no direction reversal possible with current setup

### 🗂️ Folder Impact
> No Flutter code changes this session. All work was hardware wiring and validation.

---

## [0.7.2] - Phase 7.2: UI Hardening, Dev Tool Relocation & Dashboard Cleanup

**Status:** ✅ COMPLETED — March 21, 2026

### 🎯 What This Phase Achieved:
Cleaned up the rider dashboard by fully removing the temporary HC-05 dev test shortcut. Relocated the hardware test screen exclusively to the Super Admin profile under a new "Developer Tools" section. Fixed a stray brace compile error introduced during the removal. Verified zero errors on `flutter analyze` before pushing.

### ✅ Modified Files
- `shared_profile_screen.dart` — Added Developer Tools section (superadmin only), HC-05 ActionRow, version bump v0.7.0 → v0.7.1
- `dashboard_screen.dart` — Removed `_DevTestButton` widget, import, and class entirely. Fixed stray `}` compile error.

---

## [0.7.1] - Phase 7.1: HC-05 Classic Bluetooth Hardware Validation

**Status:** ✅ COMPLETED — March 19, 2026

### 🎯 What This Phase Achieved:
Validated full two-way Classic Bluetooth communication between Flutter app and Arduino Uno via HC-05 module. Confirmed relay actuation from Flutter app. Unblocked Phase 8 hardware automation.

### ✅ Validation Results
- ✅ Flutter → HC-05 → Arduino: HELLO, OPEN, CLOSE received correctly
- ✅ Arduino → HC-05 → Flutter: ACK responses displayed in app serial log
- ✅ Relay clicks on CLOSE, releases on OPEN
- ✅ Full two-way communication confirmed at 9600 baud

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~98% of phase complete)
**Date Started:** March 2026

### 🎯 What This Phase Achieved:
Expanded from single-role rider app to full 3-role system. Adds Admin screens (dashboard, inbox, officials, global map), Barangay Official screens (dashboard, submit, history, notifications), barangay boundary enforcement, and in-app notification system.

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.19** — Firestore security rules (HIGH RISK — do last before demo)
- [ ] **7.20** — FCM push notifications (optional)

---

## [0.6.1] - Phase 6 Patches & Background GPS
**Status:** ✅ COMPLETED — March 5, 2026

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding
**Status:** ✅ COMPLETED — February 17, 2026

## [0.4.0] - Phase 4: Bluetooth Hardware Integration
**Status:** ✅ COMPLETED — February 17, 2026

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI
**Status:** ✅ COMPLETED — February 11, 2026

## [0.2.0] - Phase 2: Dashboard & Navigation
**Status:** ✅ COMPLETED — February 11, 2026

## [0.1.0] - Phase 1: UI/UX Foundation & Branding
**Status:** 🔄 80% Complete — logo integration pending

## [0.0.1] - Core Foundation
**Status:** ✅ COMPLETED

---

## 📈 Version History Summary

| Version | Phase | Status | Date |
|---------|-------|--------|------|
| 0.0.1 | Foundation | ✅ Complete | Before Feb 11 |
| 0.1.0 | UI/UX | 🔄 80% | Feb 11, 2026 |
| 0.2.0 | Navigation | ✅ Complete | Feb 11, 2026 |
| 0.3.0 | Permissions | ✅ Complete | Feb 11, 2026 |
| 0.4.0 | Bluetooth | ✅ Complete | Feb 17, 2026 |
| 0.5.0 | GPS | ✅ Complete | Feb 17, 2026 |
| 0.6.0 | Map | ✅ Complete | Feb 17, 2026 |
| 0.6.1 | Patches & Background GPS | ✅ Complete | Mar 5, 2026 |
| 0.7.0 (patch 1) | Multi-Role Foundation + Admin/Barangay Screens | ✅ Complete | Mar 9, 2026 |
| 0.7.0 (patch 2) | Notifications, UI/UX Polish, Pro Nav, Profile Redesign | ✅ Complete | Mar 15, 2026 |
| 0.7.0 (patch 3) | Barangay Geofencing + Manual Polygon Seeding + Boundary Check | ✅ Complete | Mar 18, 2026 |
| 0.7.1 | HC-05 Classic BT Validation + Relay Test | ✅ Complete | Mar 19, 2026 |
| 0.7.2 | Dev Tool Relocation + Rider Dashboard Cleanup | ✅ Complete | Mar 21, 2026 |
| 0.7.3 | DC Motor Spin Test + Relay Wiring Validation | ✅ Complete | Mar 21, 2026 |
| 0.7.3 patch 1 | Barangay Polygon Expansion — 16 barangays seeded | ✅ Complete | Mar 23, 2026 |
| **0.7.4 patch 1** | **Speed Tracking + Ride Session Logging + Speed Monitor Dev Tool** | **✅ Complete** | **May 10, 2026** |
| **0.7.4 patch 2** | **Admin Reports Screen + Nav Tab + Code Cleanup (pending)** | **✅ Complete** | **Jun 11, 2026** |
| 0.7.4 | Second Relay + Solder + CW/CCW Direction Control | 🟡 Next (hardware) | TBD |
| 0.8.0 | Core HC-105 Automation (geofence → relay → motor) | ⏳ Pending | TBD |

---

**Maintained by:** Development Team
**Last Updated:** May 10, 2026