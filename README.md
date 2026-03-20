# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones. Features a full 3-role system — Super Admin, Barangay Official, and Rider.

---

## 📱 Project Overview

### **What It Does:**
- 🔗 **Bluetooth Control:** Connects to motorcycle exhaust controller hardware (HC-05 Classic Bluetooth → Arduino Uno)
- 📍 **GPS Automation:** Automatically closes exhaust when entering restricted areas
- 🗺️ **Live Map:** Real OpenStreetMap with live pulsing GPS dot and restricted zone overlays
- 👥 **3-Role System:** Super Admin, Barangay Official, Rider — each with their own screens and permissions
- 🔔 **In-App Notifications:** Officials receive real-time approval/rejection notifications
- 📊 **Admin Dashboard:** Live stats, zone management, official management
- 👤 **User Accounts:** Firebase authentication with role-based routing
- 🏘️ **Barangay Geofencing:** Officials can only submit zones inside their assigned barangay — enforced via real polygon boundaries from GeoJSON data (934 barangays, Eastern Samar)
- 🔧 **Dev Tools:** HC-05 hardware test screen accessible exclusively to Super Admin via profile settings

### **Technology Stack:**
- **Frontend:** Flutter 3.10+
- **Backend:** Firebase (Auth, Firestore)
- **Hardware:** HC-05 Classic Bluetooth → Arduino Uno → Relay (Pin 8)
- **Maps:** OpenStreetMap via `flutter_map`
- **State Management:** Provider
- **Geofencing:** Ray casting point-in-polygon algorithm (pure Dart) + GeoJSON barangay boundaries

---

## 🎯 Current Status: ~92% Complete

### ✅ **Completed Features:**

**Core:**
- [x] User authentication (login/signup)
- [x] Professional UI with custom components
- [x] Role-based routing — 3 separate navigation stacks
- [x] Permission system (Bluetooth, GPS — Android 12+ compliant)

**Rider Role:**
- [x] Dashboard — BT connection status, exhaust status (compact), quick actions, location
- [x] Live Map — pulsing GPS dot, restricted zone circles, recenter FAB, RESTRICTED badge
- [x] Profile — gradient header card with role color, account info sections
- [x] BLE scanning and connection
- [x] GPS tracking every 8 seconds with reverse geocoding
- [x] Restricted area detection on every GPS tick (Haversine)
- [x] Dashboard production-clean — no dev artifacts

**Super Admin Role:**
- [x] Dashboard — welcome card, 4 live stat cards, recent zone activity, officials overview
- [x] Request Inbox — pending requests list, approve/reject with reason, Firestore write
- [x] Manage Officials — multi-barangay support (max 3), detail screen, assign/remove barangays
- [x] Global Map — all zones color-coded by status, filter chips, pin markers, legend
- [x] Profile — indigo gradient card, **Developer Tools section** (HC-05 hardware test — superadmin only)

**Barangay Official Role:**
- [x] Dashboard — welcome card, 4 live stat cards, recent requests
- [x] Submit Request — map pin drop, radius selector, remarks, live location
- [x] Barangay boundary enforcement — polygon check on every pin drop
- [x] Boundary polygon drawn on map — blue dashed polygon overlay with correct winding (dark outside, clear inside)
- [x] Out-of-bounds modal — `barrierDismissible: false`, barangay name injected, "I Understand" CTA
- [x] My Requests — 3-tab screen (Pending / Approved / Rejected), withdrawal, resubmit
- [x] Notifications — multi-select, swipe-to-delete, smart timestamps, mark all read, delete all
- [x] Profile — blue gradient card, barangay info row

**Notification System:**
- [x] Firestore `/notifications` collection
- [x] Admin approve/reject → notification to official
- [x] Unread badge on nav bar (live stream)
- [x] Multi-select mode, swipe-to-delete, mark individual/all as read, delete selected/all

**Geofencing & Boundary System:**
- [x] Restricted area geofence — Haversine circle check, fires on every GPS tick (rider)
- [x] Barangay boundary geofence — real polygon boundaries, point-in-polygon ray casting
- [x] `/barangays` Firestore collection — 934 barangays, 26 municipalities of Eastern Samar
- [x] `geo_utils.dart` — `isPointInPolygon()` + `firestorePolygonToLatLng()`

**HC-05 Hardware (Validated):**
- [x] `flutter_bluetooth_serial` integrated and patched for AGP compatibility
- [x] HC-05 permanently configured at 9600 baud via AT commands
- [x] Arduino sketch — OPEN/CLOSE/HELLO command protocol, relay on Pin 8
- [x] Full two-way communication confirmed (Flutter ↔ HC-05 ↔ Arduino)
- [x] Relay actuation confirmed — clicks on CLOSE, releases on OPEN
- [x] `bt_classic_test_screen.dart` — dev test screen, accessible via Super Admin only

### 🔄 **In Progress / Remaining:**
- [ ] Firestore security rules tightening (Step 7.19 — HIGH RISK, do last)
- [ ] Seed Super Admin in Firestore (Step 7.4 — manual, 5 min)
- [ ] Logo integration (asset pending)

### ⏳ **Planned (Phase 8 — Unblocked):**
- [ ] Create `ClassicBluetoothService` — wraps HC-05 connection + send logic
- [ ] Wire `ExhaustProvider` — send `CLOSE`/`OPEN` commands on geofence entry/exit
- [ ] Replace `BluetoothProvider` BLE scan with HC-05 Classic BT
- [ ] Log auto-closure events to Firestore
- [ ] End-to-end test — enter zone → relay clicks → valve closes
- [ ] Remove `bt_classic_test_screen.dart` + Developer Tools section after Phase 8 validated

---

## 🚀 Getting Started

### **Prerequisites:**
```bash
Flutter SDK: >=3.10.8
Dart SDK: >=3.0.0
Android Studio / Xcode
Firebase project configured
Physical Android device (BLE + GPS required)
Node.js v18+ (for seeding scripts only)
```

### **Installation:**

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/exhaust_controller_app.git
cd exhaust_controller_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Patch `flutter_bluetooth_serial` build.gradle** *(required after every `flutter pub get` on a fresh machine)*
```
Navigate to: ~/.pub-cache/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android/
Edit build.gradle:
  - Add: namespace 'com.example.flutter_bluetooth_serial'
  - Change: compileSdkVersion to 34
  - Replace: jcenter() with mavenCentral()
```

4. **Configure Firebase**
```bash
# Add your google-services.json to android/app/
```

5. **Create Firestore composite indexes** (required — app will silently fail without these)

| Collection | Field 1 | Field 2 | Order |
|---|---|---|---|
| `restricted_areas` | `submitted_by_uid` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `approved_at` DESC | Collection |
| `notifications` | `uid` ASC | `created_at` DESC | Collection |
| `notifications` | `uid` ASC | `is_read` ASC | Collection |

6. **Seed the `/barangays` collection** (one-time setup)
```bash
npm install firebase-admin
node seed_barangays.js
# Expected output: 934 barangays uploaded across 26 municipalities
```

7. **Seed Super Admin in Firestore console**
```
Collection: users
Document ID: <Firebase Auth UID of admin account>
Fields:
  name: "Super Admin"
  email: "your-admin@email.com"
  role: "superadmin"
  is_active: true
  created_at: <timestamp>
```

8. **Run the app**
```bash
flutter run
```

---

## 📦 Dependencies

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

## 🏗️ Project Structure

```
lib/
├── main.dart
├── models/
│   ├── app_user.dart                        # uid, name, email, role, barangayIds (multi), isActive
│   └── restricted_area.dart                 # GPS zone model with status + Haversine
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart              # BLE scanning + connection
│   ├── exhaust_provider.dart                # Exhaust state + live location
│   └── restricted_areas_provider.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart               # All Firestore reads/writes across 3 roles
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── test/
│   │   └── bt_classic_test_screen.dart      # HC-05 dev test — Super Admin only
│   ├── shared/
│   │   └── shared_profile_screen.dart       # Shared across all 3 roles + Dev Tools (superadmin)
│   ├── rider/
│   │   ├── main_navigation_screen.dart
│   │   ├── dashboard_screen.dart            # BT + exhaust status + location (production-clean)
│   │   ├── map_screen.dart
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_navigation_screen.dart
│   │   ├── admin_home_screen.dart
│   │   ├── admin_request_inbox_screen.dart
│   │   ├── admin_request_detail_screen.dart
│   │   ├── admin_manage_officials_screen.dart  # Multi-barangay, detail screen, assign/remove
│   │   ├── admin_create_official_screen.dart   # Syncs official_uid to barangay doc
│   │   └── admin_global_map_screen.dart
│   └── barangay/
│       ├── barangay_navigation_screen.dart
│       ├── barangay_home_screen.dart
│       ├── barangay_submit_request_screen.dart  # Polygon boundary + dark overlay + modal
│       ├── barangay_my_requests_screen.dart
│       ├── barangay_notifications_screen.dart   # Multi-select, swipe-delete, smart timestamps
│       └── barangay_profile_screen.dart
└── utils/
    ├── app_colors.dart
    ├── app_text_styles.dart
    ├── permission_handler.dart
    └── geo_utils.dart                       # isPointInPolygon + firestorePolygonToLatLng
```

---

## 🏘️ Barangay Geofencing System

### How It Works
1. Admin assigns a `barangay_id` to each Barangay Official on account creation — `official_uid` is written back to the barangay document (fixes occupancy indicator)
2. When the official opens Submit Request, the app fetches their barangay polygon from `/barangays/{barangay_id}`
3. The boundary is drawn on the map as a blue dashed polygon with a dark overlay outside
4. On every pin drop, `isPointInPolygon()` runs the ray casting algorithm
5. If outside — blocked with a modal (`barrierDismissible: false`, must tap "I Understand")
6. If inside — submission proceeds normally

### Data Source
- **Repo:** `faeldon/philippines-json-maps` — `bgysubmuns` GeoJSON files
- **Coverage:** Eastern Samar, Region VIII — 26 municipalities, 934 barangays
- **ID Format:** `08-MUN-BRG` (e.g. `08-016-003`)

---

## 👥 Role System

| Feature | Super Admin | Barangay Official | Rider |
|---------|-------------|-------------------|-------|
| View approved zones | ✅ All | ✅ Own barangay | ✅ All |
| Submit zone request | ✅ Direct approve | ✅ Pending only | ❌ |
| Boundary enforcement | ❌ No restriction | ✅ Polygon check | ❌ |
| Approve/Reject requests | ✅ | ❌ | ❌ |
| Manage officials | ✅ | ❌ | ❌ |
| Receive notifications | ❌ | ✅ | ❌ |
| BLE + exhaust control | ❌ | ❌ | ✅ |
| GPS auto-close | ❌ | ❌ | ✅ |
| HC-05 Developer Tools | ✅ | ❌ | ❌ |

---

## 🔐 Permissions Required (Android)

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

## 🧪 Testing

**Verified on:** Infinix X6833B (Android 13)

### ✅ Passing:
- Login/signup + role routing (all 3 roles)
- Full submit → approve → rider map flow end-to-end
- Notification delivery, multi-select, swipe-delete, unread badge
- Reverse geocoding on admin dashboard
- GPS dot on all 3 maps
- BLE scanning and connection
- Restricted area detection
- Barangay boundary polygon — dark overlay, pin drop blocking, out-of-bounds modal
- HC-05 two-way communication — OPEN/CLOSE/HELLO confirmed
- Relay actuation confirmed
- HC-05 test screen accessible via Super Admin only — not visible to other roles

### ⏳ Pending:
- Automatic valve control (Phase 8)
- iOS support
- Firestore security rules

---

## 🎯 Roadmap

| Phase | Feature | Status | Date |
|-------|---------|--------|------|
| 0 | Foundation | ✅ Done | Before Feb 11 |
| 1 | UI/UX | 🔄 80% | Feb 11 |
| 2 | Navigation | ✅ Done | Feb 11 |
| 3 | Permissions | ✅ Done | Feb 11 |
| 4 | Bluetooth | ✅ Done | Feb 17 |
| 5 | GPS | ✅ Done | Feb 17 |
| 6 | Map | ✅ Done | Feb 17 |
| 6.1 | Patches + Background GPS | ✅ Done | Mar 5 |
| 7 (p1) | Multi-Role Foundation + Screens | ✅ Done | Mar 9 |
| 7 (p2) | Notifications + UI/UX Polish | ✅ Done | Mar 15 |
| 7 (p3) | Barangay Geofencing + GeoJSON Seeding | ✅ Done | Mar 18 |
| 7.1 | HC-05 Hardware Validated + Relay Confirmed | ✅ Done | Mar 19 |
| **7.2** | **Dev Tool Relocation + Dashboard Cleanup** | **✅ Done** | **Mar 21** |
| 7 (final) | Security Rules + Super Admin Seed | 🔄 Next | Mar 2026 |
| 8 | HC-05 Automation (geofence → relay) | 🟡 Unblocked | TBD |

---

## 📚 Documentation

- [CHANGELOG.md](./CHANGELOGS.md) — Full version history
- [PROJECT_PROGRESS.md](./PROJECT_PROGRESS.md) — Phase progress tracker

---

## 📄 License

Created for educational purposes as part of a capstone project.

---

## 👨‍💻 Author

**Development Team**
Capstone Project 2026

---

**Last Updated:** March 21, 2026
**Version:** 0.7.2
**Status:** Active Development — Phase 7 final steps + Phase 8 unblocked