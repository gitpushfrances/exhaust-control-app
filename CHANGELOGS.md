# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.2] - Phase 7.2: UI Hardening, Dev Tool Relocation & Dashboard Cleanup

**Status:** ✅ COMPLETED — March 21, 2026

### 🎯 What This Phase Achieved:
Cleaned up the rider dashboard by fully removing the temporary HC-05 dev test shortcut. Relocated the hardware test screen exclusively to the Super Admin profile under a new "Developer Tools" section. Fixed a stray brace compile error introduced during the removal. Verified zero errors on `flutter analyze` before pushing.

---

### ✅ Completed This Session — Dev Tool Relocation + Dashboard Cleanup (March 21, 2026)

---

#### Feature — `lib/screens/shared/shared_profile_screen.dart` updated
- **Added:** `import '../test/bt_classic_test_screen.dart'`
- **Added:** "Developer Tools" `_Section` block — only renders when `normalizedRole == 'superadmin'`
- **Added:** `_ActionRow` — "HC-05 Hardware Test" with `bluetooth_searching` icon (indigo), subtitle "Test Classic Bluetooth & relay commands", navigates to `BtClassicTestScreen` via `Navigator.push`
- **Result:** Dev hardware test is now role-gated — barangay officials and riders never see it
- **Version bump:** `v0.7.0` → `v0.7.1` in About dialog and footer text

#### Fix — `lib/screens/rider/dashboard_screen.dart`
- **Removed:** `import '../test/bt_classic_test_screen.dart'` (line 6)
- **Removed:** `_DevTestButton()` widget call from dashboard body column
- **Removed:** Entire `_DevTestButton` class (was lines 498–514)
- **Fixed:** Stray closing brace `}` left behind after class deletion — caused `expected_executable` compile error at line 495/496
- **Result:** Rider dashboard is clean — no dev artifacts, compiles without errors

#### Verification
- `flutter analyze` — **zero errors** after all changes
- Only pre-existing `info`-level deprecation warnings remain (tracked in tech debt)
- Phase 8 task **8.7** marked ✅ — dev test button removed from production build

---

### 🗂️ Updated Folder Impact
```
lib/
├── screens/
│   ├── shared/
│   │   └── shared_profile_screen.dart    ✅ UPDATED — Developer Tools section (superadmin only)
│   ├── rider/
│   │   └── dashboard_screen.dart         ✅ UPDATED — _DevTestButton fully removed, stray brace fixed
│   └── test/
│       └── bt_classic_test_screen.dart   ℹ️  Unchanged — still exists, now only reachable via Super Admin
```

---

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.19** — Firestore security rules (HIGH RISK — do last before demo)
- [ ] **7.20** — FCM push notifications (optional)

---

### 🔜 Next — Phase 8: Core HC-05 Automation

**Status:** 🟡 UNBLOCKED — hardware validated, dev tooling cleaned up, ready to wire

| Task | Notes | Status |
|------|-------|--------|
| 8.1 | Create `ClassicBluetoothService` — wraps HC-05 connection + send logic | ⏳ Next |
| 8.2 | Wire `ExhaustProvider` — send `CLOSE` command on geofence entry | ⏳ Next |
| 8.3 | Wire `ExhaustProvider` — send `OPEN` command on geofence exit | ⏳ Next |
| 8.4 | Replace `BluetoothProvider` BLE scan with HC-05 Classic BT connection | ⏳ Next |
| 8.5 | Log auto-closure events to Firestore | ⏳ Next |
| 8.6 | End-to-end test — rider enters zone → relay clicks → valve closes | ⏳ Next |
| 8.7 | ~~Remove `_DevTestButton` and `bt_classic_test_screen.dart` from production build~~ | ✅ Done |

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
- **Note:** Dev-only screen — accessible via Super Admin profile → Developer Tools

#### Feature — `lib/screens/rider/dashboard_screen.dart` updated
- **Added:** `_DevTestButton` widget at bottom of dashboard body *(temp — removed in v0.7.2)*
- **Note:** Marked TODO — removed in patch 0.7.2

---

#### Hardware — HC-05 Module Configuration
- **Issue:** HC-05 default baud rate was 115200 — too fast for `SoftwareSerial` on Arduino Uno
- **Fix:** Entered AT mode and permanently set baud to 9600:
  - `AT+UART=9600,0,0` → `OK`
  - `AT+RESET` → `OK`
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
- **String matching:** Uses `indexOf()` — handles hidden `\r\n` from Flutter serial send

#### Validation Results
- ✅ Flutter → HC-05 → Arduino: HELLO, OPEN, CLOSE received correctly
- ✅ Arduino → HC-05 → Flutter: ACK responses displayed in app serial log
- ✅ Relay clicks on CLOSE command, releases on OPEN command
- ✅ Full two-way communication confirmed at 9600 baud

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
| 7.1 | Update `RestrictedArea` model | None | ✅ Done |
| 7.2 | Update Sign Up screen — write `role: "rider"` | None | ✅ Done |
| 7.3 | Update `AuthWrapper` — role-based routing | Low | ✅ Done |
| 7.4 | Seed Super Admin in Firestore console manually | None | ⏳ Pending |
| 7.5 | `streamApprovedAreas()` filter `status == "approved"` | Low | ✅ Done |
| 7.6 | Remove Add Restricted Area from rider UI | None | ✅ Done |
| 7.7 | `AdminNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.8 | Admin Home Dashboard | None | ✅ Done |
| 7.9 | Request Inbox + Detail + Approve/Reject flow | None | ✅ Done |
| 7.10 | Manage Officials + Create Official form | None | ✅ Done |
| 7.11 | Admin Global Map | None | ✅ Done |
| 7.12 | `BarangayNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.13 | Barangay Home Dashboard | None | ✅ Done |
| 7.14 | Submit Request screen | None | ✅ Done |
| 7.15 | Barangay boundary check — polygon point-in-polygon | None | ✅ Done |
| 7.16 | My Requests — 3 tabs (Pending / Approved / Rejected) | None | ✅ Done |
| 7.17 | Notifications screen + bell icon | None | ✅ Done |
| 7.18 | Firestore notification docs on approve/reject/submit | Low | ✅ Done |
| 7.19 | Tighten Firestore security rules | **HIGH** | ⏳ Pending |
| 7.20 | FCM push notifications (optional) | Low | ⏳ Pending |

---

### ✅ Completed — Manage Officials Overhaul + Notification Upgrades + Polygon Fix (March 2026)

#### Feature — `admin_manage_officials_screen.dart` — Full replacement
- Tappable cards → `AdminOfficialDetailScreen`
- Multi-barangay support (max 3 per official)
- Assign/remove barangay bottom sheet with cascading municipality → barangay picker
- Assignment sends in-app notification to official

#### Feature — `admin_create_official_screen.dart` — Full replacement
- Calls `createOfficialAccountWithSync()` — writes `official_uid` back to barangay doc on creation
- Fixes occupancy dot always showing vacant

#### Feature — `barangay_notifications_screen.dart` — Full rewrite
- Long-press enters multi-select mode
- Swipe-to-delete, select all, mark selected as read, delete selected, delete all
- Smart timestamps (time if today, date if older)

#### Fix — `barangay_submit_request_screen.dart`
- Polygon winding order fixed — world rectangle explicitly clockwise, boundary counterclockwise
- Dark overlay now correctly dims outside the barangay boundary
- Out-of-bounds error promoted from snackbar to modal — `barrierDismissible: false`, "I Understand" CTA

#### Fix — `AppUser` model
- Added `barangayIds: List<String>` and `barangayNames: List<String>`
- Old single `barangayId`/`barangayName` kept as computed getters — no breaking changes

#### Fix — `FirestoreService`
- Added: `_syncBarangayOfficialUid`, `createOfficialAccountWithSync`, `assignBarangayToOfficial`, `removeBarangayFromOfficial`, `getBarangaysForOfficial`, `deleteNotification`, `deleteNotifications`, `deleteAllNotifications`, `markNotificationsRead`

---

### ✅ Completed — Barangay Geofencing + Data Seeding (March 18, 2026)
- Real polygon boundaries from GeoJSON (`faeldon/philippines-json-maps`)
- 934 barangays seeded across 26 municipalities of Eastern Samar
- `geo_utils.dart` — `isPointInPolygon()` ray casting + `firestorePolygonToLatLng()`

---

### ✅ Completed — UI/UX Polish (March 15, 2026)
- Notification system fully wired
- `submitted_by_name` field added to zone requests
- All 3 nav screens rebuilt with `_ProNavBar`
- Profile screen redesigned — gradient header, role-matched colors
- Rider map — pulsing GPS dot
- Admin Global Map UI improved

---

### ✅ Completed — Patches & Fixes (March 9, 2026)
- `RestrictedArea.fromMap()` Firestore Timestamp crash fix
- Firestore composite indexes for `restricted_areas`
- `admin_request_detail_screen.dart` converted to `StatefulWidget`
- Live location stream added to Admin and Barangay maps

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
| 0.7.1 | HC-05 Classic BT Validation + Relay Test | ✅ Complete | Mar 19, 2026 |
| **0.7.2** | **Dev Tool Relocation + Rider Dashboard Cleanup** | **✅ Complete** | **Mar 21, 2026** |
| 0.8.0 | Core HC-05 Automation (geofence → relay) | 🟡 Unblocked | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 21, 2026