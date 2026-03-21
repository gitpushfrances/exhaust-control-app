# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones. Features a full 3-role system — Super Admin, Barangay Official, and Rider.

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
- 🏘️ **Barangay Geofencing:** Officials can only submit zones inside their assigned barangay — enforced via real GeoJSON polygon boundaries (934 barangays, Eastern Samar)
- 🔧 **Dev Tools:** HC-05 hardware test screen accessible exclusively to Super Admin via profile settings

---

## 🎯 Current Status: ~93% Complete

```
[███████████████████████████████░] 93%
```

| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~99% | All screens done, dashboard clean ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Officials, Map, Dev Tools ✅ |
| Barangay Official screens | ~98% | All screens live, notifications, boundary check ✅ |
| Notification system | 100% | In-app notifications fully wired ✅ |
| UI/UX Polish | 100% | All 3 roles complete ✅ |
| HC-05 Hardware Validation | 100% | Two-way comms + relay confirmed ✅ |
| DC Motor Spin Test | 100% | Motor spins/stops via relay from Flutter app ✅ |
| Hardware Prototype (CW/CCW) | 0% | Needs second relay + soldering |
| Phase 8 BLE Automation | 0% | Unblocked — ready to wire |

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
- [x] Profile — Developer Tools section (HC-05 test — superadmin only)

**Barangay Official Role:**
- [x] Dashboard — 4 live stat cards, recent requests
- [x] Submit Request — map pin drop, radius selector, remarks, boundary check
- [x] Barangay polygon drawn on map — blue dashed overlay, dark exterior mask
- [x] Out-of-bounds modal — `barrierDismissible: false`, "I Understand" CTA
- [x] My Requests — 3-tab (Pending / Approved / Rejected), withdraw, resubmit
- [x] Notifications — multi-select, swipe-to-delete, smart timestamps, mark all read

**Hardware (Validated):**
- [x] HC-05 permanently configured at 9600 baud via AT commands
- [x] Arduino sketch — OPEN/CLOSE/HELLO protocol, relay on Pin 8
- [x] Full two-way BT communication confirmed (Flutter ↔ HC-05 ↔ Arduino)
- [x] Relay actuation confirmed — clicks on CLOSE, releases on OPEN
- [x] DC motor spin test confirmed — motor spins/stops via relay from Flutter app
- [x] Dedicated 9V battery for motor, shared ground with Arduino confirmed

## 🔄 In Progress / Remaining

- [ ] Firestore security rules tightening — Step 7.19, HIGH RISK, do last before demo
- [ ] Seed Super Admin in Firestore console — Step 7.4, manual 5 min
- [ ] Logo integration — asset pending

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
| `firebase_auth` | ^6.1.4 | User authentication — login, signup, session |
| `cloud_firestore` | ^6.1.2 | Database — users, zones, notifications, barangays |
| `provider` | ^6.1.5+1 | State management across all 3 roles |
| `shared_preferences` | ^2.5.4 | Local storage — persist small values across sessions |

#### Hardware & Connectivity
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_blue_plus` | 1.31.15 | BLE scanning and connection (existing, kept for compatibility) |
| `flutter_bluetooth_serial` | ^0.4.0 | **HC-05 Classic Bluetooth** — paired device list, connect, send/receive serial data. Requires manual `build.gradle` patch for AGP compatibility (namespace + compileSdkVersion 34 + mavenCentral) |
| `geolocator` | ^14.0.2 | GPS position stream, background location, permission handling |
| `permission_handler` | ^12.0.1 | Runtime permissions — Bluetooth, location, Android 12+ |
| `device_info_plus` | ^10.1.0 | Android SDK version detection — used for conditional permission logic |

#### Map & Location
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^8.2.2 | **OpenStreetMap** tiles rendered in Flutter — zone circles, polygon overlays, markers, GPS dot layer |
| `latlong2` | ^0.9.1 | `LatLng` coordinate class used by `flutter_map` |
| `geocoding` | ^4.0.0 | Reverse geocoding — converts GPS coordinates to human-readable address |

#### UI & Icons
| Package | Version | Purpose |
|---------|---------|---------|
| `font_awesome_flutter` | ^10.7.0 | **Font Awesome icons** — used across all 3 role screens for action rows, stat cards, nav items |
| `awesome_dialog` | ^3.2.1 | Styled modal dialogs — confirmations, alerts, success/error feedback |
| `flutter_svg` | ^2.0.10 | SVG asset rendering — logo, custom graphics |
| `lottie` | ^3.1.2 | Lottie animation files — used for loading states and visual feedback |

#### Dev & Build
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_launcher_icons` | ^0.14.1 | Generates Android/iOS launcher icons from a single source asset |

---

### Arduino / Hardware Stack

#### Microcontroller
| Component | Detail |
|-----------|--------|
| **Arduino Uno** | Main controller — runs the sketch, receives BT commands, controls relay |
| **IDE** | Arduino IDE — used to write and upload sketches via USB |
| **Language** | C++ (Arduino dialect) |
| **Library used** | `SoftwareSerial.h` — built-in Arduino library, enables serial communication on digital pins 6 and 7 instead of the hardware Serial pins |

#### Bluetooth Module
| Component | Detail |
|-----------|--------|
| **HC-05** | Classic Bluetooth (not BLE) — paired to phone like a headset, communicates over serial |
| **Baud rate** | 9600 — permanently set via AT command (`AT+UART=9600,0,0`) |
| **Wiring** | VCC → 5V, GND → GND, TX → Pin 6 (SoftwareSerial RX), RX → Pin 7 (SoftwareSerial TX) |
| **AT mode** | Entered by holding button on HC-05 during power-on — used once to set baud rate |

#### Relay Module
| Component | Detail |
|-----------|--------|
| **5V single-channel relay** | Acts as the electrical switch between the 9V battery and the DC motor |
| **Signal pin** | S → Arduino Pin 8 |
| **Power** | + → Arduino 5V, – → Arduino GND |
| **Screw terminals used** | COM (power in from battery +) and NO (power out to motor Wire A) |
| **NC terminal** | Not connected — left empty |
| **Behavior** | Pin 8 HIGH = relay energizes = NO closes = motor gets power. Pin 8 LOW = relay off = motor loses power |

#### Motor & Power
| Component | Detail |
|-----------|--------|
| **DC Motor** | Salvaged from Epson printer — generic brushed DC motor |
| **Power supply** | Dedicated 9V battery — completely separate from Arduino power |
| **9V battery (+)** | Small circle terminal → Relay COM |
| **9V battery (–)** | Large octagon terminal → Motor Wire B AND Arduino GND (shared ground) |
| **Motor Wire A** | Relay NO |
| **Motor Wire B** | 9V battery (–) |
| **Current direction** | With 1 relay: spin only (one direction). CW/CCW requires second relay — pending Phase 7.4 |

#### Planned — Second Relay (Phase 7.4)
| Component | Detail |
|-----------|--------|
| **Second 5V relay** | Same type as current relay |
| **Signal pin** | S → Arduino Pin 9 |
| **Purpose** | H-bridge config — Relay 1 + Relay 2 swap motor polarity for CW/CCW |
| **Rule** | Never set both relays HIGH simultaneously — short circuit |

---

### External Services & APIs

| Service | Purpose |
|---------|---------|
| **Firebase Auth** | User authentication, session management |
| **Cloud Firestore** | All app data — users, zones, barangays, notifications |
| **OpenStreetMap (OSM)** | Free map tiles served via `flutter_map` — no API key required |
| **Nominatim** | OSM geocoding API — used during barangay GeoJSON seeding to resolve coordinates |
| **Overpass API** | OSM query API — used during barangay boundary polygon extraction from GeoJSON |
| **Firebase Cloud Messaging (FCM)** | Push notifications — optional, planned for Phase 7.20 |

---

### Seeding & Dev Tools

| Tool | Purpose |
|------|---------|
| **Node.js v18+** | Runs the barangay seeding script |
| **firebase-admin (npm)** | Node.js Firebase Admin SDK — used to write 934 barangay documents to Firestore |
| **GeoJSON source** | `faeldon/philippines-json-maps` — `bgysubmuns` files, Eastern Samar Region VIII |
| **Firestore console** | Manual Super Admin seed — one-time setup, no script |

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
| From | To | Notes |
|------|----|-------|
| 9V battery (+) small circle | Relay COM | Power in |
| Relay NO | DC Motor Wire A | Power out when relay ON |
| 9V battery (–) large octagon | DC Motor Wire B | Return path |
| 9V battery (–) large octagon | Arduino GND | Shared ground — critical |

### Planned — Phase 7.4 (2 Relay H-Bridge)

| From | To | Notes |
|------|----|-------|
| Arduino Pin 8 | Relay 1 S | CW direction |
| Arduino Pin 9 | Relay 2 S | CCW direction |
| 9V battery (+) | Relay 1 COM | |
| 9V battery (+) | Relay 2 COM | |
| Relay 1 NO | Motor Wire A | |
| Relay 2 NO | Motor Wire B | |
| 9V battery (–) | Motor Wire B (return) | |
| 9V battery (–) | Arduino GND | Shared ground |

---

## 🧪 Arduino Sketch — Current (v0.7.3, no changes needed for spin test)

```cpp
#include <SoftwareSerial.h>

SoftwareSerial BTSerial(6, 7); // RX=6, TX=7

const int RELAY_PIN = 8;

void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  Serial.println("Ready. Waiting for BT data...");
}

void loop() {
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat > 2000) {
    Serial.println("Waiting...");
    lastHeartbeat = millis();
  }

  if (BTSerial.available()) {
    String received = "";
    while (BTSerial.available()) {
      received += (char)BTSerial.read();
      delay(2);
    }
    received.trim();

    if (received.length() > 0) {
      Serial.print("Received: [");
      Serial.print(received);
      Serial.print("] length: ");
      Serial.println(received.length());

      if (received.indexOf("OPEN") >= 0) {
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("Relay OFF — exhaust OPEN");
        BTSerial.println("ACK:OPEN");
      } else if (received.indexOf("CLOSE") >= 0) {
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("Relay ON — exhaust CLOSED");
        BTSerial.println("ACK:CLOSE");
      } else {
        BTSerial.println("ACK:" + received);
      }
    }
  }
}
```

### Planned Sketch — Phase 7.4 (CW/CCW with 2 relays)

```cpp
#include <SoftwareSerial.h>

SoftwareSerial BTSerial(6, 7);

const int RELAY_PIN_1 = 8;  // CW — exhaust CLOSE
const int RELAY_PIN_2 = 9;  // CCW — exhaust OPEN

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
      digitalWrite(RELAY_PIN_2, LOW);  // stop opposite first — safety
      delay(50);
      digitalWrite(RELAY_PIN_1, HIGH); // CW — close cover
      delay(600);                       // rotate ~90°–180°, tune this value
      digitalWrite(RELAY_PIN_1, LOW);  // stop
      Serial.println("Motor CW — exhaust CLOSED");
      BTSerial.println("ACK:CLOSE");

    } else if (received.indexOf("OPEN") >= 0) {
      digitalWrite(RELAY_PIN_1, LOW);  // stop opposite first — safety
      delay(50);
      digitalWrite(RELAY_PIN_2, HIGH); // CCW — open cover
      delay(600);                       // rotate ~90°–180°, tune this value
      digitalWrite(RELAY_PIN_2, LOW);  // stop
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

> **Note on `delay(600)`:** This is a timed stop. The motor runs for 600ms then cuts power. Tune this value based on your actual motor speed and the rotation angle needed for your prototype cover. A limit switch replacing the delay is the proper long-term fix — flagged in technical debt.

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

| Collection | Field 1 | Field 2 | Order |
|---|---|---|---|
| `restricted_areas` | `submitted_by_uid` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `approved_at` DESC | Collection |
| `notifications` | `uid` ASC | `created_at` DESC | Collection |
| `notifications` | `uid` ASC | `is_read` ASC | Collection |

**6. Seed `/barangays` collection (one-time)**
```bash
npm install firebase-admin
node seed_barangays.js
# Expected: 934 barangays uploaded across 26 municipalities of Eastern Samar
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
Open Arduino IDE
Open sketch from /arduino/exhaust_controller.ino
Select board: Arduino Uno
Select correct COM port
Upload
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
│   ├── app_user.dart                          # uid, name, email, role, barangayIds, isActive
│   └── restricted_area.dart                   # GPS zone model with status + Haversine
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart                # BLE scanning + connection
│   ├── exhaust_provider.dart                  # Exhaust state + live location + geofence
│   └── restricted_areas_provider.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart                 # All Firestore reads/writes, 3 roles
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── test/
│   │   └── bt_classic_test_screen.dart        # HC-05 dev test — Super Admin only
│   ├── shared/
│   │   └── shared_profile_screen.dart         # Shared profile + Dev Tools (superadmin)
│   ├── rider/
│   │   ├── main_navigation_screen.dart
│   │   ├── dashboard_screen.dart              # BT + exhaust status (production-clean)
│   │   ├── map_screen.dart
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
│       ├── barangay_navigation_screen.dart
│       ├── barangay_home_screen.dart
│       ├── barangay_submit_request_screen.dart
│       ├── barangay_my_requests_screen.dart
│       ├── barangay_notifications_screen.dart
│       └── barangay_profile_screen.dart
└── utils/
    ├── app_colors.dart
    ├── app_text_styles.dart
    ├── permission_handler.dart
    └── geo_utils.dart                         # isPointInPolygon + firestorePolygonToLatLng
```

---

## 👥 Role Permission Matrix

| Feature | Super Admin | Barangay Official | Rider |
|---------|-------------|-------------------|-------|
| View approved zones | ✅ All barangays | ✅ Own barangay only | ✅ All barangays |
| Submit zone request | ✅ Direct approve | ✅ Pending approval | ❌ |
| Barangay boundary enforcement | ❌ | ✅ Polygon check | ❌ |
| Approve / Reject requests | ✅ | ❌ | ❌ |
| Manage officials | ✅ | ❌ | ❌ |
| Receive notifications | ❌ | ✅ | ❌ |
| Bluetooth + exhaust control | ❌ | ❌ | ✅ |
| GPS auto-close on zone entry | ❌ | ❌ | ✅ |
| HC-05 Developer Tools | ✅ | ❌ | ❌ |

---

## 🔐 Android Permissions Required

```xml
android.permission.BLUETOOTH
android.permission.BLUETOOTH_ADMIN
android.permission.BLUETOOTH_SCAN
android.permission.BLUETOOTH_CONNECT
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
android.permission.INTERNET
```

---

## 🏘️ Barangay Geofencing System

1. Admin assigns `barangay_id` to official on account creation — `official_uid` written back to barangay document
2. Official opens Submit Request — app fetches barangay polygon from `/barangays/{barangay_id}`
3. Polygon drawn on map — blue dashed overlay, dark mask outside boundary
4. On every pin drop — `isPointInPolygon()` ray casting runs
5. Outside boundary — blocked with modal (`barrierDismissible: false`, must tap "I Understand")
6. Inside boundary — submission proceeds

**Data source:** `faeldon/philippines-json-maps` — `bgysubmuns` GeoJSON, Eastern Samar Region VIII
**Coverage:** 26 municipalities, 934 barangays
**ID format:** `08-MUN-BRG` (e.g. `08-016-003`)

---

## 📝 Technical Debt

| Item | Priority | Notes |
|------|----------|-------|
| Firestore rules too permissive | **High** | Fix Step 7.19 before demo |
| Super Admin not seeded | Medium | Required to log in as admin |
| Motor rotation timed stop | Medium | `delay()` based — fragile, needs limit switch |
| Second relay for CW/CCW | Medium | Single relay = spin/stop only, Phase 7.4 |
| Breadboard wiring not soldered | Medium | Solder before prototype demo |
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` (~12 instances) | Low | Batch fix before demo |
| `bt_classic_test_screen.dart` | Low | Delete after Phase 8 validated |
| Developer Tools section in profile | Low | Remove after Phase 8 complete |
| `flutter_bluetooth_serial` build.gradle patch | Low | Document for fresh installs |
| Logo integration | Low | Asset pending |
| iOS Info.plist not configured | Low | Android only for capstone |

---

## 🗺️ Roadmap

| Version | Phase | Status | Date |
|---------|-------|--------|------|
| 0.0.1 | Foundation | ✅ Done | Before Feb 11 |
| 0.1.0 | UI/UX Foundation | 🔄 80% | Feb 11 |
| 0.2.0 | Navigation | ✅ Done | Feb 11 |
| 0.3.0 | Permissions | ✅ Done | Feb 11 |
| 0.4.0 | Bluetooth (BLE) | ✅ Done | Feb 17 |
| 0.5.0 | GPS | ✅ Done | Feb 17 |
| 0.6.0 | Map Integration | ✅ Done | Feb 17 |
| 0.6.1 | Patches + Background GPS | ✅ Done | Mar 5 |
| 0.7.0 p1 | Multi-Role Foundation + Admin/Barangay Screens | ✅ Done | Mar 9 |
| 0.7.0 p2 | Notifications + UI/UX Polish | ✅ Done | Mar 15 |
| 0.7.0 p3 | Barangay Geofencing + GeoJSON Seeding | ✅ Done | Mar 18 |
| 0.7.1 | HC-05 Hardware Validation + Relay Confirmed | ✅ Done | Mar 19 |
| 0.7.2 | Dev Tool Relocation + Dashboard Cleanup | ✅ Done | Mar 21 |
| **0.7.3** | **DC Motor Spin Test Validated** | **✅ Done** | **Mar 21** |
| 0.7.4 | Second Relay + Solder + CW/CCW Direction Control | ⏳ Next | TBD |
| 0.7.5 | Physical Valve Prototype + Rotation Test | ⏳ Next | TBD |
| 0.7.x | Security Rules + Super Admin Seed | 🔄 Next | Mar 2026 |
| 0.8.0 | Full HC-05 Automation (geofence → relay → motor) | ⏳ Unblocked | TBD |

---

## 🧪 Testing

**Tested on:** Infinix X6833B (Android 13)

### ✅ Passing
- Login/signup + role routing (all 3 roles)
- Full submit → approve → rider map flow end-to-end
- Notification delivery, multi-select, swipe-delete, unread badge
- Reverse geocoding on admin dashboard
- GPS dot on all 3 maps
- BLE scanning and connection
- Restricted area detection (Haversine)
- Barangay polygon — dark overlay, pin drop blocking, out-of-bounds modal
- HC-05 two-way communication — OPEN/CLOSE/HELLO confirmed
- Relay actuation — clicks on CLOSE, releases on OPEN
- DC motor spin — spins on CLOSE, stops on OPEN, 9V battery dedicated power
- HC-05 test screen — accessible via Super Admin only, not visible to other roles

### ⏳ Pending
- CW/CCW motor direction (needs second relay)
- Physical valve prototype rotation test
- Geofence → motor rotation end-to-end
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

## 👨‍💻 Author

Development Team — Capstone Project 2026

---

**Last Updated:** March 21, 2026
**Version:** 0.7.3
**Status:** Active Development — Phase 7.4 hardware next, Phase 8 unblocked