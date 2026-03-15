# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones. Features a full 3-role system — Super Admin, Barangay Official, and Rider.

---

## 📱 Project Overview

### **What It Does:**
- 🔗 **Bluetooth Control:** Connects to motorcycle exhaust controller hardware (ESP32 via BLE)
- 📍 **GPS Automation:** Automatically closes exhaust when entering restricted areas
- 🗺️ **Live Map:** Real OpenStreetMap with live pulsing GPS dot and restricted zone overlays
- 👥 **3-Role System:** Super Admin, Barangay Official, Rider — each with their own screens and permissions
- 🔔 **In-App Notifications:** Officials receive real-time approval/rejection notifications
- 📊 **Admin Dashboard:** Live stats, zone management, official management
- 👤 **User Accounts:** Firebase authentication with role-based routing

### **Technology Stack:**
- **Frontend:** Flutter 3.10+
- **Backend:** Firebase (Auth, Firestore)
- **Hardware:** Bluetooth Low Energy (BLE) — ESP32
- **Maps:** OpenStreetMap via `flutter_map`
- **State Management:** Provider

---

## 🎯 Current Status: ~88% Complete

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

**Super Admin Role:**
- [x] Dashboard — welcome card, 4 live stat cards, recent zone activity with geocoded addresses, officials overview
- [x] Request Inbox — pending requests list, approve/reject with reason, Firestore write
- [x] Manage Officials — active/inactive filter, deactivate/reactivate, create official form
- [x] Global Map — all zones color-coded by status, filter chips, pin markers, legend, recenter
- [x] Profile — indigo gradient card, role-aware

**Barangay Official Role:**
- [x] Dashboard — welcome card, 4 live stat cards (total/pending/approved/rejected), recent requests
- [x] Submit Request — map pin drop, radius selector, remarks, live location, pending submission
- [x] My Requests — 3-tab screen (Pending / Approved / Rejected), withdrawal, resubmit
- [x] Notifications — real-time approval/rejection notifications, unread badge, mark all read
- [x] Profile — blue gradient card, barangay info row

**Notification System:**
- [x] Firestore `/notifications` collection with `uid`, `type`, `title`, `body`, `is_read`
- [x] Admin approve → notification to official
- [x] Admin reject → notification to official with reason
- [x] Unread badge on nav bar (live stream)
- [x] Mark individual / mark all as read

### 🔄 **In Progress / Remaining:**
- [ ] Barangay boundary enforcement (Step 7.15 — Haversine circle check on pin drop)
- [ ] Firestore security rules tightening (Step 7.19 — HIGH RISK, do last)
- [ ] Seed Super Admin in Firestore (Step 7.4 — manual, 5 min)
- [ ] Logo integration (asset pending)

### ⏸️ **Planned (Phase 8 — Blocked):**
- [ ] ESP32 BLE command protocol definition
- [ ] Send valve open/close commands via BLE
- [ ] Automatic exhaust control on geofence entry/exit

---

## 🚀 Getting Started

### **Prerequisites:**
```bash
Flutter SDK: >=3.10.8
Dart SDK: >=3.0.0
Android Studio / Xcode
Firebase project configured
Physical Android device (BLE + GPS required)
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

3. **Configure Firebase**
```bash
# Add your google-services.json to android/app/
```

4. **Create Firestore composite indexes** (required — app will silently fail without these)

| Collection | Field 1 | Field 2 | Order |
|---|---|---|---|
| `restricted_areas` | `submitted_by_uid` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `created_at` DESC | Collection |
| `restricted_areas` | `status` ASC | `approved_at` DESC | Collection |
| `notifications` | `uid` ASC | `created_at` DESC | Collection |
| `notifications` | `uid` ASC | `is_read` ASC | Collection |

5. **Seed Super Admin in Firestore console**
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

6. **Run the app**
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
│   ├── app_user.dart                        # uid, name, email, role, barangayId, isActive
│   └── restricted_area.dart                 # GPS zone model with status + Haversine
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart              # Real BLE scanning + connection
│   ├── exhaust_provider.dart                # Exhaust state + live location
│   └── restricted_areas_provider.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart               # All Firestore reads/writes across 3 roles
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── shared/
│   │   └── shared_profile_screen.dart       # Shared across all 3 roles
│   ├── rider/
│   │   ├── main_navigation_screen.dart      # Custom pro nav (3 tabs)
│   │   ├── dashboard_screen.dart            # BT + exhaust status + location
│   │   ├── map_screen.dart                  # OSM + pulsing GPS dot + zones
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_navigation_screen.dart     # Custom pro nav + pending badge
│   │   ├── admin_home_screen.dart           # Stats + geocoded zones + officials
│   │   ├── admin_request_inbox_screen.dart
│   │   ├── admin_request_detail_screen.dart
│   │   ├── admin_manage_officials_screen.dart
│   │   ├── admin_create_official_screen.dart
│   │   └── admin_global_map_screen.dart     # All zones + pin markers + legend
│   └── barangay/
│       ├── barangay_navigation_screen.dart  # Custom pro nav + notif badge
│       ├── barangay_home_screen.dart
│       ├── barangay_submit_request_screen.dart
│       ├── barangay_my_requests_screen.dart
│       ├── barangay_notifications_screen.dart
│       └── barangay_profile_screen.dart
└── utils/
    ├── app_colors.dart
    ├── app_text_styles.dart
    └── permission_handler.dart
```

---

## 🗺️ Map Features

- **Real OSM Tiles** — Carto Voyager tileset, no API key needed
- **Pulsing GPS Dot** — animated blue dot with white border and pulse ring (all 3 role maps)
- **Restricted Zone Circles** — red overlays from Firestore, approved only for riders
- **Color-coded Pins** — green/amber/red per status on admin map
- **Recenter FAB** — snaps map back to current location
- **Location Overlay** — live address via reverse geocoding, RESTRICTED badge when in zone

---

## 👥 Role System

| Feature | Super Admin | Barangay Official | Rider |
|---------|-------------|-------------------|-------|
| View approved zones | ✅ All | ✅ Own barangay | ✅ All |
| Submit zone request | ✅ Direct approve | ✅ Pending only | ❌ |
| Approve/Reject requests | ✅ | ❌ | ❌ |
| Manage officials | ✅ | ❌ | ❌ |
| Receive notifications | ❌ | ✅ | ❌ |
| BLE + exhaust control | ❌ | ❌ | ✅ |
| GPS auto-close | ❌ | ❌ | ✅ |

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
- Notification delivery and unread badge
- Reverse geocoding on admin dashboard
- GPS dot on all 3 maps
- BLE scanning and connection
- Restricted area detection

### ⏳ Pending:
- Barangay boundary enforcement on pin drop
- Automatic valve control (Phase 8)
- iOS support

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
| 7 (final) | Boundary Check + Security Rules | 🔄 Next | Mar 2026 |
| 8 | BLE Automation | ⏸️ Blocked | TBD |

---

## 📚 Documentation

- [CHANGELOG.md](./CHANGELOG.md) — Full version history
- [PROJECT_PROGRESS.md](./PROJECT_PROGRESS.md) — Phase progress tracker

---

## 📄 License

Created for educational purposes as part of a capstone project.

---

## 👨‍💻 Author

**Development Team**
Capstone Project 2026

---

**Last Updated:** March 15, 2026
**Version:** 0.7.0 (patch 2)
**Status:** Active Development — Phase 7 final steps + Phase 8 pending hardware