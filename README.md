# 🏍️ Exhaust Controller App

**Automatic Motorcycle Exhaust Noise Control System**

A Flutter mobile application for controlling motorcycle exhaust valves via Bluetooth, with GPS-based automation to automatically close exhausts in restricted noise zones.

---

## 📱 Project Overview

### **What It Does:**
- 🔗 **Bluetooth Control:** Connects to motorcycle exhaust controller hardware (ESP32 via BLE)
- 📍 **GPS Automation:** Automatically closes exhaust when entering restricted areas
- 🗺️ **Live Map:** Real OpenStreetMap with live GPS marker and restricted zone overlays
- 📊 **Statistics:** Track trips, auto-closures, and usage patterns
- 👤 **User Accounts:** Firebase authentication and cloud sync

### **Technology Stack:**
- **Frontend:** Flutter 3.10+
- **Backend:** Firebase (Auth, Firestore)
- **Hardware:** Bluetooth Low Energy (BLE) — ESP32
- **Maps:** OpenStreetMap via `flutter_map`
- **State Management:** Provider

---

## 🎯 Current Status: 85% Complete

### ✅ **Completed Features:**
- [x] User authentication (login/signup)
- [x] Professional UI with custom components
- [x] 4-tab navigation system (Home, Map, Stats, Profile)
- [x] Permission system (Bluetooth, GPS — Android 12+ compliant)
- [x] Real BLE device scanning and connection
- [x] Real OpenStreetMap with live tiles
- [x] GPS tracking every 8 seconds
- [x] Reverse geocoding (human-readable address)
- [x] Dashboard + Map synced via ExhaustProvider
- [x] Restricted area detection on every GPS tick
- [x] Statistics dashboard
- [x] Restricted area model with Haversine GPS detection

### 🔄 **In Progress:**
- [ ] ReWatch logo integration (80% complete — asset pending)

### ⏸️ **Planned (Phase 7):**
- [ ] ESP32 BLE command protocol definition
- [ ] Send valve open/close commands via BLE
- [ ] Automatic exhaust control on geofence entry/exit
- [ ] Auto-closure notifications

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

3. **Add logo asset** (if available)
```bash
# Place your logo file here:
assets/images/logo.png
```

4. **Generate app icons** (after adding logo)
```bash
flutter pub run flutter_launcher_icons
```

5. **Configure Firebase**
```bash
# Add your google-services.json to android/app/
# Add your GoogleService-Info.plist to ios/Runner/
```

6. **Run the app**
```bash
flutter run
```

---

## 📦 Dependencies

### **Core:**
```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
provider: ^6.1.5+1
shared_preferences: ^2.5.4
```

### **Hardware Integration:**
```yaml
flutter_blue_plus: 1.31.15     # BLE scanning and connection (free version)
geolocator: ^14.0.2            # GPS location
permission_handler: ^12.0.1    # Permission management
device_info_plus: ^10.1.0      # Android SDK version detection
```

### **Map & Location:**
```yaml
flutter_map: ^8.2.2            # OpenStreetMap rendering
latlong2: ^0.9.1               # LatLng coordinate type
geocoding: ^4.0.0              # Reverse geocoding (coords → address)
```

### **UI/UX:**
```yaml
font_awesome_flutter: ^10.7.0
awesome_dialog: ^3.2.1
flutter_svg: ^2.0.10
lottie: ^3.1.2
```

### **Development:**
```yaml
flutter_launcher_icons: ^0.14.1
```

---

## 🏗️ Project Structure
```
lib/
├── main.dart
├── models/
│   └── restricted_area.dart         # GPS zone model (Haversine)
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart      # Real BLE scanning + connection
│   ├── exhaust_provider.dart        # Exhaust state + live location
│   └── restricted_areas_provider.dart
├── screens/
│   ├── splash_screen.dart           # Permissions on launch
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── main_navigation_screen.dart  # 4-tab nav
│   ├── dashboard_screen.dart        # Live BT status + location
│   ├── map_screen.dart              # OSM map + GPS + geocoding
│   ├── stats_screen.dart
│   ├── profile_screen.dart
│   └── manage_restricted_areas_screen.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
├── utils/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── permission_handler.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── bluetooth_connection_modal.dart

android/app/src/main/
└── AndroidManifest.xml              # 7 permissions declared

assets/images/
└── logo.png                         # App logo (add this)
```

---

## 🗺️ Map Features

- **Real OSM Tiles** — live street map data, no API key needed
- **Live GPS Marker** — motorcycle icon at your real position, updates every 8 seconds
- **Restricted Zone Circles** — red overlays pulled from Firestore
- **Center Button** — snaps map back to your current location
- **Location Overlay** — shows live coords + green `8s` refresh badge
- **Auto-center** — only on first GPS fix; user can pan freely after

---

## 📍 GPS & Location

- **Update Interval:** Every 8 seconds via `Timer.periodic`
- **Accuracy:** `LocationAccuracy.high`
- **Reverse Geocoding:** `geocoding` package — converts coords to readable address (e.g. `"Sumulong Highway, Antipolo, Calabarzon"`)
- **Fallback:** Raw `lat, lng` string if geocoding fails
- **Restricted Area Check:** Runs on every GPS tick using Haversine formula
- **Dashboard Sync:** Address + restricted status pushed to `ExhaustProvider` — dashboard updates automatically

---

## 🔐 Permissions Required

### **Android:**
```xml
<!-- Bluetooth (Legacy - Android <12) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Bluetooth (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location (GPS) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Internet (Firebase + OSM tiles) -->
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🧪 Testing

### **Verified on:** Infinix X6833B (Android 13)

### ✅ Passing:
- Login/signup flow
- Permission request flow (BT + GPS)
- BLE device scanning
- BLE device connection
- Real OSM map loading
- GPS marker at actual position
- GPS updates every 8 seconds
- Human-readable address on dashboard
- Restricted area detection

### ⏳ Pending:
- Automatic valve control (Phase 7)
- Background location
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
| 7 | Automation | ⏸️ Next | Feb 18 |

---

## 📚 Documentation

- [CHANGELOG.md](./CHANGELOG.md) — Full version history
- [PROJECT_PROGRESS.md](./PROJECT_PROGRESS.md) — Phase progress tracker

### **Package Docs:**
- [flutter_map](https://pub.dev/packages/flutter_map)
- [geolocator](https://pub.dev/packages/geolocator)
- [geocoding](https://pub.dev/packages/geocoding)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)

---

## 📄 License

Created for educational purposes as part of a capstone project.

---

## 👨‍💻 Author

**Development Team**
Capstone Project 2026

---

**Last Updated:** February 17, 2026
**Version:** 0.6.0
**Status:** Active Development — Phase 7 Next