# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones. Features a full 3-role system — Super Admin, Barangay Official, and Rider — with speed tracking, ride session logging, and decibel reduction reporting.

---

## 📱 Project Overview

### **What It Does:**
- 🔗 **Bluetooth Control:** Connects to motorcycle exhaust controller hardware (HC-05 Classic Bluetooth → Arduino Uno → 5V Relay → DC Motor)
- 📍 **GPS Automation:** Automatically closes exhaust when entering restricted noise zones (Haversine distance check on every GPS tick)
- 🗺️ **Live Map:** Real OpenStreetMap tiles via `flutter_map` — pulsing GPS dot, restricted zone radius circles, barangay polygon overlays
- 👥 **3-Role System:** Super Admin, Barangay Official, Rider — each with completely separate navigation stacks and permissions
- 🔔 **In-App Notifications:** Officials receive real-time approval/rejection notifications via Firestore streams
- 📊 **Admin Dashboard:** Live stats, zone management, official management, global map
- 👤 **User Accounts:** Firebase Auth with role-based routing — role read from Firestore on login
- 🏘️ **Barangay Geofencing:** Officials can only submit zones inside their assigned barangay — enforced via manually created polygon boundaries (currently 16 barangays in Guiuan, Eastern Samar)
- 🚀 **Speed Tracking:** GPS speed captured every second with position-diff fallback — averaged per zone pass
- 📋 **Ride Session Logging:** 3-snapshot logging per zone pass (approach, entry, exit) stored in Firestore `ride_sessions` collection
- 📉 **Decibel Reduction Reporting:** dB before/after/reduced per session — placeholder until IoT sensor hardware arrives
- 🔧 **Dev Tools:** HC-05 hardware test + live Speed Monitor — accessible exclusively to Super Admin via profile settings

---

## 🎯 Current Status: ~95% Complete

```
[█████████████████████████████████░] 95%
```

| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~99% | All screens done, dashboard clean ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Officials, Map, Dev Tools ✅ |
| Barangay Official screens | ~99% | All screens live + Logs tab ✅ |
| Notification system | 100% | In-app notifications fully wired ✅ |
| UI/UX Polish | 100% | All 3 roles complete ✅ |
| Speed Tracking & Ride Logging | 100% | SpeedService, RideSession, Logs tab, Speed Monitor ✅ |
| HC-05 Hardware Validation | 100% | Two-way comms + relay confirmed ✅ |
| DC Motor Spin Test | 100% | Motor spins/stops via relay from Flutter app ✅ |
| Barangay Polygon Seeding | 100% | 16 barangays seeded ✅ |
| IoT Decibel Integration | 0% | Hardware pending — dB fields are 0.0 placeholders |
| Hardware Prototype (CW/CCW) | 0% | Needs second relay + soldering |
| Phase 8 HC-05 Automation | 0% | Unblocked — ready to wire |

---

## ✅ Completed Features

**Core:**
- [x] Firebase Auth — login, signup, role-based routing
- [x] Professional UI with custom components
- [x] Permission system — Bluetooth + GPS, Android 12+ compliant

**Rider Role:**
- [x] Dashboard — BT connection status, exhaust status, quick actions, live location
- [x] Live Map — pulsing GPS dot, restricted zone circles, recenter FAB, RESTRICTED badge
- [x] BLE scanning and connection
- [x] GPS tracking every 8 seconds with reverse geocoding
- [x] Restricted area detection on every GPS tick (Haversine)
- [x] Dashboard production-clean — no dev artifacts

**Super Admin Role:**
- [x] Dashboard — welcome card, 4 live stat cards, recent zone activity
- [x] Request Inbox — pending requests, approve/reject with reason
- [x] Manage Officials — multi-barangay (max 3), assign/remove barangays, detail screen
- [x] Global Map — all zones, filter chips, pin markers, legend
- [x] Profile → Developer Tools → HC-05 Hardware Test (superadmin only)
- [x] Profile → Developer Tools → Speed Monitor — live GPS speed, fallback tag, 20-reading log

**Barangay Official Role:**
- [x] Dashboard — 4 live stat cards, recent requests
- [x] Submit Request — map pin drop, radius selector, remarks, boundary check
- [x] Barangay polygon drawn on map — blue dashed overlay, dark exterior mask
- [x] Out-of-bounds modal — `barrierDismissible: false`, "I Understand" CTA
- [x] My Requests — 3-tab (Pending / Approved / Rejected), withdraw, resubmit
- [x] Notifications — multi-select, swipe-to-delete, smart timestamps, mark all read
- [x] **Ride Logs tab** — sessions list with avg speed, dB before/after/reduced, per-snapshot breakdown (approach / entry / exit)

**Speed Tracking & Logging:**
- [x] `SpeedService` — GPS speed every second (`m/s → km/h`), position-diff fallback, rolling buffer
- [x] `RideSnapshot` — point-in-time reading at approach/entry/exit with speed + dB + exhaust state
- [x] `RideSession` — groups snapshots, stores avg speed + dB reduction in Firestore
- [x] Approach detection — fires snapshot 50m before zone edge
- [x] Session lifecycle — created on zone entry, closed on zone exit with calculated averages
- [x] Decibel fields — `0.0` placeholder; single line swap when IoT hardware arrives

**Hardware (Validated):**
- [x] HC-05 permanently configured at 9600 baud via AT commands
- [x] Arduino sketch — OPEN/CLOSE/HELLO protocol, relay on Pin 8
- [x] Full two-way BT communication confirmed (Flutter ↔ HC-05 ↔ Arduino)
- [x] Relay actuation confirmed — clicks on CLOSE, releases on OPEN
- [x] DC motor spin test confirmed — motor spins/stops via relay from Flutter app
- [x] Dedicated 9V battery for motor, shared ground with Arduino confirmed

**Barangay Data:**
- [x] 16 barangays seeded in Guiuan, Eastern Samar
- [x] All polygon boundaries manually created — no third-party GeoJSON dependency
- [x] Seeding script (`add_barangay.js`) supports incremental additions

---

## 🔄 In Progress / Remaining

- [ ] Firestore security rules tightening — Step 7.19, HIGH RISK, do last before demo
- [ ] Seed Super Admin in Firestore console — Step 7.4, manual 5 min
- [ ] IoT decibel sensor integration — hardware not arrived; update `decibelDb: 0.0` in `_takeSnapshot()` when ready
- [ ] Logo integration — asset pending

---

## ⏳ Next — Phase 7.4: Second Relay + Solder + CW/CCW

- [ ] Acquire second 5V single-channel relay module
- [ ] Solder all current breadboard wiring permanently
- [ ] Wire second relay to Pin 9 for direction reversal
- [ ] Update Arduino sketch — CW/CCW direction control
- [ ] Build physical valve/cover prototype
- [ ] Test 90°/180° rotation and return on geofence entry/exit

## ⏳ Next — Phase 8: Full HC-05 Automation

- [ ] Create `ClassicBluetoothService` — wraps HC-05 connection + send logic
- [ ] Wire `ExhaustProvider` — CLOSE on geofence entry, OPEN on geofence exit
- [ ] Replace `BluetoothProvider` BLE scan with HC-05 Classic BT
- [ ] Log auto-closure events to Firestore
- [ ] End-to-end test — enter zone → relay clicks → motor rotates → cover closes
- [ ] Delete `bt_classic_test_screen.dart` + Developer Tools section after Phase 8 validated

---

## 📦 Full Package & Dependency Reference

### Flutter / Dart Packages

#### Firebase & Backend
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^4.4.0 | Firebase initialization |
| `firebase_auth` | ^6.1.4 | User authentication |
| `cloud_firestore` | ^6.1.2 | Database — users, zones, notifications, barangays, ride_sessions |
| `provider` | ^6.1.5+1 | State management across all 3 roles |
| `shared_preferences` | ^2.5.4 | Local storage |

#### Hardware & Connectivity
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_blue_plus` | 1.31.15 | BLE scanning and connection (kept for compatibility) |
| `flutter_bluetooth_serial` | ^0.4.0 | HC-05 Classic Bluetooth — paired device list, connect, send/receive |
| `geolocator` | ^14.0.2 | GPS position stream, speed (`m/s`), background location |
| `permission_handler` | ^12.0.1 | Runtime permissions — Bluetooth, location, Android 12+ |
| `device_info_plus` | ^10.1.0 | Android SDK version detection |

#### Map & Location
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^8.2.2 | OpenStreetMap tiles — zone circles, polygon overlays, GPS dot |
| `latlong2` | ^0.9.1 | `LatLng` coordinate class |
| `geocoding` | ^4.0.0 | Reverse geocoding — GPS → human-readable address |

#### UI & Icons
| Package | Version | Purpose |
|---------|---------|---------|
| `font_awesome_flutter` | ^10.7.0 | Font Awesome icons |
| `awesome_dialog` | ^3.2.1 | Styled modal dialogs |
| `flutter_svg` | ^2.0.10 | SVG asset rendering |
| `lottie` | ^3.1.2 | Lottie animation files |

#### Dev & Build
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_launcher_icons` | ^0.14.1 | Generates launcher icons |

---

## 🗄️ Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | All accounts — role, name, email, barangay assignment, isActive |
| `restricted_areas` | Zone requests — status, polygon, radius, submitted_by |
| `barangays` | Polygon boundaries — 16 barangays seeded |
| `notifications` | In-app notification docs per official |
| `ride_sessions` | Speed + dB logs per zone pass — approach/entry/exit snapshots + averages |

### Firestore Composite Indexes Required

| Collection | Field 1 | Field 2 | Order |
|---|---|---|---|
| `restricted_areas` | `submitted_by_uid` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `approved_at` DESC | Collection |
| `notifications` | `uid` ASC | `created_at` DESC | Collection |
| `notifications` | `uid` ASC | `is_read` ASC | Collection |
| `ride_sessions` | `barangay_id` ASC | `started_at` DESC | Collection |
| `ride_sessions` | `rider_uid` ASC | `started_at` DESC | Collection |

---

## 🚀 Getting Started

### Prerequisites
```
Flutter SDK: >=3.10.8
Dart SDK: >=3.0.0
Android Studio
Firebase project configured
Physical Android device (Bluetooth Classic + GPS required)
Node.js v18+ (barangay seeding script only)
Arduino IDE (for uploading sketch to Arduino Uno)
```

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/exhaust_controller_app.git
cd exhaust_controller_app
```

**2. Install Flutter dependencies**
```bash
flutter pub get
```

**3. Patch `flutter_bluetooth_serial` build.gradle**

Required after every `flutter pub get` on a fresh machine:
```
Navigate to: ~/.pub-cache/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android/
Edit build.gradle:
  - Add:    namespace 'com.example.flutter_bluetooth_serial'
  - Change: compileSdkVersion to 34
  - Replace: jcenter() with mavenCentral()
```

**4. Configure Firebase**
```bash
# Add google-services.json to android/app/
```

**5. Create Firestore composite indexes**

See table in Firestore Collections section above — 7 indexes total.

**6. Seed `/barangays` collection (one-time)**
```bash
npm install firebase-admin
node add_barangay.js
```

**7. Seed Super Admin in Firestore console (one-time, manual)**
```
Collection: users
Document ID: <Firebase Auth UID of admin account>
Fields:
  name:       "Super Admin"
  email:      "your-admin@email.com"
  role:       "superadmin"
  is_active:  true
  created_at: <timestamp>
```

**8. Upload Arduino sketch**
```
Open Arduino IDE → open sketch → select Arduino Uno → upload
```

**9. Run the app**
```bash
flutter run
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart
├── models/
│   ├── app_user.dart
│   ├── restricted_area.dart
│   └── ride_session.dart                              ✅ NEW — RideSnapshot + RideSession
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart
│   ├── exhaust_provider.dart                          ✅ UPDATED — speed + snapshot wiring
│   └── restricted_areas_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart                         ✅ UPDATED — ride session CRUD
│   └── speed_service.dart                             ✅ NEW — GPS speed + fallback
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── test/
│   │   ├── bt_classic_test_screen.dart               HC-05 dev test — Super Admin only
│   │   └── speed_monitor_screen.dart                 ✅ NEW — live speed monitor
│   ├── shared/
│   │   └── shared_profile_screen.dart                ✅ UPDATED — Speed Monitor in Dev Tools
│   ├── rider/
│   │   ├── main_navigation_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── map_screen.dart                           ✅ UPDATED — SpeedService + zone distance
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_navigation_screen.dart
│   │   ├── admin_home_screen.dart
│   │   ├── admin_request_inbox_screen.dart
│   │   ├── admin_request_detail_screen.dart
│   │   ├── admin_manage_officials_screen.dart
│   │   ├── admin_create_official_screen.dart
│   │   └── admin_global_map_screen.dart
│   └── barangay/
│       ├── barangay_navigation_screen.dart            ✅ UPDATED — Logs tab added
│       ├── barangay_home_screen.dart
│       ├── barangay_submit_request_screen.dart
│       ├── barangay_my_requests_screen.dart
│       ├── barangay_notifications_screen.dart
│       ├── barangay_ride_logs_screen.dart             ✅ NEW — ride session logs viewer
│       └── barangay_profile_screen.dart
├── utils/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   ├── permission_handler.dart
│   └── geo_utils.dart
└── widgets/
    ├── bluetooth_connection_modal.dart
    ├── custom_button.dart
    └── custom_text_field.dart
```

---

## 👥 Role Permission Matrix

| Feature | Super Admin | Barangay Official | Rider |
|---------|-------------|-------------------|-------|
| View approved zones | ✅ All | ✅ Own barangay | ✅ All |
| Submit zone request | ✅ Direct approve | ✅ Pending approval | ❌ |
| Barangay boundary enforcement | ❌ | ✅ Polygon check | ❌ |
| Approve / Reject requests | ✅ | ❌ | ❌ |
| Manage officials | ✅ | ❌ | ❌ |
| Receive notifications | ❌ | ✅ | ❌ |
| View ride logs | ❌ | ✅ Own barangay | ❌ |
| Bluetooth + exhaust control | ❌ | ❌ | ✅ |
| GPS auto-close on zone entry | ❌ | ❌ | ✅ |
| Speed tracked per zone pass | ❌ | views only | ✅ generates |
| HC-05 Dev Test + Speed Monitor | ✅ | ❌ | ❌ |

---

## 🚀 Speed Tracking Architecture

```
Rider enters zone area
        ↓
[50m buffer] → Approach snapshot (speed + dB + exhaust state)
        ↓
[Zone entry] → Entry snapshot + Firestore ride_sessions doc created
        ↓
[Every 1 sec] → SpeedService ticks (GPS speed or position-diff fallback)
        ↓
[Zone exit] → Exit snapshot + session closed (avg speed + dB reduction calculated)
        ↓
Barangay Official Logs tab → streams ride_sessions for their barangay
```

**IoT Decibel Integration (pending hardware):**
When the noise sensor arrives and sends readings via BT to Arduino → Flutter, update this single line in `exhaust_provider.dart`:
```dart
// _takeSnapshot() method:
decibelDb: 0.0,  // ← replace with live BT reading
```

---

## 🔌 Full Wiring Reference

### Current Hardware State (v0.7.3)

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
| S | Pin 8 |
| + | 5V |
| – | GND |

**Relay screw terminals + 9V battery + DC motor:**
| From | To |
|------|----|
| 9V battery (+) small circle | Relay COM |
| Relay NO | DC Motor Wire A |
| 9V battery (–) large octagon | DC Motor Wire B |
| 9V battery (–) large octagon | Arduino GND |

### Planned — Phase 7.4 (2 Relay H-Bridge)

| From | To | Notes |
|------|----|-------|
| Arduino Pin 8 | Relay 1 S | CW — exhaust CLOSE |
| Arduino Pin 9 | Relay 2 S | CCW — exhaust OPEN |
| 9V battery (+) | Relay 1 COM + Relay 2 COM | |
| Relay 1 NO | Motor Wire A | |
| Relay 2 NO | Motor Wire B | |
| 9V battery (–) | Motor Wire B (return) + Arduino GND | |

> ⚠️ **Never set both relays HIGH simultaneously — short circuit.**

---

## 🧪 Arduino Sketch — Current (v0.7.3)

```cpp
#include <SoftwareSerial.h>
SoftwareSerial BTSerial(6, 7);
const int RELAY_PIN = 8;

void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
}

void loop() {
  if (BTSerial.available()) {
    String received = "";
    while (BTSerial.available()) {
      received += (char)BTSerial.read();
      delay(2);
    }
    received.trim();
    if (received.indexOf("OPEN") >= 0) {
      digitalWrite(RELAY_PIN, LOW);
      BTSerial.println("ACK:OPEN");
    } else if (received.indexOf("CLOSE") >= 0) {
      digitalWrite(RELAY_PIN, HIGH);
      BTSerial.println("ACK:CLOSE");
    }
  }
}
```

---

## 📝 Technical Debt

| Item | Priority | Notes |
|------|----------|-------|
| Firestore rules too permissive | **High** | Fix Step 7.19 before demo |
| Super Admin not seeded | Medium | Required to log in as admin |
| IoT decibel sensor not integrated | Medium | One line to update when hardware arrives |
| Motor rotation timed stop | Medium | `delay()` based — needs limit switch |
| Second relay for CW/CCW | Medium | Single relay = spin/stop only |
| Breadboard wiring not soldered | Medium | Solder before prototype demo |
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` (~12 instances) | Low | Batch fix before demo |
| `bt_classic_test_screen.dart` | Low | Delete after Phase 8 validated |
| Developer Tools section in profile | Low | Remove after Phase 8 complete |
| Logo integration | Low | Asset pending |
| iOS Info.plist not configured | Low | Android only for capstone |

---

## 🗺️ Roadmap

| Version | Phase | Status | Date |
|---------|-------|--------|------|
| 0.7.3 patch 1 | Barangay Polygon Expansion | ✅ Done | Mar 23, 2026 |
| **0.7.4 patch 1** | **Speed Tracking + Ride Logging + Speed Monitor** | **✅ Done** | **May 10, 2026** |
| 0.7.4 | Second Relay + Solder + CW/CCW | 🟡 Next (hardware) | TBD |
| 0.7.5 | Physical Valve Prototype + Rotation Test | ⏳ Next | TBD |
| 0.7.x | IoT Decibel Sensor Integration | ⏳ Pending hardware | TBD |
| 0.7.x | Security Rules + Super Admin Seed | 🔄 Next | TBD |
| 0.8.0 | Full HC-05 Automation (geofence → relay → motor) | ⏳ Unblocked | TBD |

---

## 🧪 Testing

**Tested on:** Infinix X6833B (Android 13)
**GPS Mock Testing:** Lockito (simulates GPS routes through barangay zones)

### ✅ Passing
- Login/signup + role routing (all 3 roles)
- Full submit → approve → rider map flow end-to-end
- Notification delivery, multi-select, swipe-delete, unread badge
- Restricted area detection (Haversine)
- Barangay polygon — dark overlay, pin drop blocking, out-of-bounds modal
- HC-05 two-way communication — OPEN/CLOSE/HELLO confirmed
- Relay actuation — clicks on CLOSE, releases on OPEN
- DC motor spin — spins on CLOSE, stops on OPEN
- Barangay polygon seeding — 16 barangays uploaded
- Speed Monitor — live speed display, GPS vs fallback tag
- Ride session logging — sessions created/closed in Firestore on zone entry/exit

### ⏳ Pending
- CW/CCW motor direction (needs second relay)
- Physical valve prototype rotation test
- Geofence → motor rotation end-to-end
- IoT decibel sensor readings
- Firestore security rules
- iOS support

---

## 📚 Documentation

- [CHANGELOG.md](./CHANGELOG.md) — Full version history and session logs
- [PROJECT_PROGRESS.md](./PROJECT_PROGRESS.md) — Phase-by-phase progress tracker

---

## 📄 License

Created for educational purposes as part of a capstone project.

---

**Last Updated:** May 10, 2026
**Version:** 0.7.4 patch 1
**Status:** Active Development — Phase 7.4 hardware next, Phase 8 unblocked