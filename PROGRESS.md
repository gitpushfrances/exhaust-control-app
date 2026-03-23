# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 23, 2026

---

## 🎯 Overall Progress: ~93% Complete

> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Phase 7 is ~98% done. HC-05 hardware validated — relay clicks on OPEN/CLOSE.
> DC motor spin test completed — motor spins and stops via CLOSE/OPEN from Flutter app.
> Barangay polygon seeding expanded to 16 barangays — all manually created, no third-party source.
> Next hardware step: acquire second relay, solder wiring, wire CW/CCW direction control.
> Phase 8 automation is unblocked and ready to wire once direction control is confirmed.

```
[███████████████████████████████░] 93%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~99% | All screens done, dashboard clean, no dev artifacts ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Detail, Officials, Global Map, Dev Tools section ✅ |
| Barangay Official screens | ~98% | All screens live, notifications working, boundary check done ✅ |
| Notification system | 100% | In-app notifications fully wired end-to-end ✅ |
| UI/UX Polish | 100% | All 3 roles — pro navbars, profile redesign, map improvements ✅ |
| End-to-end flow | ✅ Working | Submit → Admin inbox → Approve/Reject → Rider map + Official notification |
| HC-05 Hardware Validation | 100% | Two-way comms confirmed, relay clicks ✅ |
| DC Motor Spin Test | 100% | Motor spins/stops via relay from Flutter app ✅ |
| Barangay Polygon Seeding | 100% | 16 barangays seeded — more to be added incrementally ✅ |
| Dev Tooling / Code Hygiene | 100% | Dev test screen role-gated, rider dashboard production-clean ✅ |
| Hardware Prototype (CW/CCW + valve) | 0% | Needs second relay + soldering + prototype build |
| Phase 8 HC-05 Automation | 0% | Unblocked — ready to wire into ExhaustProvider |

---

## 📋 PHASE DETAILS

---

### ✅ PHASE 7.3 patch 1: BARANGAY POLYGON EXPANSION (100% Complete)

**Status:** ✅ COMPLETE — March 23, 2026

| Task | Status |
|------|--------|
| Manually create polygon coordinates for 14 Poblacion wards | ✅ Done |
| Add all new entries to `add_barangay.js` BARANGAYS object | ✅ Done |
| Run seeding script and confirm all 16 uploads | ✅ Done |

#### Seeded Barangays

| Document ID | Points | Result |
|-------------|--------|--------|
| guiuan-lupok | 51 | Overwritten |
| guiuan-salug | 23 | Overwritten |
| guiuan-poblacion-ward-1 | 16 | New |
| guiuan-poblacion-ward-2 | 8 | New |
| guiuan-poblacion-ward-3 | 19 | New |
| guiuan-poblacion-ward-4 | 25 | Overwritten |
| guiuan-poblacion-ward-4a | 10 | New |
| guiuan-poblacion-ward-5 | 25 | New |
| guiuan-poblacion-ward-6 | 36 | New |
| guiuan-poblacion-ward-7 | 20 | New |
| guiuan-poblacion-ward-8 | 20 | New |
| guiuan-poblacion-ward-9 | 12 | New |
| guiuan-poblacion-ward-9a | 16 | New |
| guiuan-poblacion-ward-10 | 30 | New |
| guiuan-poblacion-ward-11 | 35 | New |
| guiuan-poblacion-ward-12 | 19 | New |

> No Flutter code changes. Data-only update via Node.js seeding script.

---

### ✅ PHASE 7.3: DC MOTOR SPIN TEST + RELAY WIRING VALIDATION (100% Complete)

**Status:** ✅ COMPLETE — March 21, 2026

| Task | Status |
|------|--------|
| Wire 9V battery positive to relay COM | ✅ Done |
| Wire relay NO to DC motor Wire A | ✅ Done |
| Wire 9V battery negative to DC motor Wire B | ✅ Done |
| Wire 9V battery negative to Arduino GND (shared ground) | ✅ Done |
| Confirm CLOSE command spins motor | ✅ Done |
| Confirm OPEN command stops motor | ✅ Done |
| Confirm no Arduino code changes needed | ✅ Done |

#### Full Wiring Reference — Current Hardware State

**HC-05 to Arduino:**
| HC-05 Pin | Arduino Pin |
|-----------|-------------|
| VCC | 5V |
| GND | GND |
| TX | Pin 6 (SoftwareSerial RX) |
| RX | Pin 7 (SoftwareSerial TX) |

**Relay to Arduino:**
| Relay Pin | Arduino Pin |
|-----------|-------------|
| S (signal) | Pin 8 |
| + (power) | 5V |
| – (ground) | GND |

**Relay screw terminals + 9V battery + DC motor:**
| From | To |
|------|----|
| 9V battery (+) small circle | Relay COM |
| Relay NO | DC Motor Wire A |
| 9V battery (–) large octagon | DC Motor Wire B |
| 9V battery (–) large octagon | Arduino GND |

> **Shared ground:** 9V battery (–) connects to both Motor Wire B and Arduino GND.
> In this test session both connections meet at Motor Wire B terminal. Electrically correct.

> **9V battery terminals:** Small circle = positive (+). Large octagon = negative (–).

> **Relay NC terminal:** Left unconnected. Not used.

#### Current Behavior
```
CLOSE command → Pin 8 HIGH → relay energizes → NO closes → motor spins (one direction)
OPEN command  → Pin 8 LOW  → relay de-energizes → NO opens → motor stops
```

#### Current Limitation
Single relay = spin and stop only. No direction reversal. CW/CCW requires a second relay.

---

### 🔜 PHASE 7.4: SECOND RELAY + SOLDER + CW/CCW DIRECTION CONTROL

**Status:** ⏳ NEXT

| Task | Notes | Status |
|------|-------|--------|
| Acquire second 5V single-channel relay module | Same type as current | ⏳ Pending |
| Solder all current wiring permanently | Breadboard → soldered | ⏳ Pending |
| Wire second relay signal to Arduino Pin 9 | New relay S → Pin 9 | ⏳ Pending |
| Wire second relay power to Arduino 5V and GND | Same as Relay 1 power | ⏳ Pending |
| Wire H-bridge motor connections for 2 relays | See wiring plan below | ⏳ Pending |
| Update Arduino sketch — add RELAY_PIN_2, CW/CCW logic | See sketch plan below | ⏳ Pending |
| Test CW spin from app (CLOSE) | Motor rotates clockwise | ⏳ Pending |
| Test CCW spin from app (OPEN) | Motor rotates counter-clockwise | ⏳ Pending |
| Build physical valve/cover prototype | Attach motor shaft to exhaust cover | ⏳ Pending |
| Test 90°/180° rotation and return | Enter zone → cover closes → exit zone → cover opens | ⏳ Pending |
| Test full geofence → motor rotation end-to-end | GPS enter zone → CLOSE sent → relay → motor rotates | ⏳ Pending |

#### Planned Wiring — 2 Relay H-Bridge

| From | To | Notes |
|------|----|-------|
| Arduino Pin 8 | Relay 1 S | Controls direction A |
| Arduino Pin 9 | Relay 2 S | Controls direction B |
| 9V battery (+) | Relay 1 COM | Power in |
| 9V battery (+) | Relay 2 COM | Power in |
| Relay 1 NO | DC Motor Wire A | |
| Relay 2 NO | DC Motor Wire B | |
| 9V battery (–) | DC Motor Wire B (via Relay 2 NC or direct) | Return path |
| 9V battery (–) | Arduino GND | Shared ground |

> ⚠️ **Never set both relays HIGH at the same time — short circuit.**

#### Planned Arduino Sketch — CW/CCW

```cpp
#include <SoftwareSerial.h>

SoftwareSerial BTSerial(6, 7);

const int RELAY_PIN_1 = 8;  // CW direction
const int RELAY_PIN_2 = 9;  // CCW direction

void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600);
  pinMode(RELAY_PIN_1, OUTPUT);
  pinMode(RELAY_PIN_2, OUTPUT);
  digitalWrite(RELAY_PIN_1, LOW);
  digitalWrite(RELAY_PIN_2, LOW);
  Serial.println("Ready.");
}

void loop() {
  if (BTSerial.available()) {
    String received = "";
    while (BTSerial.available()) {
      received += (char)BTSerial.read();
      delay(2);
    }
    received.trim();

    if (received.indexOf("CLOSE") >= 0) {
      digitalWrite(RELAY_PIN_2, LOW);
      delay(50);
      digitalWrite(RELAY_PIN_1, HIGH);
      delay(600);  // tune this value
      digitalWrite(RELAY_PIN_1, LOW);
      Serial.println("Motor CW — exhaust CLOSED");
      BTSerial.println("ACK:CLOSE");

    } else if (received.indexOf("OPEN") >= 0) {
      digitalWrite(RELAY_PIN_1, LOW);
      delay(50);
      digitalWrite(RELAY_PIN_2, HIGH);
      delay(600);  // tune this value
      digitalWrite(RELAY_PIN_2, LOW);
      Serial.println("Motor CCW — exhaust OPEN");
      BTSerial.println("ACK:OPEN");

    } else if (received.indexOf("STOP") >= 0) {
      digitalWrite(RELAY_PIN_1, LOW);
      digitalWrite(RELAY_PIN_2, LOW);
      Serial.println("Motor STOPPED");
      BTSerial.println("ACK:STOP");
    }
  }
}
```

> **Note:** `delay(600)` is a timed stop — tune based on motor speed and rotation angle needed.
> A limit switch is the proper long-term fix (tracked in technical debt).

---

### ✅ PHASE 7.2: DEV TOOL RELOCATION + DASHBOARD CLEANUP (100% Complete)

**Status:** ✅ COMPLETE — March 21, 2026

| Task | Status |
|------|--------|
| Add "Developer Tools" section to Super Admin profile | ✅ Done |
| Gate Developer Tools behind `normalizedRole == 'superadmin'` check | ✅ Done |
| Remove `_DevTestButton` widget call from rider dashboard | ✅ Done |
| Remove `bt_classic_test_screen` import from rider dashboard | ✅ Done |
| Remove `_DevTestButton` class entirely from dashboard_screen.dart | ✅ Done |
| Fix stray `}` compile error after class deletion | ✅ Done |
| Bump version string to v0.7.1 in profile screen About dialog + footer | ✅ Done |
| `flutter analyze` — zero errors confirmed | ✅ Done |
| Commit + push to main | ✅ Done |

---

### ✅ PHASE 7.1: HC-05 HARDWARE VALIDATION (100% Complete)

**Status:** ✅ COMPLETE — March 19, 2026

| Task | Status |
|------|--------|
| Add `flutter_bluetooth_serial` package | ✅ Done |
| Fix `build.gradle` namespace AGP issue | ✅ Done |
| Create `bt_classic_test_screen.dart` | ✅ Done |
| Configure HC-05 baud rate via AT commands (9600) | ✅ Done |
| Wire HC-05 TX→Pin6, RX→Pin7, Relay→Pin8 | ✅ Done |
| Validate Flutter → Arduino command receive | ✅ Done |
| Validate Arduino → Flutter ACK response | ✅ Done |
| Validate relay actuation on OPEN/CLOSE | ✅ Done |

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~98% of phase complete)

**Status:** 🔄 IN PROGRESS

#### Step Checklist:

**Group A — Low-risk additive changes**
- [x] 7.1 — `RestrictedArea` model updated ✅
- [x] 7.2 — Sign Up writes `role: "rider"` ✅
- [x] 7.3 — `AuthWrapper` routes by role to 3 nav screens ✅
- [ ] 7.4 — ⏳ Seed Super Admin in Firestore console — **STILL PENDING (manual step)**
- [x] 7.5 — `streamApprovedAreas()` filters approved only ✅
- [x] 7.6 — Zone management removed from rider UI ✅

**Group B — Admin screens**
- [x] 7.7 — `AdminNavigationScreen` + skeleton screens ✅
- [x] 7.8 — Admin Home Dashboard ✅
- [x] 7.9 — Request Inbox + Detail + Approve/Reject ✅
- [x] 7.10 — Manage Officials + Create Official form ✅
- [x] 7.11 — Admin Global Map ✅

**Group C — Barangay Official screens**
- [x] 7.12 — `BarangayNavigationScreen` + skeleton screens ✅
- [x] 7.13 — Barangay Home Dashboard ✅
- [x] 7.14 — Submit Request screen ✅
- [x] 7.15 — Barangay boundary check (manual polygon) ✅
- [x] 7.16 — My Requests (3 tabs: Pending / Approved / Rejected) ✅
- [x] 7.17 — Notifications screen + bell icon ✅

**Group D — Wiring + security**
- [x] 7.18 — Firestore notification docs on approve/reject/submit ✅
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### ⚠️ Immediate Next Actions
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
2. **Step 7.19** — Tighten Firestore security rules (do last, high risk)
3. **Phase 7.4 hardware** — Acquire second relay, solder wiring, wire CW/CCW

---

### 🔜 NEXT PHASE — Phase 8: Core HC-05 Automation

**Status:** 🟡 UNBLOCKED — hardware validated, codebase clean, ready to wire

| Step | Task | Status |
|------|------|--------|
| 8.1 | Create `ClassicBluetoothService` — wraps HC-05 connection + send | ⏳ Next |
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
flutter_bluetooth_serial: ^0.4.0   # HC-05 Classic BT
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
| **17** | **Barangay Polygon Expansion — 16 barangays seeded** | **✅ Done** | **Mar 23** |
| 18 | Second Relay + Solder + CW/CCW Direction Control | ⏳ Next | TBD |
| 19 | Physical Valve Prototype Built + Rotation Test | ⏳ Next | TBD |
| 20 | Security Rules + Super Admin Seed | 🔄 Next | Mar 2026 |
| 21 | MVP Complete (Phase 8 Full Automation) | ⏳ Next | TBD |

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Firestore rules too permissive | **High** | Fix in Step 7.19 before demo |
| Step 7.4 Super Admin not seeded | Medium | Required to log in as admin |
| Motor rotation needs timed stop | Medium | Currently no stop after 90°/180° — needs delay() or limit switch |
| Single relay — no direction control yet | Medium | Needs second relay for CW/CCW — tracked in Phase 7.4 |
| Breadboard wiring not yet soldered | Medium | Solder before prototype demo |
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` (~12 instances remaining) | Low | Batch fix before demo |
| `activeColor` → `activeThumbColor` (1 instance) | Low | Minor deprecation |
| `bt_classic_test_screen.dart` | Low | Keep until Phase 8 validated, then delete entirely |
| Developer Tools section in `shared_profile_screen.dart` | Low | Remove after Phase 8 complete |
| `flutter_bluetooth_serial` cache `build.gradle` patch | Low | Document for fresh installs |
| `barangay_profile_screen.dart` still a placeholder | Low | Uses shared profile — functional |
| Old test zone documents missing `submitted_by_name` | Low | Only affects pre-patch documents |
| iOS Info.plist not configured | Low | Android only for capstone |

---

**For detailed changes, see:** CHANGELOG.md
**Last Updated:** March 23, 2026