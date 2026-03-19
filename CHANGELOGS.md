# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.1] - Phase 7.1: HC-05 Classic Bluetooth Hardware Validation

**Status:** ✅ COMPLETED — March 19, 2026

### 🎯 What This Phase Achieved:
Validated full two-way Classic Bluetooth communication between Flutter app and Arduino Uno via HC-05 module. Established OPEN/CLOSE/HELLO command protocol over Serial. Confirmed relay actuation from Flutter app. This unblocks Phase 8 hardware automation.

---

### ✅ Completed This Session — HC-05 BT + Relay Validation (March 19, 2026)

---

#### Feature — Classic Bluetooth (HC-05) Flutter Integration
- **Added:** `flutter_bluetooth_serial: ^0.4.0` to `pubspec.yaml`
- **Note:** Coexists with existing `flutter_blue_plus` — separate packages, no conflict
- **Fix:** Manually patched `flutter_bluetooth_serial` cache `build.gradle` — added `namespace` field and upgraded `compileSdkVersion` to 34, replaced `jcenter()` with `mavenCentral()` — required for AGP compatibility on newer Android toolchain

#### Feature — `lib/screens/test/bt_classic_test_screen.dart` — NEW FILE
- **New folder:** `lib/screens/test/`
- **Purpose:** Isolated standalone HC-05 hardware test screen — not wired to any provider
- **Features:**
  - Loads bonded/paired devices via `FlutterBluetoothSerial.instance.getBondedDevices()`
  - Connects via `BluetoothConnection.toAddress(device.address)`
  - Listens to `conn.input` stream — displays Arduino responses in real-time log
  - Send commands: HELLO, OPEN, CLOSE
  - Color-coded serial log — green for Arduino responses, blue for Flutter sends, gray for system messages
  - Disconnect button, refresh paired devices, clear log
  - Status bar at top — green when connected, red when not
- **Note:** Dev-only screen — marked with TODO to remove before production

#### Feature — `lib/screens/rider/dashboard_screen.dart` updated
- **Added:** `_DevTestButton` widget at bottom of dashboard body
- **Added:** Import for `bt_classic_test_screen.dart`
- **Purpose:** Temporary dev access button to HC-05 test screen
- **Note:** Marked TODO — remove before production

---

#### Hardware — HC-05 Module Configuration
- **Issue:** HC-05 default baud rate was 115200 — too fast for `SoftwareSerial` on Arduino Uno causing garbled/empty reads
- **Fix:** Entered AT mode on HC-05 and permanently set baud to 9600 via AT commands:
  - `AT` → `OK` (confirmed AT mode active)
  - `AT+UART?` → `+UART:115200,0,0` (confirmed original baud)
  - `AT+UART=9600,0,0` → `OK` (set to 9600)
  - `AT+RESET` → `OK` (applied and restarted)
- **Result:** HC-05 permanently configured at 9600 baud

#### Hardware — Arduino Wiring (Final)
| HC-05 Pin | Arduino Pin |
|-----------|-------------|
| VCC | 5V |
| GND | GND |
| TX | Pin 6 (SoftwareSerial RX) |
| RX | Pin 7 (SoftwareSerial TX) |
| Relay S | Pin 8 |
| Relay + | 5V |
| Relay - | GND |

#### Hardware — Arduino Sketch (Final)
- **SoftwareSerial** on pins 6/7 at 9600 baud
- **Relay** on Pin 8 — `LOW` = off (exhaust open), `HIGH` = on (exhaust closed)
- **Command protocol:**
  - `OPEN` → `digitalWrite(RELAY_PIN, LOW)` → ACK:OPEN
  - `CLOSE` → `digitalWrite(RELAY_PIN, HIGH)` → ACK:CLOSE
  - Other → echoes ACK back
- **String matching:** Uses `indexOf()` instead of `==` — handles hidden `\r\n` characters from Flutter serial send

#### Validation Results
- ✅ Flutter → HC-05 → Arduino: HELLO, OPEN, CLOSE received correctly in Serial Monitor
- ✅ Arduino → HC-05 → Flutter: ACK responses displayed in app serial log
- ✅ Relay clicks on CLOSE command, releases on OPEN command
- ✅ Full two-way communication confirmed at 9600 baud on SoftwareSerial pins 6/7

---

### 🗂️ Updated Folder Structure
```
lib/
├── screens/
│   ├── test/                                  ✅ NEW folder
│   │   └── bt_classic_test_screen.dart        ✅ NEW — HC-05 dev test screen
│   ├── rider/
│   │   └── dashboard_screen.dart              ✅ added _DevTestButton (temp)
│   └── ... (all other screens unchanged)
```

---

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.19** — Firestore security rules (HIGH RISK — do last before demo)
- [ ] **7.20** — FCM push notifications (optional)

---

### 🔜 Next — Phase 8: Core HC-05 Automation

**Status:** 🟡 UNBLOCKED — hardware validated, ready to wire into ExhaustProvider

| Task | Notes |
|------|-------|
| 8.1 | Create `ClassicBluetoothService` — wraps HC-05 connection + send logic | 
| 8.2 | Wire `ExhaustProvider` — send `CLOSE` command on geofence entry |
| 8.3 | Wire `ExhaustProvider` — send `OPEN` command on geofence exit |
| 8.4 | Replace `BluetoothProvider` BLE scan with HC-05 Classic BT connection |
| 8.5 | Log auto-closure events to Firestore |
| 8.6 | End-to-end test — rider enters zone → BLE fires → relay clicks → valve closes |
| 8.7 | Remove `_DevTestButton` and `bt_classic_test_screen.dart` from production build |

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~98% of phase complete)
**Date Started:** March 2026

### 🎯 What This Phase Will Achieve:
Expand the app from a single-role rider app into a full 3-role system — Super Admin, Barangay Official, and Rider. Adds role-based routing, Admin screens (dashboard, request inbox, manage officials, global map), Barangay Official screens (dashboard, submit request, request history, notifications), barangay boundary enforcement, and an in-app notification system.

---

### 📋 Implementation Steps

| Step | Task | Risk | Status |
|------|------|------|--------|
| 7.1 | Update `RestrictedArea` model — add `status`, `barangay_id`, `submitted_by_uid`, `remarks`, `rejection_reason`, `approved_at`, `approved_by_uid` fields with defaults | None | ✅ Done |
| 7.2 | Update Sign Up screen — write `role: "rider"` on register | None | ✅ Done |
| 7.3 | Update `AuthWrapper` — role-based routing to 3 navigation screens | Low | ✅ Done |
| 7.4 | Seed Super Admin in Firestore console manually | None | ⏳ Pending |
| 7.5 | Update `streamRestrictedAreas()` — replaced with `streamApprovedAreas()` filter `status == "approved"` | Low | ✅ Done |
| 7.6 | Remove Add Restricted Area button from rider UI (map screen + profile screen) | None | ✅ Done |
| 7.7 | Create `AdminNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.8 | Build Admin Home Dashboard (stat cards, recent activity feed) | None | ✅ Done |
| 7.9 | Build Request Inbox + Detail screen + Approve/Reject flow | None | ✅ Done |
| 7.10 | Build Manage Officials + Create Official form | None | ✅ Done |
| 7.11 | Build Admin Global Map with filter chips + circle overlays | None | ✅ Done |
| 7.12 | Create `BarangayNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.13 | Build Barangay Home Dashboard (zone stats, request summary) | None | ✅ Done |
| 7.14 | Build Submit Request screen (real logic — submits pending to Firestore) | None | ✅ Done |
| 7.15 | Implement barangay boundary check — polygon point-in-polygon (GeoJSON) | None | ✅ Done |
| 7.16 | Build My Requests screen — 3 inner tabs (Pending / Approved / Rejected) | None | ✅ Done |
| 7.17 | Build Notifications screen + bell icon on Barangay Home | None | ✅ Done |
| 7.18 | Write Firestore notification documents on approve / reject / submit events | Low | ✅ Done |
| 7.19 | Tighten Firestore security rules (all roles) | **HIGH** | ⏳ Pending |
| 7.20 | Add FCM push notifications (optional, add last) | Low | ⏳ Pending |

---

### ✅ Completed This Session — Barangay Geofencing + Data Seeding (March 18, 2026)

#### Feature — Barangay Boundary Geofencing (Step 7.15) — COMPLETED
- **Approach:** Upgraded from Option A (Haversine circle) to Option B (real polygon boundaries from GeoJSON)
- **Data Source:** `faeldon/philippines-json-maps` repo — `bgysubmuns` GeoJSON files (barangay level, lowres)
- **Coverage:** All 26 municipalities of Eastern Samar — 934 barangays total
- **Province PSGC:** `806000000` (Eastern Samar, Region VIII)

#### Infrastructure — Firestore `/barangays` Collection Seeded
- **New collection:** `/barangays/{barangay_id}` — 934 documents uploaded
- **ID format:** Custom hierarchical format `08-MUN-BRG` (e.g. `08-001-001`)

#### New File — `lib/utils/geo_utils.dart`
- **Added:** `isPointInPolygon(lat, lng, polygon)` — ray casting algorithm, pure Dart, no packages
- **Added:** `firestorePolygonToLatLng(polygon)` — converts Firestore `{lat, lng}` array to `List<LatLng>`

#### Feature — `FirestoreService.getBarangayBoundary()`
- **Added:** `getBarangayBoundary(String barangayId)` method to `firestore_service.dart`

#### Feature — `barangay_submit_request_screen.dart` updated
- **Added:** Polygon boundary enforcement on pin drop
- **Added:** `PolygonLayer` on map — draws official's barangay boundary as dashed blue polygon
- **Updated:** Map auto-centers on barangay centroid on load

#### Patch — Notification title strings cleaned
- **Removed:** Emoji from `'Zone Approved ✅'` and `'Zone Rejected ❌'`

---

### ✅ Completed Previously — UI/UX Polish & Fixes (March 15, 2026)

#### Feature — Notification System fully wired
#### Feature — `submitted_by_name` field added to zone requests
#### Feature — Admin Home Dashboard rebuilt
#### Feature — Admin Navigation Screen rebuilt with `_ProNavBar`
#### Feature — Admin Global Map UI improved
#### Feature — Rider Dashboard cleaned up
#### Feature — Rider Map improved with pulsing GPS dot
#### Feature — Rider Navigation Screen rebuilt
#### Feature — Barangay Navigation Screen rebuilt
#### Feature — Profile Screen redesigned (gradient header, role-matched colors)
#### Patch — Firestore composite indexes for notifications

---

### ✅ Completed Previously — Patches & Fixes (March 9, 2026)

#### Patch — `RestrictedArea.fromMap()` Firestore Timestamp crash fix
#### Patch — Firestore composite indexes for restricted_areas
#### Patch — `admin_request_detail_screen.dart` converted to `StatefulWidget`
#### Patch — Live location stream added to Admin and Barangay maps

---

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
| 0.7.0 (patch 3) | Barangay Geofencing + GeoJSON Seeding + Boundary Check | ✅ Complete | Mar 18, 2026 |
| 0.7.0 (final) | Security Rules + Super Admin Seed | 🔄 Next | Mar 2026 |
| **0.7.1** | **HC-05 Classic BT Validation + Relay Test** | **✅ Complete** | **Mar 19, 2026** |
| 0.8.0 | Core HC-05 Automation (geofence → relay) | 🟡 Unblocked | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 19, 2026