# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** Jun 11, 2026

---

## 🎯 Overall Progress: ~95% Complete

> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Phase 7 is ~98% done. HC-05 hardware validated — relay clicks on OPEN/CLOSE.
> DC motor spin test completed — motor spins and stops via CLOSE/OPEN from Flutter app.
> Barangay polygon seeding expanded to 16 barangays — all manually created, no third-party source.
> Speed tracking + ride session logging added — SpeedService, RideSession, Barangay Logs tab, Speed Monitor Dev Tool.
> IoT decibel sensor hardware not yet arrived — dB fields are 0.0 placeholders throughout.
> Next hardware step: acquire second relay, solder wiring, wire CW/CCW direction control.
> Phase 8 automation is unblocked and ready to wire once direction control is confirmed.

```
[█████████████████████████████████░] 95%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~99% | All screens done, dashboard clean, no dev artifacts ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Detail, Officials, Global Map, Dev Tools ✅ |
| Barangay Official screens | ~99% | All screens live, notifications, boundary check, Logs tab ✅ |
| Notification system | 100% | In-app notifications fully wired end-to-end ✅ |
| UI/UX Polish | 100% | All 3 roles — pro navbars, profile redesign, map improvements ✅ |
| End-to-end flow | ✅ Working | Submit → Admin inbox → Approve/Reject → Rider map + Official notification |
| HC-05 Hardware Validation | 100% | Two-way comms confirmed, relay clicks ✅ |
| DC Motor Spin Test | 100% | Motor spins/stops via relay from Flutter app ✅ |
| Barangay Polygon Seeding | 100% | 16 barangays seeded — more to be added incrementally ✅ |
| Speed Tracking & Ride Logging | 100% | SpeedService, RideSession, Logs tab, Speed Monitor ✅ |
| Dev Tooling / Code Hygiene | 100% | Dev screens role-gated, rider dashboard production-clean ✅ |
| Hardware Prototype (CW/CCW + valve) | 0% | Needs second relay + soldering + prototype build |
| IoT Decibel Sensor Integration | 0% | Hardware not arrived — dB is 0.0 placeholder |
| Phase 8 HC-05 Automation | 0% | Unblocked — ready to wire into ExhaustProvider |

---

## 📋 PHASE DETAILS

---

### ✅ PHASE 0.7.4 patch 1: SPEED TRACKING + RIDE SESSION LOGGING + SPEED MONITOR (100% Complete)

**Status:** ✅ COMPLETE — May 10, 2026

| Task | Status |
|------|--------|
| Create `SpeedService` — GPS speed every second with position-diff fallback | ✅ Done |
| Create `RideSession` + `RideSnapshot` models | ✅ Done |
| Add ride session CRUD methods to `FirestoreService` | ✅ Done |
| Wire `ExhaustProvider` — approach/entry/exit snapshots, session create/close | ✅ Done |
| Wire `MapScreen` — feed position to SpeedService, compute nearest zone + distance | ✅ Done |
| Create `BarangayRideLogsScreen` — Logs tab for Official | ✅ Done |
| Add Logs tab to `BarangayNavigationScreen` | ✅ Done |
| Create `SpeedMonitorScreen` — live speed gauge for Super Admin Dev Tools | ✅ Done |
| Add Speed Monitor to `SharedProfileScreen` Developer Tools section | ✅ Done |
| Register `SpeedService` as provider in `main.dart` | ✅ Done |
| Add 2 composite Firestore indexes for `ride_sessions` | ✅ Done |
| `flutter analyze` — zero new errors confirmed | ✅ Done |

#### New Files
| File | Purpose |
|------|---------|
| `lib/services/speed_service.dart` | GPS speed + fallback, 1-second timer, rolling buffer |
| `lib/models/ride_session.dart` | `RideSnapshot` + `RideSession` models |
| `lib/screens/barangay/barangay_ride_logs_screen.dart` | Logs tab — sessions list with speed/dB/snapshot data |
| `lib/screens/test/speed_monitor_screen.dart` | Live speed monitor for Super Admin Dev Tools |

#### Ride Session Logging Strategy
| Trigger | Action |
|---------|--------|
| 50m before zone edge | Approach snapshot (speed + dB placeholder + exhaust state) |
| Zone entry | Entry snapshot + Firestore session doc created + speed buffer cleared |
| Zone exit | Exit snapshot + session closed with avg speed + dB reduction calculated |
| Every second | Speed reading in SpeedService buffer (not written per tick — averaged on exit) |

#### Firestore — New Collection `ride_sessions`
```
ride_sessions/{session_id}
├── rider_uid, zone_id, zone_name, barangay_id
├── started_at, ended_at
├── avg_speed_kph, decibel_before, decibel_after, decibel_reduced
└── snapshots[] → { type, speed_kph, decibel_db, exhaust_state, zone_id, zone_name, timestamp }
```

#### New Firestore Indexes
| Collection | Fields | Order |
|---|---|---|
| `ride_sessions` | `barangay_id` + `started_at` | ASC + DESC |
| `ride_sessions` | `rider_uid` + `started_at` | ASC + DESC |

> **Note:** Decibel values are `0.0` placeholders until IoT noise sensor hardware arrives. Single line to update in `exhaust_provider.dart → _takeSnapshot()` when ready.

---

### ✅ PHASE 7.3 patch 1: BARANGAY POLYGON EXPANSION (100% Complete)

**Status:** ✅ COMPLETE — March 23, 2026

| Task | Status |
|------|--------|
| Manually create polygon coordinates for 14 Poblacion wards | ✅ Done |
| Add all new entries to `add_barangay.js` BARANGAYS object | ✅ Done |
| Run seeding script and confirm all 16 uploads | ✅ Done |

#### Seeded Barangays (16 total)
Lupok, Salug, Poblacion Wards 1, 2, 3, 4, 4-A, 5, 6, 7, 8, 9, 9-A, 10, 11, 12 — all in Guiuan, Eastern Samar.

> No Flutter code changes. Data-only update via Node.js seeding script.

---

### ✅ PHASE 7.3: DC MOTOR SPIN TEST + RELAY WIRING VALIDATION (100% Complete)

**Status:** ✅ COMPLETE — March 21, 2026

| Task | Status |
|------|--------|
| Wire 9V battery to relay and DC motor | ✅ Done |
| Confirm CLOSE command spins motor | ✅ Done |
| Confirm OPEN command stops motor | ✅ Done |
| Confirm shared ground Arduino + battery | ✅ Done |

#### Current Behavior
```
CLOSE command → Pin 8 HIGH → relay energizes → NO closes → motor spins (one direction)
OPEN command  → Pin 8 LOW  → relay de-energizes → NO opens → motor stops
```

#### Current Limitation
Single relay = spin and stop only. CW/CCW requires a second relay — tracked in Phase 7.4.

---

### 🔜 PHASE 7.4: SECOND RELAY + SOLDER + CW/CCW DIRECTION CONTROL

**Status:** ⏳ NEXT (hardware)

| Task | Notes | Status |
|------|-------|--------|
| Acquire second 5V single-channel relay module | Same type as current | ⏳ Pending |
| Solder all current wiring permanently | Breadboard → soldered | ⏳ Pending |
| Wire second relay signal to Arduino Pin 9 | New relay S → Pin 9 | ⏳ Pending |
| Wire H-bridge motor connections for 2 relays | See wiring plan in README | ⏳ Pending |
| Update Arduino sketch — CW/CCW logic | Add RELAY_PIN_2 | ⏳ Pending |
| Test CW spin from app (CLOSE) | Motor rotates clockwise | ⏳ Pending |
| Test CCW spin from app (OPEN) | Motor rotates counter-clockwise | ⏳ Pending |
| Build physical valve/cover prototype | Attach motor shaft to exhaust cover | ⏳ Pending |
| Test full geofence → motor rotation end-to-end | GPS enter zone → CLOSE → relay → motor rotates | ⏳ Pending |

---

### ✅ PHASE 7.2: DEV TOOL RELOCATION + DASHBOARD CLEANUP (100% Complete)

**Status:** ✅ COMPLETE — March 21, 2026

| Task | Status |
|------|--------|
| Add "Developer Tools" section to Super Admin profile | ✅ Done |
| Gate Developer Tools behind `normalizedRole == 'superadmin'` | ✅ Done |
| Remove `_DevTestButton` widget + import + class from rider dashboard | ✅ Done |
| Fix stray `}` compile error after class deletion | ✅ Done |
| Bump version string to v0.7.1 | ✅ Done |
| `flutter analyze` — zero errors confirmed | ✅ Done |

---

### ✅ PHASE 7.1: HC-05 HARDWARE VALIDATION (100% Complete)

**Status:** ✅ COMPLETE — March 19, 2026

| Task | Status |
|------|--------|
| Add `flutter_bluetooth_serial` package | ✅ Done |
| Fix `build.gradle` namespace AGP issue | ✅ Done |
| Create `bt_classic_test_screen.dart` | ✅ Done |
| Configure HC-05 baud rate via AT commands (9600) | ✅ Done |
| Validate Flutter → Arduino command receive | ✅ Done |
| Validate Arduino → Flutter ACK response | ✅ Done |
| Validate relay actuation on OPEN/CLOSE | ✅ Done |

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~98% of phase complete)

**Status:** 🔄 IN PROGRESS

**Group A — Low-risk additive changes**
- [x] 7.1 — `RestrictedArea` model updated ✅
- [x] 7.2 — Sign Up writes `role: "rider"` ✅
- [x] 7.3 — `AuthWrapper` routes by role to 3 nav screens ✅
- [ ] 7.4 — ⏳ Seed Super Admin in Firestore console — **STILL PENDING (manual step)**
- [x] 7.5 — `streamApprovedAreas()` filters approved only ✅
- [x] 7.6 — Zone management removed from rider UI ✅

**Group B — Admin screens**
- [x] 7.7 through 7.11 ✅

**Group C — Barangay Official screens**
- [x] 7.12 through 7.17 ✅

**Group D — Wiring + security**
- [x] 7.18 — Firestore notification docs ✅
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### ⚠️ Immediate Next Actions
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
2. **Step 7.19** — Tighten Firestore security rules (do last, high risk)
3. **Phase 7.4 hardware** — Acquire second relay, solder wiring, wire CW/CCW
4. **IoT sensor** — When decibel hardware arrives, update `decibelDb: 0.0` in `exhaust_provider.dart → _takeSnapshot()`

---

### 🔜 NEXT PHASE — Phase 8: Core HC-05 Automation

**Status:** 🟡 UNBLOCKED — hardware validated, codebase clean, speed/logging wired, ready

| Step | Task | Status |
|------|------|--------|
| 8.1 | `ClassicBluetoothService` — wraps HC-05 connection + send | ⏳ Next |
| 8.2 | Wire `ExhaustProvider` — send `CLOSE` on geofence entry | ⏳ Next |
| 8.3 | Wire `ExhaustProvider` — send `OPEN` on geofence exit | ⏳ Next |
| 8.4 | Replace `BluetoothProvider` BLE scan with HC-05 Classic BT | ⏳ Next |
| 8.5 | Log auto-closure events to Firestore | ⏳ Next |
| 8.6 | End-to-end test — enter zone → relay clicks → motor rotates → cover closes | ⏳ Next |
| 8.7 | ~~Remove `_DevTestButton` + `bt_classic_test_screen.dart` from build~~ | ✅ Done (0.7.2) |

---

## 📦 FULL PACKAGE DEPENDENCIES

```yaml
# Core
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
provider: ^6.1.5+1
shared_preferences: ^2.5.4

# Hardware
flutter_blue_plus: 1.31.15
flutter_bluetooth_serial: ^0.4.0
geolocator: ^14.0.2
permission_handler: ^12.0.1
device_info_plus: ^10.1.0

# Map & Location
flutter_map: ^8.2.2
latlong2: ^0.9.1
geocoding: ^4.0.0

# UI
font_awesome_flutter: ^10.7.0
awesome_dialog: ^3.2.1
flutter_svg: ^2.0.10
lottie: ^3.1.2

# Dev
flutter_launcher_icons: ^0.14.1
```

---

## 🎯 MILESTONES

| # | Milestone | Status | Date |
|---|-----------|--------|------|
| 1 | Foundation | ✅ Done | Before Feb 11 |
| 2 | Professional UI | 🔄 80% | Feb 11 |
| 3 | Full Navigation | ✅ Done | Feb 11 |
| 4 | Permission System | ✅ Done | Feb 11 |
| 5 | Hardware Ready (BLE) | ✅ Done | Feb 17 |
| 6 | Live Map & GPS | ✅ Done | Feb 17 |
| 7 | Background GPS + Map-tap Areas | ✅ Done | Mar 5 |
| 8 | Role Foundation (models, routing, structure) | ✅ Done | Mar 9 |
| 9 | Admin Screens Complete | ✅ Done | Mar 9 |
| 10 | Barangay Screens (core) | ✅ Done | Mar 9 |
| 11 | End-to-end flow verified | ✅ Done | Mar 9 |
| 12 | Notifications + UI/UX Polish (all 3 roles) | ✅ Done | Mar 15 |
| 13 | Barangay Boundary Check + Manual Polygon Seeding | ✅ Done | Mar 18 |
| 14 | HC-05 Hardware Validated + Relay Confirmed | ✅ Done | Mar 19 |
| 15 | Dev Tool Relocation + Rider Dashboard Production-Clean | ✅ Done | Mar 21 |
| 16 | DC Motor Spin Test Validated | ✅ Done | Mar 21 |
| 17 | Barangay Polygon Expansion — 16 barangays seeded | ✅ Done | Mar 23 |
| **18** | **Speed Tracking + Ride Session Logging + Speed Monitor Dev Tool** | **✅ Done** | **May 10, 2026** |
| **19** | **Admin Reports Screen + GPS Smoothing + Speed Overlay** | **✅ Done** | **Jun 11, 2026** |
| 20 | Second Relay + Solder + CW/CCW Direction Control | ⏳ Next | TBD |
| 20 | Physical Valve Prototype Built + Rotation Test | ⏳ Next | TBD |
| 21 | IoT Decibel Sensor Integrated | ⏳ Pending hardware | TBD |
| 22 | Security Rules + Super Admin Seed | 🔄 Next | TBD |
| 23 | MVP Complete (Phase 8 Full Automation) | ⏳ Next | TBD |

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Firestore rules too permissive | **High** | Fix in Step 7.19 before demo |
| Step 7.4 Super Admin not seeded | Medium | Required to log in as admin |
| IoT decibel sensor not integrated | Medium | Hardware pending — `decibelDb: 0.0` placeholder in `_takeSnapshot()` |
| Motor rotation needs timed stop | Medium | `delay()` based — needs limit switch long-term |
| Single relay — no direction control yet | Medium | Needs second relay for CW/CCW — Phase 7.4 |
| Breadboard wiring not yet soldered | Medium | Solder before prototype demo |
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` (~8 instances remaining) | Low | Batch fix before demo — tracked in 0.7.4 patch 2 |
| Code hygiene — `value` → `initialValue`, async context, curly braces | Low | 13 info warnings — tracked in 0.7.4 patch 2, fix before demo |
| `bt_classic_test_screen.dart` | Low | Keep until Phase 8 validated, then delete |
| Developer Tools section in `shared_profile_screen.dart` | Low | Remove after Phase 8 complete |
| `flutter_bluetooth_serial` cache `build.gradle` patch | Low | Document for fresh installs |
| iOS Info.plist not configured | Low | Android only for capstone |

---

**For detailed changes, see:** CHANGELOG.md
**Last Updated:** Jun 11, 2026